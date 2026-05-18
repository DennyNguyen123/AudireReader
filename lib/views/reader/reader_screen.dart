import 'package:flutter/material.dart';
import '../../core/shortcut_helper.dart';
import '../../services/tts_service.dart';
import '../../models/chapter.dart';
import '../../models/settings.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final TtsService _ttsService;
  bool _isInitialized = false;
  double _fontSize = 18.0;
  double _speechRate = 0.5; // FlutterTts standard rate is 0.5 for normal speed
  final _speedController = TextEditingController();
  List<dynamic> _voices = [];
  Map<String, String>? _selectedVoice;
  String _fontFamily = 'System';
  String _themeMode = 'System';

  @override
  void initState() {
    super.initState();
    _initTtsService();
  }

  @override
  void dispose() {
    _speedController.dispose();
    super.dispose();
  }

  Future<void> _initTtsService() async {
    _ttsService = await TtsService.getInstance();
    final settings = await _ttsService.getSettings();

    setState(() {
      _fontSize = settings.fontSize;
      _speechRate = settings.speechRate;
      _speedController.text = (_speechRate * 2).toStringAsFixed(3);
      
      dynamic rawFont = settings.fontFamily;
      _fontFamily = (rawFont == null || rawFont.toString().trim().isEmpty) ? 'System' : rawFont.toString();
      
      dynamic rawTheme = settings.themeMode;
      _themeMode = (rawTheme == null || rawTheme.toString().trim().isEmpty) ? 'System' : rawTheme.toString();
      
      _isInitialized = true;
    });
    _loadVoices(settings);
  }

  Future<void> _loadVoices(AppSettings settings) async {
    try {
      final voices = await _ttsService.audioHandler.getVoices();
      // Lọc ra các giọng đọc tiếng Việt hoặc tiếng Anh phổ biến
      final filteredVoices = voices.where((v) {
        final lang = v['locale']?.toString().toLowerCase() ?? '';
        return lang.startsWith('vi') || lang.startsWith('en');
      }).toList();

      final list = filteredVoices.isNotEmpty ? filteredVoices : voices;

      Map<String, String>? initialVoice;
      if (settings.selectedVoiceName != null && settings.selectedVoiceLocale != null) {
        final matched = list.firstWhere(
          (v) => v['name']?.toString() == settings.selectedVoiceName &&
                 v['locale']?.toString() == settings.selectedVoiceLocale,
          orElse: () => null,
        );
        if (matched != null) {
          initialVoice = Map<String, String>.from(
            (matched as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
          );
        }
      }

      setState(() {
        _voices = list;
        if (initialVoice != null) {
          _selectedVoice = initialVoice;
        }
      });
    } catch (e) {
      print("Failed to load voices: $e");
    }
  }

  // --- Hotkeys & Boss Key Handlers ---
  void _handleNextParagraph() {
    _ttsService.nextParagraph();
  }

  void _handlePrevParagraph() {
    _ttsService.previousParagraph();
  }

  void _handleNextChapter() {
    if (_ttsService.currentChapterIndex < _ttsService.chapters.length - 1) {
      _ttsService.nextChapter();
    }
  }

  void _handlePrevChapter() {
    if (_ttsService.currentChapterIndex > 0) {
      _ttsService.previousChapter();
    }
  }

  void _handlePlayPauseTts() {
    _ttsService.togglePlayPause();
  }

  void _handleOpenChapter() {
    _showChapterList(context);
  }

  void _handleOpenSetting() {
    _showSettings();
  }


  Map<ShortcutActivator, VoidCallback> _buildShortcuts(AppSettings settings) {
    return {
      ShortcutHelper.parse(settings.hotkeyNextParagraph): _handleNextParagraph,
      ShortcutHelper.parse(settings.hotkeyPrevParagraph): _handlePrevParagraph,
      ShortcutHelper.parse(settings.hotkeyNextChapter): _handleNextChapter,
      ShortcutHelper.parse(settings.hotkeyPrevChapter): _handlePrevChapter,
      ShortcutHelper.parse(settings.hotkeyPlayPauseTts): _handlePlayPauseTts,
      ShortcutHelper.parse(settings.hotkeyOpenChapter): _handleOpenChapter,
      ShortcutHelper.parse(settings.hotkeyOpenSetting): _handleOpenSetting,
    };
  }

  bool _getIsDark(BuildContext context) {
    if (_themeMode == 'Dark') return true;
    if (_themeMode == 'Light' || _themeMode == 'Sepia') return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _getBackgroundColor(bool isDark) {
    if (_themeMode == 'Sepia') return const Color(0xFFF4ECD8);
    return isDark ? const Color(0xFF121212) : const Color(0xFFFAF9F6);
  }

  Color _getTextColor(bool isDark) {
    if (_themeMode == 'Sepia') return const Color(0xFF5B4636);
    return isDark ? Colors.white70 : Colors.black87;
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = _getIsDark(context);
          final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final labelColor = isDark ? Colors.white70 : Colors.black87;

          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reader Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // CHỌN CHỦ ĐỀ ĐỌC (Theme Mode Row)
                  Text('Reading Theme', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['System', 'Light', 'Dark', 'Sepia'].map((theme) {
                      final isSelected = _themeMode == theme;
                      Color btnBg;
                      Color textCol;
                      IconData icon;
                      
                      if (theme == 'System') {
                        btnBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
                        textCol = isDark ? Colors.white70 : Colors.black87;
                        icon = Icons.brightness_auto_rounded;
                      } else if (theme == 'Light') {
                        btnBg = Colors.white;
                        textCol = Colors.black87;
                        icon = Icons.wb_sunny_rounded;
                      } else if (theme == 'Dark') {
                        btnBg = const Color(0xFF121212);
                        textCol = Colors.white70;
                        icon = Icons.nightlight_round;
                      } else { // Sepia
                        btnBg = const Color(0xFFF4ECD8);
                        textCol = const Color(0xFF5B4636);
                        icon = Icons.menu_book_rounded;
                      }
                      
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _themeMode = theme;
                            });
                            setModalState(() {});
                            _ttsService.updateSettings(themeMode: theme);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: btnBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.amber[700]! 
                                    : (isDark ? Colors.white10 : Colors.black12),
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.amber[700]!.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ] : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon, 
                                  color: isSelected ? Colors.amber[700] : textCol.withOpacity(0.8), 
                                  size: 18
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  theme,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.amber[700] : textCol,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // CỠ CHỮ
                  Row(
                    children: [
                      const Icon(Icons.format_size_rounded),
                      const SizedBox(width: 12),
                      Text('Font Size', style: TextStyle(color: labelColor)),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 14.0,
                          max: 28.0,
                          divisions: 7,
                          activeColor: Colors.amber[700],
                          label: _fontSize.round().toString(),
                          onChanged: (val) {
                            setState(() {
                              _fontSize = val;
                            });
                            setModalState(() {});
                            _ttsService.updateSettings(fontSize: val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                   // TỐC ĐỘ NÓI
                   Row(
                     children: [
                       const Icon(Icons.speed_rounded),
                       const SizedBox(width: 12),
                       Text('Reading Speed', style: TextStyle(color: labelColor)),
                       Expanded(
                         child: Slider(
                           value: _speechRate,
                           min: 0.05,
                           max: 1.0,
                           activeColor: Colors.amber[700],
                           onChanged: (val) {
                             setState(() {
                               _speechRate = val;
                               _speedController.text = (val * 2).toStringAsFixed(3);
                             });
                             setModalState(() {});
                             _ttsService.updateSettings(speechRate: val);
                           },
                         ),
                       ),
                       // Hộp nhập số tốc độ chính xác 3 số lẻ thập phân
                       SizedBox(
                         width: 85,
                         height: 38,
                         child: TextField(
                           controller: _speedController,
                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             fontSize: 12, 
                             fontWeight: FontWeight.bold,
                             color: labelColor,
                           ),
                           decoration: InputDecoration(
                             contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                             suffixText: 'x',
                             suffixStyle: TextStyle(
                               fontSize: 11, 
                               fontWeight: FontWeight.bold, 
                               color: isDark ? Colors.amber[300] : Colors.amber[850]
                             ),
                             filled: true,
                             fillColor: isDark ? Colors.white10 : Colors.black12,
                             border: OutlineInputBorder(
                               borderRadius: BorderRadius.circular(10),
                               borderSide: BorderSide.none,
                             ),
                           ),
                           onChanged: (text) {
                             final double? val = double.tryParse(text);
                             if (val != null) {
                               final clampedMultiplier = val.clamp(0.1, 2.0);
                               final newRate = clampedMultiplier / 2.0;
                               setState(() {
                                 _speechRate = newRate;
                               });
                               setModalState(() {});
                               _ttsService.updateSettings(speechRate: newRate);
                             }
                           },
                         ),
                       ),
                     ],
                   ),
                  const SizedBox(height: 16),

                  // CHỌN PHÔNG CHỮ (Font Family Dropdown)
                  Text('Font Style', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: ['System', 'Serif', 'Sans-Serif', 'Monospace'].contains(_fontFamily) 
                        ? _fontFamily 
                        : 'System',
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: sheetBg,
                    items: ['System', 'Serif', 'Sans-Serif', 'Monospace'].map((font) {
                      return DropdownMenuItem<String>(
                        value: font,
                        child: Text(
                          font,
                          style: TextStyle(
                            color: labelColor,
                            fontFamily: font == 'System' ? null : font.toLowerCase()
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _fontFamily = val;
                        });
                        setModalState(() {});
                        _ttsService.updateSettings(fontFamily: val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // CHỌN GIỌNG ĐỌC
                  if (_voices.isNotEmpty) ...[
                    Text('Select Voice', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _voices.any((v) => v['name']?.toString() == _selectedVoice?['name'])
                          ? (_selectedVoice?['name'])
                          : null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.black12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: sheetBg,
                      items: _voices.map((v) {
                        final name = v['name']?.toString() ?? 'Unknown';
                        final locale = v['locale']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(
                            '$name ($locale)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: labelColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selectedMap = _voices.firstWhere(
                            (v) => v['name']?.toString() == val,
                            orElse: () => null,
                          );
                          if (selectedMap != null) {
                            final voiceMap = Map<String, String>.from(
                              (selectedMap as Map).map(
                                (key, value) => MapEntry(key.toString(), value.toString()),
                              ),
                            );
                            setState(() {
                              _selectedVoice = voiceMap;
                            });
                            setModalState(() {});
                            _ttsService.updateSettings(voice: voiceMap);
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDark = _getIsDark(context);
    final backgroundColor = _getBackgroundColor(isDark);
    final textColor = _getTextColor(isDark);

    return ListenableBuilder(
      listenable: _ttsService,
      builder: (context, _) {
        final book = _ttsService.activeBook;
        final chapters = _ttsService.chapters;
        final activeChapterIndex = _ttsService.currentChapterIndex;

        if (book == null || chapters.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('No book active'),
            ),
          );
        }

        final chapter = chapters[activeChapterIndex];

        return FutureBuilder<AppSettings>(
          future: _ttsService.getSettings(),
          builder: (context, snapshot) {
            final settings = snapshot.data;
            final Widget scaffoldContent = Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: textColor,
                title: Text(
                  book.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded),
                    onPressed: () => _showChapterList(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: _showSettings,
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.amber[400] : Colors.amber[800],
                          fontFamily: _fontFamily == 'System' ? null : _fontFamily.toLowerCase(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(chapter.paragraphs.length, (index) {
                          final paragraphText = chapter.paragraphs[index];
                          final isActive = index == _ttsService.currentParagraphIndex;

                          return ParagraphWidget(
                            text: paragraphText,
                            isActive: isActive,
                            fontSize: _fontSize,
                            wordStart: isActive ? _ttsService.wordStart : 0,
                            wordEnd: isActive ? _ttsService.wordEnd : 0,
                            isDark: isDark,
                            fontFamily: _fontFamily,
                            textColor: textColor,
                            onTap: () {
                              _ttsService.jumpToParagraph(index);
                            },
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _buildBottomAudioPanel(chapter, isDark, textColor),
            );

            if (settings == null) {
              return scaffoldContent;
            }

            return CallbackShortcuts(
              bindings: _buildShortcuts(settings),
              child: Focus(
                autofocus: true,
                child: scaffoldContent,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomAudioPanel(Chapter chapter, bool isDark, Color textColor) {
    Color panelBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    if (_themeMode == 'Sepia') {
      panelBg = const Color(0xFFEAD8B1);
    }

    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hiển thị vị trí câu đang đọc, phần trăm tiến trình và chỉ số chương kèm phần trăm chương
          Builder(
            builder: (context) {
              final totalParagraphs = chapter.paragraphs.length;
              final currentParagraph = _ttsService.currentParagraphIndex + 1;
              final double percent = totalParagraphs > 0 ? (currentParagraph / totalParagraphs * 100) : 0.0;
              final percentStr = percent.toStringAsFixed(1);
              final currentChapter = _ttsService.currentChapterIndex + 1;
              final totalChapters = _ttsService.chapters.length;
              final double chapterPercent = totalChapters > 0 ? (currentChapter / totalChapters * 100) : 0.0;
              final chapterPercentStr = chapterPercent.round().toString();

              return Text(
                'Paragraph $currentParagraph of $totalParagraphs ($percentStr%) • Chapter $currentChapter/$totalChapters ($chapterPercentStr%)',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Chương trước
              IconButton(
                icon: Icon(Icons.skip_previous_rounded, size: 32, color: textColor),
                onPressed: _ttsService.currentChapterIndex > 0
                    ? _ttsService.previousChapter
                    : null,
              ),
              // Đoạn trước
              IconButton(
                icon: Icon(Icons.fast_rewind_rounded, size: 28, color: textColor),
                onPressed: _ttsService.previousParagraph,
              ),
              // Play/Pause
              FloatingActionButton(
                onPressed: _ttsService.togglePlayPause,
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                child: Icon(
                  _ttsService.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 36,
                ),
              ),
              // Đoạn tiếp theo
              IconButton(
                icon: Icon(Icons.fast_forward_rounded, size: 28, color: textColor),
                onPressed: _ttsService.nextParagraph,
              ),
              // Chương tiếp theo
              IconButton(
                icon: Icon(Icons.skip_next_rounded, size: 32, color: textColor),
                onPressed: _ttsService.currentChapterIndex < _ttsService.chapters.length - 1
                    ? _ttsService.nextChapter
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChapterList(BuildContext context) {
    final isDark = _getIsDark(context);
    final sheetBg = _getBackgroundColor(isDark);
    final textColor = _getTextColor(isDark);
    final chapters = _ttsService.chapters;
    final currentChapterIdx = _ttsService.currentChapterIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        String chapterSearchQuery = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredChapters = chapters.asMap().entries.where((entry) {
              final title = entry.value.title.toLowerCase();
              final query = chapterSearchQuery.toLowerCase();
              return title.contains(query);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chapters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${filteredChapters.length} of ${chapters.length}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: TextField(
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Search chapters...',
                            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.search_rounded, color: textColor.withOpacity(0.5)),
                            filled: true,
                            fillColor: isDark ? Colors.white10 : Colors.black12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              chapterSearchQuery = val;
                            });
                          },
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: filteredChapters.isEmpty
                            ? Center(
                                child: Text(
                                  'No chapters match your search',
                                  style: TextStyle(color: textColor.withOpacity(0.5)),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredChapters.length,
                                itemBuilder: (context, index) {
                                  final entry = filteredChapters[index];
                                  final originalIndex = entry.key;
                                  final chapter = entry.value;
                                  final isCurrent = originalIndex == currentChapterIdx;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                                    title: Text(
                                      chapter.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                        color: isCurrent 
                                            ? (isDark ? Colors.amber[400] : Colors.amber[800])
                                            : textColor,
                                      ),
                                    ),
                                    trailing: isCurrent 
                                        ? Icon(
                                            Icons.volume_up_rounded, 
                                            color: isDark ? Colors.amber[400] : Colors.amber[800]
                                          ) 
                                        : null,
                                    tileColor: isCurrent 
                                        ? (isDark ? Colors.amber[900]!.withOpacity(0.1) : Colors.amber[50]!)
                                        : null,
                                    onTap: () {
                                      Navigator.pop(context);
                                      _ttsService.jumpToChapter(originalIndex);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class ParagraphWidget extends StatefulWidget {
  final String text;
  final bool isActive;
  final double fontSize;
  final int wordStart;
  final int wordEnd;
  final bool isDark;
  final String fontFamily;
  final Color textColor;
  final VoidCallback onTap;

  const ParagraphWidget({
    super.key,
    required this.text,
    required this.isActive,
    required this.fontSize,
    required this.wordStart,
    required this.wordEnd,
    required this.isDark,
    required this.fontFamily,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<ParagraphWidget> createState() => _ParagraphWidgetState();
}

class _ParagraphWidgetState extends State<ParagraphWidget> {
  @override
  void initState() {
    super.initState();
    // Tự động cuộn màn hình ngay khi widget được khởi tạo ở trạng thái active (ví dụ khi đổi chương)
    if (widget.isActive) {
      _scrollToVisible();
    }
  }

  @override
  void didUpdateWidget(covariant ParagraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tự động cuộn màn hình để đưa đoạn văn đang được đọc vào vị trí trung tâm khi trạng thái đổi thành active
    if (widget.isActive && !oldWidget.isActive) {
      _scrollToVisible();
    }
  }

  void _scrollToVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.3, // Cuộn hơi lùi lên trên một chút để dễ đọc
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeBgColor = widget.isDark ? Colors.amber[900]!.withOpacity(0.2) : Colors.amber[100]!;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: widget.isActive
              ? Border.all(color: Colors.amber[700]!.withOpacity(0.5), width: 1)
              : null,
        ),
        child: _buildRichText(widget.textColor),
      ),
    );
  }

  Widget _buildRichText(Color defaultColor) {
    final style = TextStyle(
      fontSize: widget.fontSize,
      fontFamily: widget.fontFamily == 'System' ? null : widget.fontFamily.toLowerCase(),
      height: 1.6,
      color: defaultColor,
      letterSpacing: 0.2,
    );

    // Không highlight nếu đoạn văn không hoạt động hoặc không có vị trí highlight hợp lệ
    if (!widget.isActive || widget.wordStart >= widget.wordEnd || widget.wordEnd > widget.text.length) {
      return Text(
        widget.text,
        style: style,
        textAlign: TextAlign.left,
      );
    }

    final before = widget.text.substring(0, widget.wordStart);
    final word = widget.text.substring(widget.wordStart, widget.wordEnd);
    final after = widget.text.substring(widget.wordEnd);

    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: word,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w900,
              backgroundColor: Colors.black12,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
