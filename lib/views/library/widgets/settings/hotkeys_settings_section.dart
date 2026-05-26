import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/shortcut_helper.dart';
import '../../../../l10n/app_localizations.dart';
import 'settings_card.dart';

class HotkeysSettingsSection extends StatefulWidget {
  final String hotkeyNextParagraph;
  final String hotkeyPrevParagraph;
  final String hotkeyNextChapter;
  final String hotkeyPrevChapter;
  final String hotkeyPlayPauseTts;
  final String hotkeyOpenChapter;
  final String hotkeyOpenSetting;
  final String hotkeyBossKey;
  final String bossKeyAction;
  final Function(String, String) onHotkeyRecordAndSave; // (key, value)
  final ValueChanged<String?> onBossKeyActionChanged;
  final VoidCallback onResetHotkeys;

  const HotkeysSettingsSection({
    super.key,
    required this.hotkeyNextParagraph,
    required this.hotkeyPrevParagraph,
    required this.hotkeyNextChapter,
    required this.hotkeyPrevChapter,
    required this.hotkeyPlayPauseTts,
    required this.hotkeyOpenChapter,
    required this.hotkeyOpenSetting,
    required this.hotkeyBossKey,
    required this.bossKeyAction,
    required this.onHotkeyRecordAndSave,
    required this.onBossKeyActionChanged,
    required this.onResetHotkeys,
  });

  @override
  State<HotkeysSettingsSection> createState() => _HotkeysSettingsSectionState();
}

