import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../l10n/app_localizations.dart';
import '../../../services/tts_service.dart';
import '../../../services/bgm_service.dart';
import '../../../core/theme_notifier.dart';
import '../../library/pronunciation_dictionary_screen.dart';

class ReaderSettingsSheet extends StatefulWidget {
  final TtsService ttsService;
  final String themeMode;
  final double fontSize;
  final String fontFamily;
  final double speechRate;
  final String ttsProvider;
  final List<dynamic> initialVoices;
  final Map<String, String>? initialSelectedVoice;

  final ValueChanged<String> onThemeModeChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String> onFontFamilyChanged;
  final ValueChanged<double> onSpeechRateChanged;
  final Function(String provider, List<dynamic> voices, Map<String, String>? selectedVoice) onTtsProviderChanged;
  final ValueChanged<Map<String, String>?> onVoiceChanged;

  const ReaderSettingsSheet({
    super.key,
    required this.ttsService,
    required this.themeMode,
    required this.fontSize,
    required this.fontFamily,
    required this.speechRate,
    required this.ttsProvider,
    required this.initialVoices,
    this.initialSelectedVoice,
    required this.onThemeModeChanged,
    required this.onFontSizeChanged,
    required this.onFontFamilyChanged,
    required this.onSpeechRateChanged,
    required this.onTtsProviderChanged,
    required this.onVoiceChanged,
  });

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late String _themeMode;
  late double _fontSize;
  late String _fontFamily;
  late double _speechRate;
  late String _ttsProvider;
  late List<dynamic> _voices;
  Map<String, String>? _selectedVoice;

  final _speedController = TextEditingController();
  final _voiceSearchController = TextEditingController();
  String _selectedLanguageFilter = 'all';
  String _voiceSearchQuery = '';

  // Background Music (BGM) UI state variables
  bool _showAddBgmForm = false;
  final _bgmNameController = TextEditingController();
  String? _bgmLocalPath;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _fontSize = widget.fontSize;
    _fontFamily = widget.fontFamily;
    _speechRate = widget.speechRate;
    _ttsProvider = widget.ttsProvider;
    _voices = List.from(widget.initialVoices);
    _selectedVoice = widget.initialSelectedVoice;

