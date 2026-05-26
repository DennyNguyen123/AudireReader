import 'dart:ui';
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildProgressRow({
    required IconData icon,
    required String label,
    required String value,
    String? percent,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textColor.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        if (percent != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              percent,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double iconSize,
    required VoidCallback? onPressed,
    required String tooltip,
    required Color textColor,
  }) {
    final isEnabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: iconSize,
              color: isEnabled ? textColor : textColor.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color panelBg = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    if (widget.themeMode == 'Sepia') {
      panelBg = const Color(0xFFEAD8B1);
    }

    final Color glassColor = panelBg.withValues(alpha: widget.isDark ? 0.75 : 0.85);

    final tts = widget.ttsService;
    final totalParagraphs = widget.chapter.paragraphs.length;
    final currentParagraph = tts.currentParagraphIndex + 1;
    final double percent = totalParagraphs > 0 ? (currentParagraph / totalParagraphs * 100) : 0.0;
    final percentStr = percent.toStringAsFixed(1);
    final currentChapter = tts.currentChapterIndex + 1;
    final totalChapters = tts.chapters.length;

    final chapterDuration = tts.getChapterDuration();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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

                  final currentPositionStr = _formatDuration(Duration(seconds: sliderValue.toInt()));
                  final durationStr = _formatDuration(Duration(seconds: chapterDuration.toInt()));

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: widget.textColor.withValues(alpha: 0.2),
                          thumbColor: Theme.of(context).colorScheme.primary,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentPositionStr,
                              style: TextStyle(
                                fontSize: 9,
                                color: widget.textColor.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              durationStr,
                              style: TextStyle(
                                fontSize: 9,
                                color: widget.textColor.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),

              // 2. Thông tin thời gian bằng Tiếng Anh (Card Layout)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildProgressRow(
                      icon: Icons.format_align_left_rounded,
                      label: "Paragraph",
                      value: "$currentParagraph / $totalParagraphs",
                      percent: "$percentStr%",
                      textColor: widget.textColor,
                    ),
                    const SizedBox(height: 4),
                    _buildProgressRow(
                      icon: Icons.menu_book_rounded,
                      label: "Chapter",
                      value: "$currentChapter / $totalChapters",
                      percent: tts.chapterProgressTimeStr,
                      textColor: widget.textColor,
                    ),
                    const SizedBox(height: 4),
                    _buildProgressRow(
                      icon: Icons.auto_stories_rounded,
                      label: "Book Progress",
                      value: tts.bookProgressTimeStr,
                      textColor: widget.textColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 3. Các nút bấm điều khiển
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.skip_previous_rounded,
                    iconSize: 22,
                    onPressed: tts.currentChapterIndex > 0 ? tts.previousChapter : null,
                    tooltip: "Previous Chapter",
                    textColor: widget.textColor,
                  ),
                  _buildControlButton(
                    icon: Icons.fast_rewind_rounded,
                    iconSize: 20,
                    onPressed: tts.previousParagraph,
                    tooltip: "Rewind Paragraph",
                    textColor: widget.textColor,
                  ),
                  GestureDetector(
                    onTap: tts.togglePlayPause,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                            Theme.of(context).colorScheme.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        tts.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildControlButton(
                    icon: Icons.fast_forward_rounded,
                    iconSize: 20,
                    onPressed: tts.nextParagraph,
                    tooltip: "Forward Paragraph",
                    textColor: widget.textColor,
                  ),
                  _buildControlButton(
                    icon: Icons.skip_next_rounded,
                    iconSize: 22,
                    onPressed: tts.currentChapterIndex < tts.chapters.length - 1 ? tts.nextChapter : null,
                    tooltip: "Next Chapter",
                    textColor: widget.textColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

