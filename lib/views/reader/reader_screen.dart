import 'package:flutter/material.dart';
import '../../services/tts_service.dart';
import '../../models/chapter.dart';

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
  List<dynamic> _voices = [];
  Map<String, String>? _selectedVoice;

  @override
  void initState() {
    super.initState();
    _initTtsService();
  }

  Future<void> _initTtsService() async {
    _ttsService = await TtsService.getInstance();
    setState(() {
      _isInitialized = true;
    });
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await _ttsService.audioHandler.getVoices();
      // Lọc ra các giọng đọc tiếng Việt hoặc tiếng Anh phổ biến
      final filteredVoices = voices.where((v) {
        final lang = v['locale']?.toString().toLowerCase() ?? '';
        return lang.startsWith('vi') || lang.startsWith('en');
      }).toList();

      setState(() {
        _voices = filteredVoices.isNotEmpty ? filteredVoices : voices;
      });
    } catch (e) {
      print("Failed to load voices: $e");
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reader Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Cỡ chữ
                Row(
                  children: [
                    const Icon(Icons.format_size_rounded),
                    const SizedBox(width: 12),
                    const Text('Font Size'),
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
                        },
                      ),
                    ),
                  ],
                ),
                // Tốc độ nói
                Row(
                  children: [
                    const Icon(Icons.speed_rounded),
                    const SizedBox(width: 12),
                    const Text('Reading Speed'),
                    Expanded(
                      child: Slider(
                        value: _speechRate,
                        min: 0.25,
                        max: 1.0, // Standard limit for flutter_tts
                        divisions: 6,
                        activeColor: Colors.amber[700],
                        label: '${(_speechRate * 2).toStringAsFixed(1)}x',
                        onChanged: (val) {
                          setState(() {
                            _speechRate = val;
                          });
                          _ttsService.audioHandler.setSpeed(val);
                          setModalState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                // Chọn giọng đọc
                if (_voices.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Select Voice', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, String>>(
                    value: _selectedVoice,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _voices.map((v) {
                      final name = v['name']?.toString() ?? 'Unknown';
                      final locale = v['locale']?.toString() ?? '';
                      return DropdownMenuItem<Map<String, String>>(
                        value: Map<String, String>.from(v),
                        child: Text(
                          '$name ($locale)',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedVoice = val;
                        });
                        _ttsService.audioHandler.setVoice(val);
                      }
                    },
                  ),
                ],
              ],
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _ttsService,
      builder: (context, _) {
        final book = _ttsService.activeBook;
        final chapters = _ttsService.chapters;
        final activeChapterIndex = _ttsService.currentChapterIndex;
        final activeParagraphIndex = _ttsService.currentParagraphIndex;

        if (book == null || chapters.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('No book active'),
            ),
          );
        }

        final chapter = chapters[activeChapterIndex];

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: isDark ? Colors.white : Colors.black87,
            title: Text(
              book.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: _showSettings,
              ),
            ],
          ),
          body: Column(
            children: [
              // Tiêu đề chương
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
                    ),
                  ),
                ),
              ),
              // Vùng hiển thị nội dung đọc
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: chapter.paragraphs.length,
                  itemBuilder: (context, index) {
                    final paragraphText = chapter.paragraphs[index];
                    final isActive = index == activeParagraphIndex;

                    return ParagraphWidget(
                      text: paragraphText,
                      isActive: isActive,
                      fontSize: _fontSize,
                      wordStart: isActive ? _ttsService.wordStart : 0,
                      wordEnd: isActive ? _ttsService.wordEnd : 0,
                      isDark: isDark,
                      onTap: () {
                        // Click vào đoạn văn bất kỳ để nhảy phát TTS ngay từ đoạn đó
                        _ttsService.jumpToParagraph(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomAudioPanel(chapter, isDark),
        );
      },
    );
  }

  Widget _buildBottomAudioPanel(Chapter chapter, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hiển thị vị trí câu đang đọc
          Text(
            'Paragraph ${_ttsService.currentParagraphIndex + 1} of ${chapter.paragraphs.length}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Chương trước
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 32),
                onPressed: _ttsService.currentChapterIndex > 0
                    ? _ttsService.previousChapter
                    : null,
              ),
              // Đoạn trước
              IconButton(
                icon: const Icon(Icons.fast_rewind_rounded, size: 28),
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
                icon: const Icon(Icons.fast_forward_rounded, size: 28),
                onPressed: _ttsService.nextParagraph,
              ),
              // Chương tiếp theo
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 32),
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
}

class ParagraphWidget extends StatefulWidget {
  final String text;
  final bool isActive;
  final double fontSize;
  final int wordStart;
  final int wordEnd;
  final bool isDark;
  final VoidCallback onTap;

  const ParagraphWidget({
    super.key,
    required this.text,
    required this.isActive,
    required this.fontSize,
    required this.wordStart,
    required this.wordEnd,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<ParagraphWidget> createState() => _ParagraphWidgetState();
}

class _ParagraphWidgetState extends State<ParagraphWidget> {
  @override
  void didUpdateWidget(covariant ParagraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tự động cuộn màn hình để đưa đoạn văn đang được đọc vào vị trí trung tâm
    if (widget.isActive && !oldWidget.isActive) {
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
  }

  @override
  Widget build(BuildContext context) {
    final activeBgColor = widget.isDark ? Colors.amber[900]!.withOpacity(0.2) : Colors.amber[100]!;
    final textColor = widget.isDark ? Colors.white : Colors.black87;

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
        child: _buildRichText(textColor),
      ),
    );
  }

  Widget _buildRichText(Color defaultColor) {
    final style = TextStyle(
      fontSize: widget.fontSize,
      height: 1.6,
      color: defaultColor,
      letterSpacing: 0.2,
    );

    // Không highlight nếu đoạn văn không hoạt động hoặc không có vị trí highlight hợp lệ
    if (!widget.isActive || widget.wordStart >= widget.wordEnd || widget.wordEnd > widget.text.length) {
      return Text(
        widget.text,
        style: style,
      );
    }

    final before = widget.text.substring(0, widget.wordStart);
    final word = widget.text.substring(widget.wordStart, widget.wordEnd);
    final after = widget.text.substring(widget.wordEnd);

    return RichText(
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
