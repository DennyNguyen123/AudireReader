import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/tts_service.dart';

class SleepTimerSheet extends StatefulWidget {
  final TtsService ttsService;

  const SleepTimerSheet({super.key, required this.ttsService});

  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  void _showCustomSleepTimerDialog(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)?.sleepTimer ?? 'Sleep Timer',
          ),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes',
              hintText: 'Enter minutes',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                final int? minutes = int.tryParse(textController.text);
                if (minutes != null && minutes > 0) {
                  widget.ttsService.startSleepTimer(minutes);
                }
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimerOptionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.2)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06)),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? accentColor
                    : textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? accentColor : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.scaffoldBackgroundColor;
    final labelColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white70 : Colors.black87);
    final accentColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: ListenableBuilder(
            listenable: widget.ttsService,
            builder: (context, _) {
              final isTimerActive = widget.ttsService.isSleepTimerActive;
              final isStopAtEnd = widget.ttsService.stopAtEndOfChapter;
              final remainingSec = widget.ttsService.sleepTimerDuration ?? 0;
              final remainingMin = remainingSec ~/ 60;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.timer_outlined,
                              size: 20,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context)?.sleepTimer ??
                                'Sleep Timer',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close_rounded,
                          color: labelColor.withValues(alpha: 0.7),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Active Countdown Display Badge
                  if (isTimerActive || isStopAtEnd) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.2),
                            accentColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isStopAtEnd
                                ? Icons.auto_stories_rounded
                                : Icons.hourglass_top_rounded,
                            size: 26,
                            color: accentColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isStopAtEnd
                                      ? AppLocalizations.of(
                                          context,
                                        )!.sleepTimerStopAtEnd
                                      : AppLocalizations.of(
                                          context,
                                        )!.sleepTimerRemaining(
                                          '${(remainingSec ~/ 60).toString().padLeft(2, '0')}:${(remainingSec % 60).toString().padLeft(2, '0')}',
                                        ),
                                  style: TextStyle(
                                    fontSize: isStopAtEnd ? 13 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: labelColor,
                                  ),
                                ),
                                if (isTimerActive)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Auto pause when timer ends',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: labelColor.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isTimerActive)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: accentColor,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text(
                                '+15m',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                widget.ttsService.startSleepTimer(
                                  remainingMin + 15,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Timer Preset Grid Options (2x3 Layout)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: [
                      _buildTimerOptionCard(
                        context: context,
                        title: AppLocalizations.of(context)!.off,
                        icon: Icons.timer_off_outlined,
                        isSelected: !isTimerActive && !isStopAtEnd,
                        onTap: () {
                          widget.ttsService.cancelSleepTimer();
                          widget.ttsService.enableStopAtEndOfChapter(false);
                        },
                        accentColor: accentColor,
                        textColor: labelColor,
                        isDark: isDark,
                      ),
                      _buildTimerOptionCard(
                        context: context,
                        title: '15 Min',
                        icon: Icons.access_time_rounded,
                        isSelected: isTimerActive && remainingMin == 15,
                        onTap: () => widget.ttsService.startSleepTimer(15),
                        accentColor: accentColor,
                        textColor: labelColor,
                        isDark: isDark,
                      ),
                      _buildTimerOptionCard(
                        context: context,
                        title: '30 Min',
                        icon: Icons.access_time_filled_rounded,
                        isSelected: isTimerActive && remainingMin == 30,
                        onTap: () => widget.ttsService.startSleepTimer(30),
                        accentColor: accentColor,
                        textColor: labelColor,
                        isDark: isDark,
                      ),
                      _buildTimerOptionCard(
                        context: context,
                        title: '45 Min',
                        icon: Icons.alarm_on_rounded,
                        isSelected: isTimerActive && remainingMin == 45,
                        onTap: () => widget.ttsService.startSleepTimer(45),
                        accentColor: accentColor,
                        textColor: labelColor,
                        isDark: isDark,
                      ),
                      _buildTimerOptionCard(
                        context: context,
                        title: AppLocalizations.of(context)!.endChapter,
                        icon: Icons.auto_stories_rounded,
                        isSelected: isStopAtEnd,
                        onTap: () {
                          widget.ttsService.enableStopAtEndOfChapter(true);
                        },
                        accentColor: accentColor,
                        textColor: labelColor,
                        isDark: isDark,
                      ),
                      _buildTimerOptionCard(
                        context: context,
                        title: 'Custom...',
                        icon: Icons.edit_calendar_rounded,
                        isSelected:
                            isTimerActive &&
                            ![15, 30, 45].contains(remainingMin),
                        onTap: () => _showCustomSleepTimerDialog(context),
                        accentColor: accentColor,
                        textColor: labelColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
    );
  }
}
