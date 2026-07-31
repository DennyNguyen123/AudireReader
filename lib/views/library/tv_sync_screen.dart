import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/tunnel_service.dart';
import '../../services/sync_service.dart';
import '../../services/webdav_service.dart';
import '../../core/database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class TvSyncScreen extends StatefulWidget {
  const TvSyncScreen({super.key});

  @override
  State<TvSyncScreen> createState() => _TvSyncScreenState();
}

class _TvSyncScreenState extends State<TvSyncScreen> {
  final TunnelService _tunnelService = TunnelService();
  String? _tunnelUrl;
  bool _isConnecting = true;
  bool _isApplyingConfig = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTunnel();
  }

  @override
  void dispose() {
    _tunnelService.stopTunnel();
    super.dispose();
  }

  Future<void> _startTunnel() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    _tunnelService.onConfigReceived = _onConfigReceived;

    final url = await _tunnelService.startTunnel();
    if (mounted) {
      if (url != null) {
        setState(() {
          _tunnelUrl = url;
          _isConnecting = false;
        });
      } else {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'error';
        });
      }
    }
  }

  Future<void> _onConfigReceived(Map<String, dynamic> data) async {
    if (_isApplyingConfig) return;
    setState(() {
      _isApplyingConfig = true;
    });

    try {
      final db = await DatabaseHelper.getInstance();
      var settings = await db.getSettings();

      // 1. Áp dụng cấu hình WebDAV
      final webDavUrl = data['webDavUrl'] as String? ?? '';
      final webDavUsername = data['webDavUsername'] as String? ?? '';
      final webDavPassword = data['webDavPassword'] as String? ?? '';
      final deviceName = data['deviceName'] as String? ?? 'Thiết bị khác';

      settings = settings.copyWith(
        webDavUrl: webDavUrl,
        webDavUsername: webDavUsername,
        webDavEnabled: true,
      );

      const storage = FlutterSecureStorage();
      await storage.write(key: 'webdav_password', value: webDavPassword);

      // 2. Áp dụng các settings khác (nếu có)
      if (data.containsKey('settings')) {
        final customSettings = data['settings'] as Map<String, dynamic>;
        settings = settings.copyWith(
          fontSize: customSettings.containsKey('fontSize') ? (customSettings['fontSize'] as num).toDouble() : settings.fontSize,
          speechRate: customSettings.containsKey('speechRate') ? (customSettings['speechRate'] as num).toDouble() : settings.speechRate,
          selectedVoiceName: customSettings.containsKey('selectedVoiceName') ? customSettings['selectedVoiceName'] : settings.selectedVoiceName,
          selectedVoiceLocale: customSettings.containsKey('selectedVoiceLocale') ? customSettings['selectedVoiceLocale'] : settings.selectedVoiceLocale,
          ttsProvider: customSettings.containsKey('ttsProvider') ? customSettings['ttsProvider'] : settings.ttsProvider,
          openAiTtsEndpoint: customSettings.containsKey('openAiTtsEndpoint') ? customSettings['openAiTtsEndpoint'] : settings.openAiTtsEndpoint,
          openAiTtsApiKey: customSettings.containsKey('openAiTtsApiKey') ? customSettings['openAiTtsApiKey'] : settings.openAiTtsApiKey,
          openAiTtsModel: customSettings.containsKey('openAiTtsModel') ? customSettings['openAiTtsModel'] : settings.openAiTtsModel,
          fontFamily: customSettings.containsKey('fontFamily') ? customSettings['fontFamily'] : settings.fontFamily,
          themeMode: customSettings.containsKey('themeMode') ? customSettings['themeMode'] : settings.themeMode,
          appLocale: customSettings.containsKey('appLocale') ? customSettings['appLocale'] : settings.appLocale,
          lineHeight: customSettings.containsKey('lineHeight') ? (customSettings['lineHeight'] as num).toDouble() : settings.lineHeight,
          paragraphSpacing: customSettings.containsKey('paragraphSpacing') ? (customSettings['paragraphSpacing'] as num).toDouble() : settings.paragraphSpacing,
          textAlignment: customSettings.containsKey('textAlignment') ? customSettings['textAlignment'] : settings.textAlignment,
          sideMargin: customSettings.containsKey('sideMargin') ? (customSettings['sideMargin'] as num).toDouble() : settings.sideMargin,
          customBackgroundColor: customSettings.containsKey('customBackgroundColor') ? customSettings['customBackgroundColor'] : settings.customBackgroundColor,
          customTextColor: customSettings.containsKey('customTextColor') ? customSettings['customTextColor'] : settings.customTextColor,
          primaryColorHex: customSettings.containsKey('primaryColorHex') ? customSettings['primaryColorHex'] : settings.primaryColorHex,
          openLastReadOnLaunch: customSettings.containsKey('openLastReadOnLaunch') ? customSettings['openLastReadOnLaunch'] : settings.openLastReadOnLaunch,
          hotkeyNextParagraph: customSettings.containsKey('hotkeyNextParagraph') ? customSettings['hotkeyNextParagraph'] : settings.hotkeyNextParagraph,
          hotkeyPrevParagraph: customSettings.containsKey('hotkeyPrevParagraph') ? customSettings['hotkeyPrevParagraph'] : settings.hotkeyPrevParagraph,
          hotkeyNextChapter: customSettings.containsKey('hotkeyNextChapter') ? customSettings['hotkeyNextChapter'] : settings.hotkeyNextChapter,
          hotkeyPrevChapter: customSettings.containsKey('hotkeyPrevChapter') ? customSettings['hotkeyPrevChapter'] : settings.hotkeyPrevChapter,
          hotkeyPlayPauseTts: customSettings.containsKey('hotkeyPlayPauseTts') ? customSettings['hotkeyPlayPauseTts'] : settings.hotkeyPlayPauseTts,
          hotkeyOpenChapter: customSettings.containsKey('hotkeyOpenChapter') ? customSettings['hotkeyOpenChapter'] : settings.hotkeyOpenChapter,
          hotkeyOpenSetting: customSettings.containsKey('hotkeyOpenSetting') ? customSettings['hotkeyOpenSetting'] : settings.hotkeyOpenSetting,
          hotkeyBossKey: customSettings.containsKey('hotkeyBossKey') ? customSettings['hotkeyBossKey'] : settings.hotkeyBossKey,
          bossKeyAction: customSettings.containsKey('bossKeyAction') ? customSettings['bossKeyAction'] : settings.bossKeyAction,
          autoCheckUpdate: customSettings.containsKey('autoCheckUpdate') ? customSettings['autoCheckUpdate'] : settings.autoCheckUpdate,
          bgmEnabled: customSettings.containsKey('bgmEnabled') ? customSettings['bgmEnabled'] : settings.bgmEnabled,
          bgmVolume: customSettings.containsKey('bgmVolume') ? (customSettings['bgmVolume'] as num).toDouble() : settings.bgmVolume,
          bgmLoopMode: customSettings.containsKey('bgmLoopMode') ? customSettings['bgmLoopMode'] : settings.bgmLoopMode,
          bgmProviderId: customSettings.containsKey('bgmProviderId') ? customSettings['bgmProviderId'] : settings.bgmProviderId,
          sortBy: customSettings.containsKey('sortBy') ? customSettings['sortBy'] : settings.sortBy,
          developerMode: customSettings.containsKey('developerMode') ? customSettings['developerMode'] : settings.developerMode,
          enableDebugLogs: customSettings.containsKey('enableDebugLogs') ? customSettings['enableDebugLogs'] : settings.enableDebugLogs,
          enableWebDavDebug: customSettings.containsKey('enableWebDavDebug') ? customSettings['enableWebDavDebug'] : settings.enableWebDavDebug,
        );
      }

      await db.saveSettings(settings);

      // 3. Khởi tạo WebDAV và test connection
      final webdav = WebDavService.getInstance();
      await webdav.init(webDavUrl, webDavUsername, webDavPassword);
      final connected = await webdav.testConnection();

      if (mounted) {
        if (connected) {
          // 4. Trigger Pull dữ liệu để đồng bộ ngay lập tức
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.webdavConnectionSuccess ??
                    'Kết nối WebDAV thành công! Đang đồng bộ thư viện...',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Chạy pull ngầm để lấy sách và tiến trình về
          SyncService.getInstance().forcePull(progressOnly: false).then((
            syncResult,
          ) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    syncResult.success
                        ? (AppLocalizations.of(context)?.librarySyncSuccess ??
                              'Đồng bộ thư viện thành công!')
                        : (AppLocalizations.of(
                                context,
                              )?.librarySyncFailed(syncResult.message) ??
                              'Đồng bộ thư viện thất bại: ${syncResult.message}'),
                  ),
                  backgroundColor: syncResult.success
                      ? Colors.green
                      : Colors.orange,
                ),
              );
            }
          });

          // Đóng màn hình
          Navigator.pop(context, true);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                AppLocalizations.of(context)?.webdavConnectionErrorTitle ??
                    'Lỗi kết nối WebDAV',
              ),
              content: Text(
                AppLocalizations.of(
                      context,
                    )?.webdavConnectionErrorDesc(deviceName) ??
                    'Cấu hình đã nhận từ "$deviceName", nhưng không thể kết nối tới máy chủ WebDAV. Vui lòng kiểm tra lại cấu hình trên máy chủ WebDAV.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          setState(() {
            _isApplyingConfig = false;
          });
        }
      }
    } catch (e) {
      print('Lỗi áp dụng cấu hình QR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.applyConfigError(e.toString()) ??
                  'Lỗi áp dụng cấu hình: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isApplyingConfig = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.receiveConfigQr ??
              'Nhận cấu hình qua QR',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 36.0,
                  horizontal: 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.receiverDevice ??
                          'Thiết bị Nhận cấu hình',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)?.receiverDeviceDesc ??
                          'Sử dụng thiết bị khác quét mã QR bên dưới để tự động truyền cấu hình đồng bộ sang máy này.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Trạng thái / QR Code
                    if (_isConnecting)
                      SizedBox(
                        height: 220,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(
                                      context,
                                    )?.connectingTunnel ??
                                    'Đang kết nối SSH tunnel (localhost.run)...',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_errorMessage != null)
                      SizedBox(
                        height: 220,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.redAccent,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(
                                      context,
                                    )?.failedToInitTunnel ??
                                    'Không thể khởi tạo Tunnel. Vui lòng kiểm tra lại kết nối mạng hoặc thử lại sau.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _startTunnel,
                                child: Text(
                                  AppLocalizations.of(context)?.retry ??
                                      'Thử lại',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_tunnelUrl != null)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: '${_tunnelUrl!}/config',
                              version: QrVersions.auto,
                              size: 200.0,
                              gapless: false,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              '${_tunnelUrl!}/config',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 32),
                    if (_isApplyingConfig)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)?.applyingConfig ??
                                'Đang áp dụng cấu hình và đồng bộ...',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: Text(
                          AppLocalizations.of(context)?.cancel ?? 'Hủy bỏ',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
