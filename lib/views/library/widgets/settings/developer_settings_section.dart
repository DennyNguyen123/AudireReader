import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'settings_card.dart';

class DeveloperSettingsSection extends StatelessWidget {
  final bool developerMode;
  final bool enableDebugLogs;
  final bool enableWebDavDebug;
  final ValueChanged<bool> onDeveloperModeChanged;
  final ValueChanged<bool> onEnableDebugLogsChanged;
  final ValueChanged<bool> onEnableWebDavDebugChanged;
  final VoidCallback onOpenDebugConsole;
  final VoidCallback onShowDatabaseInspector;
  final VoidCallback onClearCacheAndResetSync;
  final VoidCallback onForceSyncNow;

  const DeveloperSettingsSection({
    super.key,
    required this.developerMode,
    required this.enableDebugLogs,
    required this.enableWebDavDebug,
    required this.onDeveloperModeChanged,
    required this.onEnableDebugLogsChanged,
    required this.onEnableWebDavDebugChanged,
    required this.onOpenDebugConsole,
    required this.onShowDatabaseInspector,
    required this.onClearCacheAndResetSync,
    required this.onForceSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          child: SwitchListTile(
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
            activeThumbColor: Colors.amber[700],
            onChanged: onDeveloperModeChanged,
          ),
        ),
        if (developerMode) ...[
          const SizedBox(height: 20),
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.developer_mode_rounded, color: Colors.amber[700], size: 28),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)?.developerSettings ?? 'Developer Settings',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppLocalizations.of(context)?.enableDebugLogsLabel ?? 'Enable Debug Logs',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)?.debugLogsDesc ??
                        'Keep a history of application logs for troubleshooting.',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: enableDebugLogs,
                  activeThumbColor: Colors.amber[700],
                  onChanged: onEnableDebugLogsChanged,
                ),
                const Divider(height: 1, thickness: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppLocalizations.of(context)?.webdavDebugConsole ?? 'WebDAV Debug Console',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)?.webdavDebugDesc ??
                        'Output raw WebDAV HTTP requests and responses to system log.',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: enableWebDavDebug,
                  activeThumbColor: Colors.amber[700],
                  onChanged: onEnableWebDavDebugChanged,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onOpenDebugConsole,
                        icon: const Icon(Icons.terminal_rounded),
                        label: Text(
                          AppLocalizations.of(context)?.openDebugConsole ?? 'Open Debug Console',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          AppLocalizations.of(context)?.databaseInspector ?? 'Database Inspector',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[700],
                          side: BorderSide(color: Colors.amber[700]!, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          AppLocalizations.of(context)?.clearCache ?? 'Clear Cache & Reset Sync',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[700],
                          side: BorderSide(color: Colors.amber[700]!, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          AppLocalizations.of(context)?.forceSyncNow ?? 'Force Sync Now',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[700],
                          side: BorderSide(color: Colors.amber[700]!, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
