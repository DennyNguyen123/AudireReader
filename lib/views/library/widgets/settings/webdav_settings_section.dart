import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'settings_card.dart';

class WebdavSettingsSection extends StatelessWidget {
  final bool webDavEnabled;
  final bool autoSyncEnabled;
  final TextEditingController urlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController deviceNameController;
  final bool isTestingConnection;
  final String? testResult;
  final bool testSuccess;
  final DateTime? lastSync;
  final bool isLoading;
  final ValueChanged<bool> onWebDavEnabledChanged;
  final ValueChanged<bool> onAutoSyncEnabledChanged;
  final VoidCallback onTestConnection;
  final VoidCallback onSyncNow;
  final VoidCallback onForcePush;
  final VoidCallback onForcePull;
  final VoidCallback onSettingsChanged;
  final VoidCallback? onQrSyncPressed;

  const WebdavSettingsSection({
    super.key,
    required this.webDavEnabled,
    required this.autoSyncEnabled,
    required this.urlController,
    required this.usernameController,
    required this.passwordController,
    required this.deviceNameController,
    required this.isTestingConnection,
    required this.testResult,
    required this.testSuccess,
    required this.lastSync,
    required this.isLoading,
    required this.onWebDavEnabledChanged,
    required this.onAutoSyncEnabledChanged,
    required this.onTestConnection,
    required this.onSyncNow,
    required this.onForcePush,
    required this.onForcePull,
    required this.onSettingsChanged,
    this.onQrSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.primary;

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề & Mô tả chính
          Row(
            children: [
              Icon(Icons.cloud_sync_rounded, color: accentColor, size: 28),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.cloudLibrarySync ?? 'Cloud Library Sync',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)?.cloudSyncDesc ??
                'Synchronize your novel shelf, cover arts, exact reading progress, and book contents across devices using a private WebDAV server.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1, color: Colors.white10),
          ),

          // Switch bật/tắt WebDAV
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppLocalizations.of(context)?.enableWebdav ?? 'Enable WebDAV Sync',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.enableWebdavDesc ?? 'Đồng bộ thư viện qua máy chủ WebDAV cá nhân',
              style: const TextStyle(fontSize: 12),
            ),
            value: webDavEnabled,
            activeThumbColor: accentColor,
            onChanged: onWebDavEnabledChanged,
          ),

          if (webDavEnabled) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1, color: Colors.white10),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)?.autoSyncEnabled ?? 'Auto Sync WebDAV',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text(
                AppLocalizations.of(context)?.autoSyncEnabledDesc ?? 'Automatically synchronize library on launch or leaving a book',
                style: const TextStyle(fontSize: 12),
              ),
              value: autoSyncEnabled,
              activeThumbColor: accentColor,
              onChanged: onAutoSyncEnabledChanged,
            ),
          ],

          // Phần mở rộng cấu hình & trạng thái (chỉ hiện khi bật WebDAV)
          if (webDavEnabled) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, color: Colors.white10),
            ),

            Text(
              AppLocalizations.of(context)?.webdavServerConfig ?? 'WebDAV Server Configuration',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),

            // URL Server WebDAV
            TextFormField(
              controller: urlController,
              onChanged: (_) => onSettingsChanged(),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.webdavServerUrl ?? 'WebDAV Server URL',
                hintText: 'https://webdav.yandex.ru',
                prefixIcon: const Icon(Icons.link_rounded),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                if (webDavEnabled && (val == null || val.trim().isEmpty)) {
                  return AppLocalizations.of(context)?.enterWebdavUrl ?? 'Please enter WebDAV URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Username
            TextFormField(
              controller: usernameController,
              onChanged: (_) => onSettingsChanged(),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.username ?? 'Username',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                if (webDavEnabled && (val == null || val.trim().isEmpty)) {
                  return AppLocalizations.of(context)?.enterUsername ?? 'Please enter Username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: passwordController,
              obscureText: true,
              onChanged: (_) => onSettingsChanged(),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.passwordAppPassword ?? 'Password / App Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                if (webDavEnabled && (val == null || val.isEmpty)) {
                  return AppLocalizations.of(context)?.enterPassword ?? 'Please enter Password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Device Name
            TextFormField(
              controller: deviceNameController,
              onChanged: (_) => onSettingsChanged(),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.deviceName ?? 'Device Name',
                hintText: 'My Phone',
                prefixIcon: const Icon(Icons.devices_rounded),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                if (webDavEnabled && (val == null || val.trim().isEmpty)) {
                  return AppLocalizations.of(context)?.enterDeviceName ?? 'Please enter Device Name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            if (onQrSyncPressed != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onQrSyncPressed,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(
                        AppLocalizations.of(context)?.qrDeviceSync ?? 'Đồng bộ nhanh thiết bị (QR)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor.withOpacity(0.12),
                        foregroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Nút Test Connection
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isTestingConnection ? null : onTestConnection,
                    icon: isTestingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.network_ping_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.testConnection ?? 'Test Connection',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[850],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            // Hiển thị kết quả kiểm thử kết nối
            if (testResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: testSuccess ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: testSuccess ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      testSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                      color: testSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        testResult!,
                        style: TextStyle(
                          color: testSuccess ? Colors.green[300] : Colors.red[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, color: Colors.white10),
            ),

            // Trạng thái Đồng bộ & Nút Sync Now
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)?.syncStatus ?? 'Sync Status',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  lastSync != null
                      ? (AppLocalizations.of(context)?.lastSyncedAt(lastSync!.toLocal().toString().split('.')[0]) ??
                          'Last Synced: ${lastSync!.toLocal().toString().split('.')[0]}')
                      : (AppLocalizations.of(context)?.lastSyncedNever ?? 'Last Synced: Never'),
                  style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onSyncNow,
              icon: const Icon(Icons.sync_rounded),
              label: Text(
                AppLocalizations.of(context)?.syncNow ?? 'Sync Now',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onForcePush,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.forcePush ?? 'Force Push',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onForcePull,
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.forcePull ?? 'Force Pull',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
