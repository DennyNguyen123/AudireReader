import 'package:flutter/material.dart';
import '../../../models/chapter.dart';
import '../../../services/tts_service.dart';

class BottomAudioPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Color panelBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    if (themeMode == 'Sepia') {
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
              final currentParagraph = ttsService.currentParagraphIndex + 1;
              final double percent = totalParagraphs > 0 ? (currentParagraph / totalParagraphs * 100) : 0.0;
              final percentStr = percent.toStringAsFixed(1);
              final currentChapter = ttsService.currentChapterIndex + 1;
              final totalChapters = ttsService.chapters.length;
              final double chapterPercent = totalChapters > 0 ? (currentChapter / totalChapters * 100) : 0.0;
              final chapterPercentStr = chapterPercent.round().toString();

              return Text(
                'Paragraph $currentParagraph of $totalParagraphs ($percentStr%) • Chapter $currentChapter/$totalChapters ($chapterPercentStr%)',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.6),
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
                onPressed: ttsService.currentChapterIndex > 0
                    ? ttsService.previousChapter
                    : null,
              ),
              // Đoạn trước
              IconButton(
                icon: Icon(Icons.fast_rewind_rounded, size: 28, color: textColor),
                onPressed: ttsService.previousParagraph,
              ),
              // Play/Pause
              FloatingActionButton(
                onPressed: ttsService.togglePlayPause,
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                child: Icon(
                  ttsService.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 36,
                ),
              ),
              // Đoạn tiếp theo
              IconButton(
                icon: Icon(Icons.fast_forward_rounded, size: 28, color: textColor),
                onPressed: ttsService.nextParagraph,
              ),
              // Chương tiếp theo
              IconButton(
                icon: Icon(Icons.skip_next_rounded, size: 32, color: textColor),
                onPressed: ttsService.currentChapterIndex < ttsService.chapters.length - 1
                    ? ttsService.nextChapter
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
