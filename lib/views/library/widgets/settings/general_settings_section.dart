import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'settings_card.dart';

class GeneralSettingsSection extends StatelessWidget {
  final bool openLastReadOnLaunch;
  final bool autoCheckUpdate;
  final String appLocaleCode;
  final bool isCheckingUpdate;
  final ValueChanged<bool> onOpenLastReadChanged;
  final ValueChanged<bool> onAutoCheckUpdateChanged;
  final ValueChanged<String?> onLocaleChanged;
  final VoidCallback onCheckUpdates;

  const GeneralSettingsSection({
    super.key,
    required this.openLastReadOnLaunch,
    required this.autoCheckUpdate,
    required this.appLocaleCode,
    required this.isCheckingUpdate,
    required this.onOpenLastReadChanged,
    required this.onAutoCheckUpdateChanged,
    required this.onLocaleChanged,
    required this.onCheckUpdates,
  });

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
              Icon(Icons.settings_suggest_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.generalPreferences ?? 'General Preferences',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppLocalizations.of(context)?.openLastReadOnLaunch ?? 'Auto-Open Last Read',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.openLastReadDesc ?? 'Automatically resume reading the most recently read book on launch.',
              style: const TextStyle(fontSize: 11),
            ),
            value: openLastReadOnLaunch,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: onOpenLastReadChanged,
          ),
          const Divider(height: 1, thickness: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppLocalizations.of(context)?.autoCheckUpdate ?? 'Auto Check for Updates',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.autoCheckUpdateDesc ?? 'Automatically check for new versions from GitHub when the app starts.',
              style: const TextStyle(fontSize: 11),
            ),
            value: autoCheckUpdate,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: onAutoCheckUpdateChanged,
          ),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)?.language ?? 'Language',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: appLocaleCode,
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
              DropdownMenuItem<String>(
                value: 'en',
                child: Text(AppLocalizations.of(context)?.english ?? 'English', style: const TextStyle(fontSize: 13)),
              ),
              DropdownMenuItem<String>(
                value: 'vi',
                child: Text(AppLocalizations.of(context)?.vietnamese ?? 'Vietnamese', style: const TextStyle(fontSize: 13)),
              ),
            ],
            onChanged: onLocaleChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCheckingUpdate ? null : onCheckUpdates,
                  icon: isCheckingUpdate
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                        )
                      : const Icon(Icons.system_update_alt_rounded),
                  label: Text(
                    AppLocalizations.of(context)?.checkUpdates ?? 'Check for Updates',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
