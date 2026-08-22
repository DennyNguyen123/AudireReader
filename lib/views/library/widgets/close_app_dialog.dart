// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class CloseAppResult {
  final String action; // 'tray' or 'exit'
  final bool remember;

  const CloseAppResult({
    required this.action,
    required this.remember,
  });
}

class CloseAppDialog extends StatefulWidget {
  const CloseAppDialog({super.key});

  static Future<CloseAppResult?> show(BuildContext context) {
    return showDialog<CloseAppResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CloseAppDialog(),
    );
  }

  @override
  State<CloseAppDialog> createState() => _CloseAppDialogState();
}

class _CloseAppDialogState extends State<CloseAppDialog> {
  String _selectedAction = 'tray'; // 'tray' or 'exit'
  bool _rememberChoice = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final title = l10n?.closeAppDialogTitle ?? 'Close Application';
    final message = l10n?.closeAppDialogMessage ??
        'Do you want to minimize to system tray or exit the application?';
    final minimizeTitle = l10n?.minimizeToTray ?? 'Minimize to System Tray';
    final minimizeDesc = l10n?.minimizeToTrayDesc ??
        'App will keep running in the background and can be reopened from the tray.';
    final exitTitle = l10n?.exitApp ?? 'Exit Application';
    final exitDesc = l10n?.exitAppDesc ??
        'Completely terminate the application process.';
    final rememberText = l10n?.rememberChoice ??
        'Remember my choice (Set as default)';
    final cancelText = l10n?.cancel ?? 'Cancel';
    final confirmText = l10n?.confirm ?? 'Confirm';

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Option 1: Minimize to tray
              _buildOptionCard(
                actionKey: 'tray',
                icon: Icons.vertical_align_bottom_rounded,
                title: minimizeTitle,
                description: minimizeDesc,
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // Option 2: Exit app
              _buildOptionCard(
                actionKey: 'exit',
                icon: Icons.exit_to_app_rounded,
                title: exitTitle,
                description: exitDesc,
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              // Remember choice checkbox
              InkWell(
                onTap: () {
                  setState(() {
                    _rememberChoice = !_rememberChoice;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberChoice,
                          activeColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _rememberChoice = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rememberText,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        CloseAppResult(
                          action: _selectedAction,
                          remember: _rememberChoice,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String actionKey,
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _selectedAction == actionKey;
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : (isDark ? Colors.white12 : Colors.black12);
    final bgColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08)
        : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02));

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = actionKey;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.18)
                    : (isDark ? Colors.white10 : Colors.black12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Radio<String>(
              value: actionKey,
              groupValue: _selectedAction,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedAction = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
