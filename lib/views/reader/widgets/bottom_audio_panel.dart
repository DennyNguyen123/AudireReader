import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/chapter.dart';
import '../../../services/tts_service.dart';
import '../../../l10n/app_localizations.dart';
import 'bgm_player_sheet.dart';
import 'reader_tts_settings_sheet.dart';

class BottomAudioPanel extends StatefulWidget {
  final TtsService ttsService;
  final Chapter chapter;
  final bool isDark;
  final Color textColor;
  final String themeMode;
  final VoidCallback? onToggleFullscreen;

  const BottomAudioPanel({
    super.key,
    required this.ttsService,
    required this.chapter,
    required this.isDark,
    required this.textColor,
    required this.themeMode,
    this.onToggleFullscreen,
  });

  @override
  State<BottomAudioPanel> createState() => _BottomAudioPanelState();
}

class _BottomAudioPanelState extends State<BottomAudioPanel> {
  bool _isCollapsed = false;

  void _showCustomSleepTimerDialog(BuildContext parentContext) {
    final textController = TextEditingController();
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.sleepTimer),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số phút (Minutes)',
              hintText: 'e.g. 60',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final int? minutes = int.tryParse(textController.text);
                if (minutes != null && minutes > 0) {
                  widget.ttsService.startSleepTimer(minutes);
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSleepTimerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = widget.isDark;
        final bg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final l10n = AppLocalizations.of(context)!;
        final tts = widget.ttsService;

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bedtime_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tts.isSleepTimerActive
                        ? l10n.sleepTimerRemaining(
                            '${(tts.sleepTimerDuration! ~/ 60).toString().padLeft(2, '0')}:${(tts.sleepTimerDuration! % 60).toString().padLeft(2, '0')}')
                        : tts.stopAtEndOfChapter
                            ? l10n.sleepTimerStopAtEnd
                            : l10n.sleepTimer,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text(l10n.off),
                    selected: !tts.isSleepTimerActive && !tts.stopAtEndOfChapter,
                    onSelected: (val) {
                      if (val) {
                        tts.cancelSleepTimer();
                        tts.enableStopAtEndOfChapter(false);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('15m'),
                    selected: tts.isSleepTimerActive && (tts.sleepTimerDuration! ~/ 60 == 15),
                    onSelected: (val) {
                      if (val) {
                        tts.startSleepTimer(15);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('30m'),
                    selected: tts.isSleepTimerActive && (tts.sleepTimerDuration! ~/ 60 == 30),
                    onSelected: (val) {
                      if (val) {
                        tts.startSleepTimer(30);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('45m'),
                    selected: tts.isSleepTimerActive && (tts.sleepTimerDuration! ~/ 60 == 45),
                    onSelected: (val) {
                      if (val) {
                        tts.startSleepTimer(45);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('60m'),
                    selected: tts.isSleepTimerActive && (tts.sleepTimerDuration! ~/ 60 == 60),
                    onSelected: (val) {
                      if (val) {
                        tts.startSleepTimer(60);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: Text(l10n.endChapter),
                    selected: tts.stopAtEndOfChapter,
                    onSelected: (val) {
                      if (val) {
                        tts.enableStopAtEndOfChapter(true);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Custom...'),
                    selected: false,
                    onSelected: (_) {
                      Navigator.pop(context);
                      _showCustomSleepTimerDialog(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double iconSize,
    required VoidCallback? onPressed,
    required String tooltip,
    required Color textColor,
    EdgeInsetsGeometry padding = const EdgeInsets.all(10),
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
            padding: padding,
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
    final double bookPercent = totalChapters > 0 ? (currentChapter / totalChapters * 100) : 0.0;
    final String bookPercentStr = bookPercent < 1.0 ? bookPercent.toStringAsFixed(2) : bookPercent.toStringAsFixed(1);

    final l10n = AppLocalizations.of(context)!;

    if (_isCollapsed) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  glassColor,
                  glassColor.withValues(alpha: widget.isDark ? 0.85 : 0.95),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildControlButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  iconSize: 28,
                  onPressed: () {
                    setState(() {
                      _isCollapsed = false;
                    });
                  },
                  tooltip: l10n.expandControls,
                  textColor: widget.textColor,
                  padding: const EdgeInsets.all(6),
                ),
                Text(
                  "$currentParagraph / $totalParagraphs  ($percentStr%)",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor.withValues(alpha: 0.8),
                  ),
                ),
                _buildControlButton(
                  icon: tts.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  iconSize: 28,
                  onPressed: tts.togglePlayPause,
                  tooltip: l10n.actionPlayPause,
                  textColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                glassColor,
                glassColor.withValues(alpha: widget.isDark ? 0.85 : 0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top-Left Collapse Button (Aligned with Expand button in mini mode)
              _buildControlButton(
                icon: Icons.keyboard_arrow_down_rounded,
                iconSize: 28,
                onPressed: () {
                  setState(() {
                    _isCollapsed = true;
                  });
                },
                tooltip: l10n.collapseControls,
                textColor: widget.textColor,
                padding: const EdgeInsets.all(4),
              ),
              // 1. Cụm phím phát nhạc 5 nút đối xứng 100% (2 - 1 - 2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.skip_previous_rounded,
                    iconSize: 24,
                    onPressed: tts.currentChapterIndex > 0 ? tts.previousChapter : null,
                    tooltip: l10n.actionPrevChapter,
                    textColor: widget.textColor,
                    padding: const EdgeInsets.all(10),
                  ),
                  _buildControlButton(
                    icon: Icons.fast_rewind_rounded,
                    iconSize: 28,
                    padding: const EdgeInsets.all(10),
                    onPressed: tts.previousParagraph,
                    tooltip: l10n.actionPrevParagraph,
                    textColor: widget.textColor,
                  ),
                  GestureDetector(
                    onTap: tts.togglePlayPause,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                            Theme.of(context).colorScheme.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        tts.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildControlButton(
                    icon: Icons.fast_forward_rounded,
                    iconSize: 28,
                    padding: const EdgeInsets.all(10),
                    onPressed: tts.nextParagraph,
                    tooltip: l10n.actionNextParagraph,
                    textColor: widget.textColor,
                  ),
                  _buildControlButton(
                    icon: Icons.skip_next_rounded,
                    iconSize: 24,
                    onPressed: tts.currentChapterIndex < tts.chapters.length - 1 ? tts.nextChapter : null,
                    tooltip: l10n.actionNextChapter,
                    textColor: widget.textColor,
                    padding: const EdgeInsets.all(10),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Dãy phím tiện ích gộp chung với Khung thông số tiến trình (1 Hàng duy nhất)
              Row(
                children: [
                  _buildControlButton(
                    icon: Icons.headphones_rounded,
                    iconSize: 20,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => ReaderTtsSettingsSheet(
                          ttsService: widget.ttsService,
                        ),
                      );
                    },
                    tooltip: l10n.ttsSettings,
                    textColor: widget.textColor,
                    padding: const EdgeInsets.all(6),
                  ),
                  _buildControlButton(
                    icon: tts.isSleepTimerActive ? Icons.bedtime_rounded : Icons.bedtime_outlined,
                    iconSize: 20,
                    onPressed: () => _showSleepTimerSheet(context),
                    tooltip: l10n.sleepTimer,
                    textColor: tts.isSleepTimerActive ? Theme.of(context).colorScheme.primary : widget.textColor,
                    padding: const EdgeInsets.all(6),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: widget.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                          width: 1,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.format_align_left_rounded, size: 12, color: widget.textColor.withValues(alpha: 0.5)),
                            const SizedBox(width: 3),
                            Text(
                              "$currentParagraph / $totalParagraphs",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.textColor),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$percentStr%",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            Text(
                              " • ",
                              style: TextStyle(fontSize: 11, color: widget.textColor.withValues(alpha: 0.3)),
                            ),
                            Icon(Icons.menu_book_rounded, size: 12, color: widget.textColor.withValues(alpha: 0.5)),
                            const SizedBox(width: 3),
                            Text(
                              "$currentChapter / $totalChapters",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.textColor),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$bookPercentStr%",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildControlButton(
                    icon: Icons.music_note_rounded,
                    iconSize: 20,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => const BgmPlayerSheet(),
                      );
                    },
                    tooltip: "BGM Player",
                    textColor: widget.textColor,
                    padding: const EdgeInsets.all(6),
                  ),
                  if (widget.onToggleFullscreen != null)
                    _buildControlButton(
                      icon: Icons.fullscreen_rounded,
                      iconSize: 20,
                      onPressed: widget.onToggleFullscreen,
                      tooltip: l10n.toggleFullscreen,
                      textColor: widget.textColor,
                      padding: const EdgeInsets.all(6),
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

