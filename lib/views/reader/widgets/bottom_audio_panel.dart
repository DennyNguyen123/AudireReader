import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audire_reader/src/rust/api/models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/tts_service.dart';
import '../../../services/bgm_service.dart';
import 'bgm_player_sheet.dart';
import 'reader_tts_settings_sheet.dart';
import 'sleep_timer_sheet.dart';

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
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadCollapsedState();
  }

  Future<void> _loadCollapsedState() async {
    const storage = FlutterSecureStorage();
    final val = await storage.read(key: 'audio_panel_collapsed');
    if (mounted) {
      setState(() {
        _isCollapsed = val == 'true';
      });
    }
  }

  Future<void> _toggleCollapsed() async {
    const storage = FlutterSecureStorage();
    final newState = !_isCollapsed;
    await storage.write(key: 'audio_panel_collapsed', value: newState.toString());
    if (mounted) {
      setState(() {
        _isCollapsed = newState;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String value,
    String? percent,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: textColor.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        if (percent != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
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
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
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

  Widget _buildUtilityButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color textColor,
    bool isActive = false,
  }) {
    final activeColor = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.15)
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? activeColor.withValues(alpha: 0.4)
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color:
                      isActive ? activeColor : textColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? activeColor
                        : textColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tts = widget.ttsService;
    final totalParagraphs = widget.chapter.paragraphs.length;
    final currentParagraph = tts.currentParagraphIndex + 1;
    final double percent = totalParagraphs > 0
        ? (currentParagraph / totalParagraphs * 100)
        : 0.0;
    final percentStr = percent.toStringAsFixed(1);
    final currentChapter = tts.currentChapterIndex + 1;
    final totalChapters = tts.chapters.length;

    final chapterDuration = tts.getChapterDuration();

    if (_isCollapsed) {
      return Container(
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF1E1E1E).withValues(alpha: 0.96)
              : const Color(0xFFFAF9F6).withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: widget.isDark ? 0.25 : 0.08,
              ),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ListenableBuilder(
              listenable: tts,
              builder: (context, _) {
                return Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: tts.togglePlayPause,
                    child: Ink(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: Icon(
                        tts.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ListenableBuilder(
                listenable: tts,
                builder: (context, _) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCompactStat(
                          icon: Icons.format_align_left_rounded,
                          value: "$currentParagraph / $totalParagraphs",
                          percent: "$percentStr%",
                          textColor: widget.textColor,
                        ),
                        const SizedBox(width: 12),
                        _buildCompactStat(
                          icon: Icons.menu_book_rounded,
                          value: "$currentChapter / $totalChapters",
                          percent: tts.chapterProgressTimeStr,
                          textColor: widget.textColor,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: widget.textColor.withValues(alpha: 0.8),
                size: 24,
              ),
              onPressed: _toggleCollapsed,
              tooltip: "Expand",
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.96)
            : const Color(0xFFFAF9F6).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: widget.isDark ? 0.25 : 0.08,
            ),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: widget.textColor.withValues(alpha: 0.6),
                size: 24,
              ),
              onPressed: _toggleCollapsed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: "Collapse",
            ),
          ),
          StreamBuilder<Duration>(
            stream: AudioService.position,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final currentPositionSec = position.inSeconds.toDouble();

              double sliderValue =
                  _isDragging ? _dragValue : currentPositionSec;
              if (sliderValue < 0) {
                sliderValue = 0.0;
              }
              if (sliderValue > chapterDuration) {
                sliderValue = chapterDuration;
              }

              final currentPositionStr = _formatDuration(
                Duration(seconds: sliderValue.toInt()),
              );
              final durationStr = _formatDuration(
                Duration(seconds: chapterDuration.toInt()),
              );

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                      activeTrackColor:
                          Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: widget.textColor.withValues(
                        alpha: 0.2,
                      ),
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
                                final paragraphs =
                                    widget.chapter.paragraphs;
                                for (
                                  int i = 0;
                                  i < paragraphs.length;
                                  i++
                                ) {
                                  final dur =
                                      paragraphs[i].length / charPerSec;
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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.skip_previous_rounded,
                iconSize: 24,
                onPressed: tts.currentChapterIndex > 0
                    ? tts.previousChapter
                    : null,
                tooltip: l10n?.prevChapterTooltip ?? "Previous Chapter",
                textColor: widget.textColor,
              ),
              _buildControlButton(
                icon: Icons.fast_rewind_rounded,
                iconSize: 30,
                padding: const EdgeInsets.all(8),
                onPressed: tts.previousParagraph,
                tooltip: l10n?.rewindParagraphTooltip ?? "Rewind Paragraph",
                textColor: widget.textColor,
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: tts.togglePlayPause,
                  splashColor: Colors.white.withValues(alpha: 0.3),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Ink(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.9),
                          Theme.of(context).colorScheme.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: tts.isPlaying ? 0 : 2.5,
                        ),
                        child: Icon(
                          tts.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildControlButton(
                icon: Icons.fast_forward_rounded,
                iconSize: 30,
                padding: const EdgeInsets.all(8),
                onPressed: tts.nextParagraph,
                tooltip:
                    l10n?.forwardParagraphTooltip ?? "Forward Paragraph",
                textColor: widget.textColor,
              ),
              _buildControlButton(
                icon: Icons.skip_next_rounded,
                iconSize: 24,
                onPressed:
                    tts.currentChapterIndex < tts.chapters.length - 1
                    ? tts.nextChapter
                    : null,
                tooltip: l10n?.nextChapterTooltip ?? "Next Chapter",
                textColor: widget.textColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: BgmService.getInstance(),
            builder: (context, _) {
              final bgm = BgmService.getInstance();
              final isBgmPlaying = bgm.isPlaying || bgm.bgmEnabled;
              final isSleepActive = tts.isSleepTimerActive;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUtilityButton(
                    icon: Icons.headphones_rounded,
                    label: l10n?.ttsVoiceLabel ?? "TTS Voice",
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
                    textColor: widget.textColor,
                  ),
                  _buildUtilityButton(
                    icon: isSleepActive
                        ? Icons.alarm_on_rounded
                        : Icons.snooze_rounded,
                    label: isSleepActive
                        ? (l10n?.sleepTimerActiveLabel ?? "Timer Active")
                        : (l10n?.sleepTimerLabel ?? "Sleep Timer"),
                    isActive: isSleepActive,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) =>
                            SleepTimerSheet(ttsService: widget.ttsService),
                      );
                    },
                    textColor: widget.textColor,
                  ),
                  _buildUtilityButton(
                    icon: Icons.music_note_rounded,
                    label: isBgmPlaying
                        ? (l10n?.bgmActiveLabel ?? "BGM • On")
                        : (l10n?.bgmLabel ?? "BGM"),
                    isActive: isBgmPlaying,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => const BgmPlayerSheet(),
                      );
                    },
                    textColor: widget.textColor,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                width: 1,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCompactStat(
                    icon: Icons.format_align_left_rounded,
                    value: "$currentParagraph / $totalParagraphs",
                    percent: "$percentStr%",
                    textColor: widget.textColor,
                  ),
                  const SizedBox(width: 12),
                  _buildCompactStat(
                    icon: Icons.menu_book_rounded,
                    value: "$currentChapter / $totalChapters",
                    percent: tts.chapterProgressTimeStr,
                    textColor: widget.textColor,
                  ),
                  const SizedBox(width: 12),
                  _buildCompactStat(
                    icon: Icons.auto_stories_rounded,
                    value: tts.bookProgressTimeStr,
                    textColor: widget.textColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