class _HotkeysSettingsSectionState extends State<HotkeysSettingsSection> {
  void _showHotkeyRecorder(String keyName, String currentVal, Function(String) onSave) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String recordedShortcut = '';
        final List<String> pressedModifiers = [];
        bool isRecording = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return KeyboardListener(
              focusNode: FocusNode()..requestFocus(),
              onKeyEvent: (KeyEvent event) {
                if (!isRecording) return;

                final isDown = event is KeyDownEvent || event is KeyRepeatEvent;

                if (isDown) {
                  final Set<LogicalKeyboardKey> modifiers = HardwareKeyboard.instance.logicalKeysPressed;

                  final List<String> mods = [];
                  if (modifiers.contains(LogicalKeyboardKey.controlLeft) ||
                      modifiers.contains(LogicalKeyboardKey.controlRight) ||
                      HardwareKeyboard.instance.isControlPressed) {
                    mods.add('Control');
                  }
                  if (modifiers.contains(LogicalKeyboardKey.shiftLeft) ||
                      modifiers.contains(LogicalKeyboardKey.shiftRight) ||
                      HardwareKeyboard.instance.isShiftPressed) {
                    mods.add('Shift');
                  }
                  if (modifiers.contains(LogicalKeyboardKey.altLeft) ||
                      modifiers.contains(LogicalKeyboardKey.altRight) ||
                      HardwareKeyboard.instance.isAltPressed) {
                    mods.add('Alt');
                  }
                  if (modifiers.contains(LogicalKeyboardKey.metaLeft) ||
                      modifiers.contains(LogicalKeyboardKey.metaRight) ||
                      HardwareKeyboard.instance.isMetaPressed) {
                    mods.add('Meta');
                  }

                  final LogicalKeyboardKey mainKey = event.logicalKey;
                  final bool isModifier = mainKey == LogicalKeyboardKey.control ||
                      mainKey == LogicalKeyboardKey.controlLeft ||
                      mainKey == LogicalKeyboardKey.controlRight ||
                      mainKey == LogicalKeyboardKey.shift ||
                      mainKey == LogicalKeyboardKey.shiftLeft ||
                      mainKey == LogicalKeyboardKey.shiftRight ||
                      mainKey == LogicalKeyboardKey.alt ||
                      mainKey == LogicalKeyboardKey.altLeft ||
                      mainKey == LogicalKeyboardKey.altRight ||
                      mainKey == LogicalKeyboardKey.meta ||
                      mainKey == LogicalKeyboardKey.metaLeft ||
                      mainKey == LogicalKeyboardKey.metaRight;

                  setDialogState(() {
                    pressedModifiers.clear();
                    pressedModifiers.addAll(mods);

                    if (!isModifier) {
                      final List<String> shortcutParts = [];
                      shortcutParts.addAll(pressedModifiers);

                      String keyLabel = mainKey.keyLabel;

                      if (mainKey == LogicalKeyboardKey.arrowDown) {
                        keyLabel = 'Arrow Down';
                      } else if (mainKey == LogicalKeyboardKey.arrowUp) {
                        keyLabel = 'Arrow Up';
                      } else if (mainKey == LogicalKeyboardKey.arrowLeft) {
                        keyLabel = 'Arrow Left';
                      } else if (mainKey == LogicalKeyboardKey.arrowRight) {
                        keyLabel = 'Arrow Right';
                      } else if (mainKey == LogicalKeyboardKey.space) {
                        keyLabel = 'Space';
                      } else if (mainKey == LogicalKeyboardKey.enter) {
                        keyLabel = 'Enter';
                      } else if (mainKey == LogicalKeyboardKey.escape) {
                        keyLabel = 'Escape';
                      } else if (mainKey == LogicalKeyboardKey.comma) {
                        keyLabel = 'comma';
                      } else if (mainKey == LogicalKeyboardKey.period) {
                        keyLabel = 'period';
                      } else if (mainKey == LogicalKeyboardKey.slash) {
                        keyLabel = 'slash';
                      } else if (mainKey == LogicalKeyboardKey.tab) {
                        keyLabel = 'Tab';
                      } else if (mainKey == LogicalKeyboardKey.backspace) {
                        keyLabel = 'Backspace';
                      } else if (mainKey == LogicalKeyboardKey.delete) {
                        keyLabel = 'Delete';
                      }

                      shortcutParts.add(keyLabel);
                      recordedShortcut = shortcutParts.join('+');
                      isRecording = false;
                    } else {
                      recordedShortcut = '${pressedModifiers.join(' + ')} + ...';
                    }
                  });
                }
              },
              child: AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  AppLocalizations.of(context)?.recordHotkey(keyName) ?? 'Record Hotkey: $keyName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.pressHotkeyDesc ?? 'Press your keyboard combination. Avoid using system reserve keys.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          recordedShortcut.isEmpty
                              ? (AppLocalizations.of(context)?.pressKeys ?? 'Press keys...')
                              : ShortcutHelper.getDisplayLabel(recordedShortcut),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: recordedShortcut.isEmpty
                                ? (isDark ? Colors.white30 : Colors.black26)
                                : Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isRecording)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)?.capturedSuccess ?? 'Captured successfully!',
                            style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.listeningKeystroke ?? 'Listening for keystroke...',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)?.cancel ?? 'Cancel',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!isRecording)
                    ElevatedButton(
                      onPressed: () {
                        onSave(recordedShortcut);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(AppLocalizations.of(context)?.save ?? 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        setDialogState(() {
                          recordedShortcut = '';
                          pressedModifiers.clear();
                          isRecording = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(AppLocalizations.of(context)?.reset ?? 'Reset', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHotkeyItem(String name, String currentShortcut, Function(String) onRecord) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showHotkeyRecorder(name, currentShortcut, onRecord),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  ShortcutHelper.getDisplayLabel(currentShortcut),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.keyboard_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.hotkeyConfigurations ?? 'Hotkey Configurations',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.customizeHotkeysDesc ?? 'Customize keyboard shortcuts for system commands and reading controls.',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          _buildHotkeyItem(
            AppLocalizations.of(context)?.nextParagraph ?? 'Next Paragraph',
            widget.hotkeyNextParagraph,
            (val) => widget.onHotkeyRecordAndSave('nextParagraph', val),
          ),
          _buildHotkeyItem(
            AppLocalizations.of(context)?.prevParagraph ?? 'Previous Paragraph',
            widget.hotkeyPrevParagraph,
            (val) => widget.onHotkeyRecordAndSave('prevParagraph', val),
          ),
          _buildHotkeyItem(
            AppLocalizations.of(context)?.nextChapter ?? 'Next Chapter',
            widget.hotkeyNextChapter,
            (val) => widget.onHotkeyRecordAndSave('nextChapter', val),
          ),
          _buildHotkeyItem(
            AppLocalizations.of(context)?.prevChapter ?? 'Previous Chapter',
            widget.hotkeyPrevChapter,
            (val) => widget.onHotkeyRecordAndSave('prevChapter', val),
          ),
          _buildHotkeyItem(
            AppLocalizations.of(context)?.playPauseTts ?? 'Play/Pause TTS',
            widget.hotkeyPlayPauseTts,
            (val) => widget.onHotkeyRecordAndSave('playPauseTts', val),
          ),
          _buildHotkeyItem(
            AppLocalizations.of(context)?.openChapterShelf ?? 'Open Chapter Shelf',
            widget.hotkeyOpenChapter,
            (val) => widget.onHotkeyRecordAndSave('openChapter', val),
          ),
          _buildHotkeyItem(
            AppLocalizations.of(context)?.openReaderSetting ?? 'Open Reader Setting',
            widget.hotkeyOpenSetting,
            (val) => widget.onHotkeyRecordAndSave('openSetting', val),
          ),
          _buildHotkeyItem(
            AppLocalizations.of(context)?.bossKey ?? 'Boss Key',
            widget.hotkeyBossKey,
            (val) => widget.onHotkeyRecordAndSave('bossKey', val),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, color: Colors.white10),
          ),

          Text(
            AppLocalizations.of(context)?.bossKeyActionLabel ?? 'Boss Key Action',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: ['minimize', 'hide'].contains(widget.bossKeyAction) ? widget.bossKeyAction : 'minimize',
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.black12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            items: [
              DropdownMenuItem(
                value: 'minimize',
                child: Text(AppLocalizations.of(context)?.minimizeWindow ?? 'Minimize Window'),
              ),
              DropdownMenuItem(
                value: 'hide',
                child: Text(AppLocalizations.of(context)?.hideWindow ?? 'Hide Window (Completely invisible)'),
              ),
            ],
            onChanged: widget.onBossKeyActionChanged,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onResetHotkeys,
                  icon: const Icon(Icons.restore_rounded),
                  label: Text(
                    AppLocalizations.of(context)?.resetHotkeys ?? 'Reset to Default Hotkeys',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
