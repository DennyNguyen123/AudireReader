import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'settings_card.dart';

class DeveloperSettingsSection extends StatelessWidget {
  final bool developerMode;
  final ValueChanged<bool> onDeveloperModeChanged;
  final VoidCallback onOpenDebugConsole;
  final VoidCallback onShowDatabaseInspector;
  final VoidCallback onClearCacheAndResetSync;
  final VoidCallback onForceSyncNow;

  const DeveloperSettingsSection({
    super.key,
    required this.developerMode,
    required this.onDeveloperModeChanged,
    required this.onOpenDebugConsole,
    required this.onShowDatabaseInspector,
    required this.onClearCacheAndResetSync,
    required this.onForceSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppLocalizations.of(context)?.developerMode ?? 'Developer Mode',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.developerModeDesc ??
                  'Unlock advanced diagnostic tools, database inspector, and system logs.',
              style: const TextStyle(fontSize: 11),
            ),
            value: developerMode,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: onDeveloperModeChanged,
          ),
          if (developerMode) ...[
            const Divider(height: 32, thickness: 1),
            Row(
              children: [
                Icon(
                  Icons.developer_mode_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)?.developerSettings ??
                      'Developer Settings',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onOpenDebugConsole,
                    icon: const Icon(Icons.terminal_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.openDebugConsole ??
                          'Open Debug Console',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShowDatabaseInspector,
                    icon: const Icon(Icons.storage_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.databaseInspector ??
                          'Database Inspector',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClearCacheAndResetSync,
                    icon: const Icon(Icons.cleaning_services_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.clearCache ??
                          'Clear Cache & Reset Sync',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onForceSyncNow,
                    icon: const Icon(Icons.sync_problem_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.forceSyncNow ??
                          'Force Sync Now',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
