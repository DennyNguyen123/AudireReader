import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/tunnel_service.dart';
import '../../services/sync_service.dart';
import '../../core/database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:audire_reader/src/rust/api/sync.dart' as rust_sync;
import '../../services/logger_service.dart';

class TvSyncScreen extends StatefulWidget {
  const TvSyncScreen({super.key});

  @override
  State<TvSyncScreen> createState() => _TvSyncScreenState();
}

class _TvSyncScreenState extends State<TvSyncScreen> {
  final TunnelService _tunnelService = TunnelService();
  ServerInfo? _serverInfo;
  String? _selectedConfigUrl;
  bool _isStarting = true;
  bool _isApplyingConfig = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  @override
  void dispose() {
    _tunnelService.stopTunnel();
    super.dispose();
  }

  Future<void> _startServer() async {
    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    _tunnelService.onConfigReceived = _onConfigReceived;

    try {
      final info = await _tunnelService.startTunnel();
      if (mounted) {
        setState(() {
          _serverInfo = info;
          // Ưu tiên Public HTTPS URL để hỗ trợ mọi mạng (4G / khác Wi-Fi)
          _selectedConfigUrl = info.publicConfigUrl;
          _isStarting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _errorMessage = e.toString();
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

      if (webDavPassword.isNotEmpty) {
        await rust_sync.saveWebdavPassword(password: webDavPassword);
      }

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
          fontWeight: customSettings.containsKey('fontWeight') ? customSettings['fontWeight'] : settings.fontWeight,
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

      await rust_sync.saveWebdavConfig(
        url: webDavUrl,
        username: webDavUsername,
        password: webDavPassword,
      );
      final connected = await rust_sync.testWebdavConnection(
        url: webDavUrl,
        username: webDavUsername,
        password: webDavPassword,
      );

      if (mounted) {
        if (connected) {
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
                AppLocalizations.of(context)?.webdavConnectionErrorDesc(deviceName) ??
                    'Đã lưu cấu hình nhưng kiểm tra kết nối tới máy chủ WebDAV thất bại. Vui lòng kiểm tra lại URL và tài khoản trên máy nguồn.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
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
      LoggerService().log('Lỗi áp dụng cấu hình QR: $e', tag: 'SYNC', level: LogLevel.error);
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

  String get _qrConfigUrl {
    return _selectedConfigUrl ?? 'http://127.0.0.1:8080/config';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.primary;

    final isPublicInternet = _selectedConfigUrl != null &&
        (_selectedConfigUrl!.startsWith('https://') ||
            _selectedConfigUrl!.contains('.pinggy.') ||
            _selectedConfigUrl!.contains('.lhr.'));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.receiveConfigQr ?? 'Nhận cấu hình qua QR',
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32.0,
                  horizontal: 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Icon & Title
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.qr_code_2_rounded, size: 36, color: accentColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.receiverDevice ?? 'Thiết bị Nhận cấu hình',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPublicInternet
                          ? 'Hỗ trợ quét qua mọi mạng (4G, 5G hoặc khác Wi-Fi) bằng Cloud Tunnel.'
                          : 'Đang dùng mạng nội bộ (yêu cầu cả 2 thiết bị kết nối cùng Wi-Fi).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Trạng thái / QR Code
                    if (_isStarting)
                      const SizedBox(
                        height: 240,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Đang khởi tạo Cloud Tunnel & Server...'),
                            ],
                          ),
                        ),
                      )
                    else if (_errorMessage != null)
                      SizedBox(
                        height: 240,
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
                                'Lỗi khởi động: $_errorMessage',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _startServer,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(
                                  AppLocalizations.of(context)?.retry ?? 'Thử lại',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Khung QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrConfigUrl,
                          version: QrVersions.auto,
                          size: 210.0,
                          gapless: false,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Địa chỉ endpoint
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPublicInternet ? Icons.public_rounded : Icons.wifi_rounded,
                              size: 16,
                              color: accentColor,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: SelectableText(
                                _qrConfigUrl,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _qrConfigUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã sao chép liên kết vào bộ nhớ tạm'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Icon(Icons.copy_rounded, size: 16, color: accentColor),
                            ),
                          ],
                        ),
                      ),

                      // Tùy chọn chuyển đổi Mạng (Internet 4G vs Wi-Fi LAN)
                      if (_serverInfo != null) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            // Nút chọn Public Internet
                            ChoiceChip(
                              avatar: const Icon(Icons.public_rounded, size: 16),
                              label: const Text('Internet (4G/Mọi mạng)', style: TextStyle(fontSize: 12)),
                              selected: isPublicInternet,
                              selectedColor: accentColor,
                              labelStyle: TextStyle(
                                color: isPublicInternet ? Colors.white : null,
                                fontWeight: isPublicInternet ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedConfigUrl = _serverInfo!.publicConfigUrl;
                                  });
                                }
                              },
                            ),
                            // Nút chọn Wi-Fi Local LAN
                            if (_serverInfo!.localIps.isNotEmpty)
                              ChoiceChip(
                                avatar: const Icon(Icons.wifi_rounded, size: 16),
                                label: const Text('Wi-Fi Nội bộ (LAN)', style: TextStyle(fontSize: 12)),
                                selected: !isPublicInternet,
                                selectedColor: accentColor,
                                labelStyle: TextStyle(
                                  color: !isPublicInternet ? Colors.white : null,
                                  fontWeight: !isPublicInternet ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _selectedConfigUrl = _serverInfo!.primaryLanUrl;
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),
                    if (_isApplyingConfig)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
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
                        icon: const Icon(Icons.close_rounded),
                        label: Text(
                          AppLocalizations.of(context)?.cancel ?? 'Hủy bỏ / Đóng',
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
