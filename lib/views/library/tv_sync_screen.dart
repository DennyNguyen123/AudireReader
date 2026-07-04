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
      final settings = await db.getSettings();

      // 1. Áp dụng cấu hình WebDAV
      final webDavUrl = data['webDavUrl'] as String? ?? '';
      final webDavUsername = data['webDavUsername'] as String? ?? '';
      final webDavPassword = data['webDavPassword'] as String? ?? '';
      final deviceName = data['deviceName'] as String? ?? 'Thiết bị khác';

      settings.webDavUrl = webDavUrl;
      settings.webDavUsername = webDavUsername;
      settings.webDavEnabled = true;

      const storage = FlutterSecureStorage();
      await storage.write(key: 'webdav_password', value: webDavPassword);

      // 2. Áp dụng các settings khác (nếu có)
      if (data.containsKey('settings')) {
        final customSettings = data['settings'] as Map<String, dynamic>;
        
        if (customSettings.containsKey('fontSize')) settings.fontSize = (customSettings['fontSize'] as num).toDouble();
        if (customSettings.containsKey('speechRate')) settings.speechRate = (customSettings['speechRate'] as num).toDouble();
        if (customSettings.containsKey('selectedVoiceName')) settings.selectedVoiceName = customSettings['selectedVoiceName'];
        if (customSettings.containsKey('selectedVoiceLocale')) settings.selectedVoiceLocale = customSettings['selectedVoiceLocale'];
        if (customSettings.containsKey('ttsProvider')) settings.ttsProvider = customSettings['ttsProvider'] ?? 'system';
        
        if (customSettings.containsKey('openAiTtsEndpoint')) settings.openAiTtsEndpoint = customSettings['openAiTtsEndpoint'] ?? '';
        if (customSettings.containsKey('openAiTtsApiKey')) settings.openAiTtsApiKey = customSettings['openAiTtsApiKey'] ?? '';
        if (customSettings.containsKey('openAiTtsModel')) settings.openAiTtsModel = customSettings['openAiTtsModel'] ?? '';
        
        if (customSettings.containsKey('fontFamily')) settings.fontFamily = customSettings['fontFamily'] ?? 'System';
        if (customSettings.containsKey('themeMode')) settings.themeMode = customSettings['themeMode'] ?? 'System';
        if (customSettings.containsKey('appLocale')) settings.appLocale = customSettings['appLocale'] ?? 'en';
        
        if (customSettings.containsKey('lineHeight')) settings.lineHeight = (customSettings['lineHeight'] as num).toDouble();
        if (customSettings.containsKey('paragraphSpacing')) settings.paragraphSpacing = (customSettings['paragraphSpacing'] as num).toDouble();
        if (customSettings.containsKey('textAlignment')) settings.textAlignment = customSettings['textAlignment'] ?? 'left';
        if (customSettings.containsKey('sideMargin')) settings.sideMargin = (customSettings['sideMargin'] as num).toDouble();
        if (customSettings.containsKey('customBackgroundColor')) settings.customBackgroundColor = customSettings['customBackgroundColor'];
        if (customSettings.containsKey('customTextColor')) settings.customTextColor = customSettings['customTextColor'];
        if (customSettings.containsKey('primaryColorHex')) settings.primaryColorHex = customSettings['primaryColorHex'];
        
        if (customSettings.containsKey('openLastReadOnLaunch')) settings.openLastReadOnLaunch = customSettings['openLastReadOnLaunch'] ?? false;
        
        if (customSettings.containsKey('hotkeyNextParagraph')) settings.hotkeyNextParagraph = customSettings['hotkeyNextParagraph'] ?? 'Arrow Down';
        if (customSettings.containsKey('hotkeyPrevParagraph')) settings.hotkeyPrevParagraph = customSettings['hotkeyPrevParagraph'] ?? 'Arrow Up';
        if (customSettings.containsKey('hotkeyNextChapter')) settings.hotkeyNextChapter = customSettings['hotkeyNextChapter'] ?? 'Control+Arrow Right';
        if (customSettings.containsKey('hotkeyPrevChapter')) settings.hotkeyPrevChapter = customSettings['hotkeyPrevChapter'] ?? 'Control+Arrow Left';
        if (customSettings.containsKey('hotkeyPlayPauseTts')) settings.hotkeyPlayPauseTts = customSettings['hotkeyPlayPauseTts'] ?? 'Space';
        if (customSettings.containsKey('hotkeyOpenChapter')) settings.hotkeyOpenChapter = customSettings['hotkeyOpenChapter'] ?? 'Control+o';
        if (customSettings.containsKey('hotkeyOpenSetting')) settings.hotkeyOpenSetting = customSettings['hotkeyOpenSetting'] ?? 'Control+comma';
        if (customSettings.containsKey('hotkeyBossKey')) settings.hotkeyBossKey = customSettings['hotkeyBossKey'] ?? 'Control+b';
        if (customSettings.containsKey('bossKeyAction')) settings.bossKeyAction = customSettings['bossKeyAction'] ?? 'minimize';
        
        if (customSettings.containsKey('autoCheckUpdate')) settings.autoCheckUpdate = customSettings['autoCheckUpdate'] ?? true;
        
        if (customSettings.containsKey('bgmEnabled')) settings.bgmEnabled = customSettings['bgmEnabled'] ?? false;
        if (customSettings.containsKey('bgmVolume')) settings.bgmVolume = (customSettings['bgmVolume'] as num).toDouble();
        if (customSettings.containsKey('bgmLoopMode')) settings.bgmLoopMode = customSettings['bgmLoopMode'] ?? 'all';
        if (customSettings.containsKey('bgmProviderId')) settings.bgmProviderId = customSettings['bgmProviderId'] ?? 'local';
        
        if (customSettings.containsKey('sortBy')) settings.sortBy = customSettings['sortBy'] ?? 'dateAdded';
        
        if (customSettings.containsKey('developerMode')) settings.developerMode = customSettings['developerMode'] ?? false;
        if (customSettings.containsKey('enableDebugLogs')) settings.enableDebugLogs = customSettings['enableDebugLogs'] ?? false;
        if (customSettings.containsKey('enableWebDavDebug')) settings.enableWebDavDebug = customSettings['enableWebDavDebug'] ?? false;
      }

      await db.saveSettings(settings);

      // 3. Khởi tạo WebDAV và test connection
      final webdav = WebDavService.getInstance();
      webdav.init(webDavUrl, webDavUsername, webDavPassword);
      final connected = await webdav.testConnection();

      if (mounted) {
        if (connected) {
          // 4. Trigger Pull dữ liệu để đồng bộ ngay lập tức
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.webdavConnectionSuccess ?? 'Kết nối WebDAV thành công! Đang đồng bộ thư viện...'),
              backgroundColor: Colors.green,
            ),
          );

          // Chạy pull ngầm để lấy sách và tiến trình về
          SyncService.getInstance().forcePull(progressOnly: false).then((syncResult) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(syncResult.success 
                      ? (AppLocalizations.of(context)?.librarySyncSuccess ?? 'Đồng bộ thư viện thành công!') 
                      : (AppLocalizations.of(context)?.librarySyncFailed(syncResult.message) ?? 'Đồng bộ thư viện thất bại: ${syncResult.message}')),
                  backgroundColor: syncResult.success ? Colors.green : Colors.orange,
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
              title: Text(AppLocalizations.of(context)?.webdavConnectionErrorTitle ?? 'Lỗi kết nối WebDAV'),
              content: Text(AppLocalizations.of(context)?.webdavConnectionErrorDesc(deviceName) ?? 'Cấu hình đã nhận từ "$deviceName", nhưng không thể kết nối tới máy chủ WebDAV. Vui lòng kiểm tra lại cấu hình trên máy chủ WebDAV.'),
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
            content: Text(AppLocalizations.of(context)?.applyConfigError(e.toString()) ?? 'Lỗi áp dụng cấu hình: $e'),
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
        title: Text(AppLocalizations.of(context)?.receiveConfigQr ?? 'Nhận cấu hình qua QR', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.receiverDevice ?? 'Thiết bị Nhận cấu hình',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)?.receiverDeviceDesc ?? 'Sử dụng thiết bị khác quét mã QR bên dưới để tự động truyền cấu hình đồng bộ sang máy này.',
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
                              Text(AppLocalizations.of(context)?.connectingTunnel ?? 'Đang kết nối SSH tunnel (localhost.run)...', style: const TextStyle(fontSize: 13)),
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
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)?.failedToInitTunnel ?? 'Không thể khởi tạo Tunnel. Vui lòng kiểm tra lại kết nối mạng hoặc thử lại sau.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _startTunnel,
                                child: Text(AppLocalizations.of(context)?.retry ?? 'Thử lại'),
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
                                )
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          Text(AppLocalizations.of(context)?.applyingConfig ?? 'Đang áp dụng cấu hình và đồng bộ...', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: Text(AppLocalizations.of(context)?.cancel ?? 'Hủy bỏ'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
