import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../../models/chapter.dart';
import '../../../services/tts_service.dart';

class BottomAudioPanel extends StatefulWidget {
  final TtsService ttsService;
  final Chapter chapter;
  final bool isDark;
  final Color textColor;
  final String themeMode;

  const BottomAudioPanel({
    super.key,
    required this.ttsService,
    required this.chapter,
    required this.isDark,
    required this.textColor,
    required this.themeMode,
  });

  @override
  State<BottomAudioPanel> createState() => _BottomAudioPanelState();
}

class _BottomAudioPanelState extends State<BottomAudioPanel> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    Color panelBg = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    if (widget.themeMode == 'Sepia') {
      panelBg = const Color(0xFFEAD8B1);
    }

    final tts = widget.ttsService;
    final totalParagraphs = widget.chapter.paragraphs.length;
    final currentParagraph = tts.currentParagraphIndex + 1;
    final double percent = totalParagraphs > 0 ? (currentParagraph / totalParagraphs * 100) : 0.0;
    final percentStr = percent.toStringAsFixed(1);
    final currentChapter = tts.currentChapterIndex + 1;
    final totalChapters = tts.chapters.length;

    final chapterDuration = tts.getChapterDuration();

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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Slider thanh trượt tiến trình chương
          StreamBuilder<Duration>(
            stream: AudioService.position,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final currentPositionSec = position.inSeconds.toDouble();
              
              double sliderValue = _isDragging ? _dragValue : currentPositionSec;
              if (sliderValue < 0) sliderValue = 0.0;
              if (sliderValue > chapterDuration) sliderValue = chapterDuration;

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: Colors.amber[700],
                      inactiveTrackColor: widget.textColor.withValues(alpha: 0.2),
                      thumbColor: Colors.amber[700],
                    ),
                    child: Slider(
                      value: chapterDuration > 0 ? sliderValue : 0.0,
                      min: 0.0,
                      max: chapterDuration > 0 ? chapterDuration : 1.0,
                      onChanged: chapterDuration > 0
                          ? (value) {
                              setState(() {
                                _isDragging = true;
                                _dragValue = value;
                              });
                            }
                          : null,
                      onChangeEnd: chapterDuration > 0
                          ? (value) {
                              setState(() {
                                _isDragging = false;
                              });
                              // Tìm paragraph tương ứng
                              final charPerSec = tts.getCharsPerSecond();
                              if (charPerSec > 0) {
                                double total = 0.0;
                                int targetIndex = 0;
                                final paragraphs = widget.chapter.paragraphs;
                                for (int i = 0; i < paragraphs.length; i++) {
                                  final dur = paragraphs[i].length / charPerSec;
                                  if (value <= total + dur) {
                                    targetIndex = i;
                                    break;
                                  }
                                  total += dur;
                                  targetIndex = i;
                                }
                                tts.jumpToParagraph(targetIndex);
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Thông tin thời gian bằng Tiếng Anh
          Column(
            children: [
              Text(
                "Paragraph: $currentParagraph / $totalParagraphs ($percentStr%)",
                style: TextStyle(
                  fontSize: 11,
                  color: widget.textColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Chapter: ${tts.chapterProgressTimeStr} ($currentChapter / $totalChapters)",
                style: TextStyle(
                  fontSize: 12,
                  color: widget.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Book: ${tts.bookProgressTimeStr}",
                style: TextStyle(
                  fontSize: 11,
                  color: widget.textColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 3. Các nút bấm điều khiển
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Chương trước
              IconButton(
                icon: Icon(Icons.skip_previous_rounded, size: 32, color: widget.textColor),
                onPressed: tts.currentChapterIndex > 0
                    ? tts.previousChapter
                    : null,
              ),
              // Đoạn trước
              IconButton(
                icon: Icon(Icons.fast_rewind_rounded, size: 28, color: widget.textColor),
                onPressed: tts.previousParagraph,
              ),
              // Play/Pause
              FloatingActionButton(
                onPressed: tts.togglePlayPause,
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                child: Icon(
                  tts.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 36,
                ),
              ),
              // Đoạn tiếp theo
              IconButton(
                icon: Icon(Icons.fast_forward_rounded, size: 28, color: widget.textColor),
                onPressed: tts.nextParagraph,
              ),
              // Chương tiếp theo
              IconButton(
                icon: Icon(Icons.skip_next_rounded, size: 32, color: widget.textColor),
                onPressed: tts.currentChapterIndex < tts.chapters.length - 1
                    ? tts.nextChapter
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