    _speedController.text = (_speechRate * 2).toStringAsFixed(3);
  }

  @override
  void dispose() {
    _speedController.dispose();
    _voiceSearchController.dispose();
    _bgmNameController.dispose();
    super.dispose();
  }

  bool _getIsDark(BuildContext context) {
    if (_themeMode == 'System') {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == 'Dark';
  }

  Future<void> _loadVoices(String provider) async {
    try {
      final list = await widget.ttsService.getVoicesForProvider(provider);
      final settings = await widget.ttsService.getSettings();

      Map<String, String>? initialVoice;
      if (settings.selectedVoiceName != null && settings.selectedVoiceLocale != null) {
        dynamic matched;
        for (final v in list) {
          if (v['name']?.toString() == settings.selectedVoiceName &&
              v['locale']?.toString() == settings.selectedVoiceLocale) {
            matched = v;
            break;
          }
        }
        if (matched != null) {
          initialVoice = Map<String, String>.from(
            (matched as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
          );
        }
      } else if (provider == 'microsoft_edge' && list.isNotEmpty) {
        dynamic matched;
        for (final v in list) {
          if (v['name']?.toString() == 'vi-VN-HoaiMyNeural') {
            matched = v;
            break;
          }
        }
        matched ??= list.first;
        initialVoice = Map<String, String>.from(
          (matched as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
        );
        widget.ttsService.updateSettings(voice: initialVoice);
      }

      setState(() {
        _voices = list;
        _selectedVoice = initialVoice;
      });
      
      widget.onTtsProviderChanged(provider, list, initialVoice);
    } catch (e) {
      debugPrint("Failed to load voices in settings sheet: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  AppLocalizations.of(context)!.readerSettings,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 🎨 NHÓM 1: DISPLAY & TYPOGRAPHY
            Row(
              children: [
                Icon(Icons.format_paint_rounded, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.displayTypography,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // CHỌN CHỦ ĐỀ ĐỌC (Theme Mode Row)
            Text(AppLocalizations.of(context)!.readingTheme, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
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
                      widget.onThemeModeChanged(theme);
                      widget.ttsService.updateSettings(themeMode: theme);
                      ThemeNotifier.instance.updateTheme(theme);
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
                            color: Colors.amber[700]!.withValues(alpha: 0.3),
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
                            color: isSelected ? Colors.amber[700] : textCol.withValues(alpha: 0.8), 
                            size: 18
                          ),
                          const SizedBox(height: 4),
                          Text(
                            theme == 'System' 
                                ? AppLocalizations.of(context)!.system 
                                : theme == 'Light' 
                                    ? AppLocalizations.of(context)!.light 
                                    : theme == 'Dark' 
                                        ? AppLocalizations.of(context)!.dark 
                                        : AppLocalizations.of(context)!.sepia,
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
                Text(AppLocalizations.of(context)!.fontSize, style: TextStyle(color: labelColor)),
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
                      widget.onFontSizeChanged(val);
                      widget.ttsService.updateSettings(fontSize: val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CHỌN PHÔNG CHỮ (Font Family Dropdown)
            Text(AppLocalizations.of(context)!.fontStyle, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: ['System', 'Serif', 'Sans-Serif', 'Monospace'].contains(_fontFamily) 
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
                  widget.onFontFamilyChanged(val);
                  widget.ttsService.updateSettings(fontFamily: val);
                }
              },
            ),
            const SizedBox(height: 20),
            Divider(color: isDark ? Colors.white10 : Colors.black12, thickness: 1),
            const SizedBox(height: 20),

            // 🗣️ NHÓM 2: TEXT-TO-SPEECH (TTS)
            Row(
              children: [
                Icon(Icons.volume_up_rounded, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.textToSpeechTts,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // SLEEP TIMER
            Text(
              widget.ttsService.isSleepTimerActive 
                  ? AppLocalizations.of(context)!.sleepTimerRemaining('${(widget.ttsService.sleepTimerDuration! ~/ 60).toString().padLeft(2, '0')}:${(widget.ttsService.sleepTimerDuration! % 60).toString().padLeft(2, '0')}')
                  : widget.ttsService.stopAtEndOfChapter 
                      ? AppLocalizations.of(context)!.sleepTimerStopAtEnd
                      : AppLocalizations.of(context)!.sleepTimer,
              style: TextStyle(fontWeight: FontWeight.bold, color: labelColor),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context)!.off, style: const TextStyle(fontSize: 12)),
                    selected: !widget.ttsService.isSleepTimerActive && !widget.ttsService.stopAtEndOfChapter,
                    selectedColor: Colors.amber[700],
                    labelStyle: TextStyle(
                      color: (!widget.ttsService.isSleepTimerActive && !widget.ttsService.stopAtEndOfChapter) ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.cancelSleepTimer();
                        widget.ttsService.enableStopAtEndOfChapter(false);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('15m', style: TextStyle(fontSize: 12)),
                    selected: widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 15,
                    selectedColor: Colors.amber[700],
                    labelStyle: TextStyle(
                      color: (widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 15) ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.startSleepTimer(15);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('30m', style: TextStyle(fontSize: 12)),
                    selected: widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 30,
                    selectedColor: Colors.amber[700],
                    labelStyle: TextStyle(
                      color: (widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 30) ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.startSleepTimer(30);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('45m', style: TextStyle(fontSize: 12)),
                    selected: widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 45,
                    selectedColor: Colors.amber[700],
                    labelStyle: TextStyle(
                      color: (widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 45) ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.startSleepTimer(45);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context)!.endChapter, style: const TextStyle(fontSize: 12)),
                    selected: widget.ttsService.stopAtEndOfChapter,
                    selectedColor: Colors.amber[700],
                    labelStyle: TextStyle(
                      color: widget.ttsService.stopAtEndOfChapter ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.enableStopAtEndOfChapter(true);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

             // TỐC ĐỘ NÓI
             Row(
               children: [
                 const Icon(Icons.speed_rounded),
                 const SizedBox(width: 12),
                 Text(AppLocalizations.of(context)!.readingSpeed, style: TextStyle(color: labelColor)),
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
                       widget.onSpeechRateChanged(val);
                       widget.ttsService.updateSettings(speechRate: val);
                     },
                   ),
                 ),
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
                         widget.onSpeechRateChanged(newRate);
                         widget.ttsService.updateSettings(speechRate: newRate);
                       }
                     },
                   ),
                 ),
               ],
             ),
            const SizedBox(height: 16),

            // CHỌN ĐỘNG CƠ TTS (TTS Provider Dropdown)
            Text(AppLocalizations.of(context)!.ttsProvider, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _ttsProvider,
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
              items: [
                DropdownMenuItem<String>(
                  value: 'system',
                  child: Text(AppLocalizations.of(context)!.systemTtsOffline, style: const TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem<String>(
                  value: 'microsoft_edge',
                  child: Text(AppLocalizations.of(context)!.edgeTtsOnline, style: const TextStyle(fontSize: 13)),
                ),
                const DropdownMenuItem<String>(
                  value: 'supertonic',
                  child: Text('Supertonic Offline AI', style: TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (val) async {
                if (val != null) {
                  setState(() {
                    _ttsProvider = val;
                    _voices = [];
                    _selectedVoice = null;
                  });

                  await widget.ttsService.updateSettings(ttsProvider: val);
                  await _loadVoices(val);
                  
                  if (val == 'supertonic') {
                    setState(() {
                      _selectedVoice = {
                        'name': 'M1',
                        'locale': 'offline',
                        'gender': 'Male',
                      };
                    });
                    widget.onVoiceChanged(_selectedVoice);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Đóng Bottom Sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PronunciationDictionaryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.record_voice_over_rounded),
              label: Text(AppLocalizations.of(context)!.managePronunciation),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // CHỌN GIỌNG ĐỌC & BỘ LỌC NGÔN NGỮ
            if (_voices.isNotEmpty) ...[
              // BỘ LỌC NGÔN NGỮ
              Text(AppLocalizations.of(context)!.languageFilter, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguageFilter,
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
                items: [
                  DropdownMenuItem<String>(
                    value: 'all',
                    child: Text(AppLocalizations.of(context)!.allLanguages, style: const TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem<String>(
                    value: 'vi',
                    child: Text(AppLocalizations.of(context)!.vietnamese, style: const TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem<String>(
                    value: 'en',
                    child: Text(AppLocalizations.of(context)!.english, style: const TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem<String>(
                    value: 'others',
                    child: Text(AppLocalizations.of(context)!.otherLanguages, style: const TextStyle(fontSize: 13)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedLanguageFilter = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Ô TÌM KIẾM GIỌNG ĐỌC (Bằng tiếng Anh)
              Text(AppLocalizations.of(context)!.searchVoice, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: _voiceSearchController,
                style: TextStyle(color: labelColor, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.black12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintText: AppLocalizations.of(context)!.searchVoiceHint,
                  hintStyle: TextStyle(color: labelColor.withValues(alpha: 0.5), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: labelColor.withValues(alpha: 0.6)),
                  suffixIcon: _voiceSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: labelColor.withValues(alpha: 0.6)),
                          onPressed: () {
                            _voiceSearchController.clear();
                            setState(() {
                              _voiceSearchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _voiceSearchQuery = val.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),

              Text(AppLocalizations.of(context)!.selectVoice, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
              const SizedBox(height: 8),
              () {
                final filteredDisplayVoices = _voices.where((v) {
                  final lang = v['locale']?.toString().toLowerCase() ?? '';
                  final name = v['name']?.toString().toLowerCase() ?? '';

                  // 1. Lọc theo ngôn ngữ
                  bool matchesLang = true;
                  if (_selectedLanguageFilter == 'vi') {
                    matchesLang = lang.startsWith('vi');
                  } else if (_selectedLanguageFilter == 'en') {
                    matchesLang = lang.startsWith('en');
                  } else if (_selectedLanguageFilter == 'others') {
                    matchesLang = !lang.startsWith('vi') && !lang.startsWith('en');
                  }

                  if (!matchesLang) return false;

                  // 2. Lọc theo ô tìm kiếm
                  if (_voiceSearchQuery.isNotEmpty) {
                    return name.contains(_voiceSearchQuery) || lang.contains(_voiceSearchQuery);
                  }

                  return true;
                }).toList();

                return DropdownButtonFormField<String>(
                  initialValue: filteredDisplayVoices.any((v) => v['name']?.toString() == _selectedVoice?['name'])
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
                  items: () {
                    final Set<String> seenNames = {};
                    final List<DropdownMenuItem<String>> menuItems = [];
                    for (final v in filteredDisplayVoices) {
                      final name = v['name']?.toString() ?? 'Unknown';
                      final locale = v['locale']?.toString() ?? '';
                      if (!seenNames.contains(name)) {
                        seenNames.add(name);
                        menuItems.add(DropdownMenuItem<String>(
                          value: name,
                          child: Text(
                            '$name ($locale)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: labelColor),
                          ),
                        ));
                      }
                    }
                    return menuItems;
                  }(),
                  onChanged: (val) {
                    if (val != null) {
                      dynamic selectedMap;
                      for (final v in filteredDisplayVoices) {
                        if (v['name']?.toString() == val) {
                          selectedMap = v;
                          break;
                        }
                      }
                      if (selectedMap != null) {
                        final voiceMap = Map<String, String>.from(
                          (selectedMap as Map).map(
                            (key, value) => MapEntry(key.toString(), value.toString()),
                          ),
                        );
                        setState(() {
                          _selectedVoice = voiceMap;
                        });
                        widget.onVoiceChanged(voiceMap);
                        widget.ttsService.updateSettings(voice: voiceMap);
                      }
                    }
                  },
                );
              }(),
              
              const SizedBox(height: 20),
              Divider(color: isDark ? Colors.white10 : Colors.black12, thickness: 1),
              const SizedBox(height: 20),

              // 🎵 GROUP 3: BACKGROUND MUSIC (BGM)
              Row(
                children: [
                  Icon(Icons.music_note_rounded, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text(
                    "BACKGROUND MUSIC (BGM)",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ListenableBuilder(
                listenable: BgmService.getInstance(),
                builder: (context, _) {
                  final bgmService = BgmService.getInstance();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ENABLE BGM SWITCH
                      SwitchListTile(
                        title: Text(
                          "Enable Background Music",
                          style: TextStyle(fontWeight: FontWeight.bold, color: labelColor, fontSize: 14),
                        ),
                        value: bgmService.bgmEnabled,
                        activeThumbColor: Colors.amber[700],
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) async {
                          await bgmService.updateSettings(bgmEnabled: val);
                          if (val && bgmService.currentTrack != null) {
                            await bgmService.playTrack(bgmService.currentTrack!);
                          }
                        },
                      ),

                      if (bgmService.bgmEnabled) ...[
                        const SizedBox(height: 10),
                        // VOLUME SLIDER
                        Row(
                          children: [
                            const Icon(Icons.volume_down_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text("BGM Volume", style: TextStyle(color: labelColor, fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: bgmService.bgmVolume,
                                min: 0.0,
                                max: 0.5, // Giới hạn max 0.5 để nhạc nền không lấn át TTS
                                activeColor: Colors.amber[700],
                                onChanged: (val) {
                                  bgmService.updateVolumeInMemory(val);
                                },
                                onChangeEnd: (val) {
                                  bgmService.updateSettings(bgmVolume: val);
                                },
                              ),
                            ),
                            Text(
                              "${(bgmService.bgmVolume * 200).round()}%",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: labelColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // LOOP MODE DROPDOWN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Loop Mode", style: TextStyle(fontWeight: FontWeight.bold, color: labelColor, fontSize: 13)),
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                initialValue: bgmService.bgmLoopMode,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? Colors.white10 : Colors.black12,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                dropdownColor: sheetBg,
                                style: TextStyle(color: labelColor, fontSize: 13),
                                items: const [
                                  DropdownMenuItem(value: 'none', child: Text('No Loop')),
                                  DropdownMenuItem(value: 'one', child: Text('Loop One Track')),
                                  DropdownMenuItem(value: 'all', child: Text('Loop Playlist')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    bgmService.updateSettings(bgmLoopMode: val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // PLAYLIST MANAGER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "BGM Playlist",
                            style: TextStyle(fontWeight: FontWeight.bold, color: labelColor, fontSize: 14),
                          ),
                          IconButton(
                            icon: Icon(
                              _showAddBgmForm ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                              color: Colors.amber[700],
                            ),
                            onPressed: () {
                              setState(() {
                                _showAddBgmForm = !_showAddBgmForm;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Add Track Form (Local Only)
                      if (_showAddBgmForm) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Add BGM Track",
                                style: TextStyle(fontWeight: FontWeight.bold, color: labelColor, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              
                              // Track Name Input
                              TextField(
                                controller: _bgmNameController,
                                style: TextStyle(color: labelColor, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: "Track Name (Optional)",
                                  labelStyle: TextStyle(color: labelColor.withValues(alpha: 0.6), fontSize: 12),
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Local Audio Picker Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                  foregroundColor: labelColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.folder_open_rounded, size: 16),
                                label: Text(
                                  _bgmLocalPath != null
                                      ? p.basename(_bgmLocalPath!)
                                      : "Select Audio File",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () async {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['mp3', 'm4a', 'wav', 'ogg', 'flac'],
                                    allowMultiple: false,
                                  );
                                  if (result != null && result.files.single.path != null) {
                                    setState(() {
                                      _bgmLocalPath = result.files.single.path;
                                      if (_bgmNameController.text.trim().isEmpty) {
                                        _bgmNameController.text = p.basenameWithoutExtension(_bgmLocalPath!);
                                      }
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _bgmLocalPath == null
                                    ? null
                                    : () async {
                                        try {
                                          await bgmService.addTrackFromLocal(
                                            _bgmNameController.text,
                                            _bgmLocalPath!,
                                          );
                                          setState(() {
                                            _showAddBgmForm = false;
                                            _bgmNameController.clear();
                                            _bgmLocalPath = null;
                                          });
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("BGM Track added successfully!")),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Failed to add track: $e")),
                                          );
                                        }
                                      },
                                child: const Text("Import Local File", style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // PLAYLIST TRACKS LIST
                      if (bgmService.bgmPlaylist.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "No background music tracks added yet.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: labelColor.withValues(alpha: 0.5), fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bgmService.bgmPlaylist.length,
                          itemBuilder: (context, index) {
                            final track = bgmService.bgmPlaylist[index];
                            final isCurrent = bgmService.currentTrack?.id == track.id;
                            const IconData sourceIcon = Icons.insert_drive_file_rounded;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.amber[700]!.withValues(alpha: isDark ? 0.2 : 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? Colors.amber[700]!.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    sourceIcon,
                                    size: 18,
                                    color: isCurrent ? Colors.amber[700] : labelColor.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      track.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                        color: isCurrent ? (isDark ? Colors.amber[200] : Colors.amber[900]) : labelColor,
                                      ),
                                    ),
                                  ),
                                  
                                  // Play/Pause Button
                                  IconButton(
                                    icon: Icon(
                                      isCurrent && bgmService.isPlaying
                                          ? Icons.pause_circle_outline_rounded
                                          : Icons.play_circle_outline_rounded,
                                      size: 20,
                                      color: isCurrent ? Colors.amber[700] : labelColor.withValues(alpha: 0.7),
                                    ),
                                    onPressed: () {
                                      if (isCurrent && bgmService.isPlaying) {
                                        bgmService.pauseBgm();
                                      } else {
                                        bgmService.playTrack(track);
                                      }
                                    },
                                  ),

                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: sheetBg,
                                          title: const Text("Delete Track", style: TextStyle(fontWeight: FontWeight.bold)),
                                          content: Text("Are you sure you want to delete '${track.name}'?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                bgmService.deleteTrack(track);
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
