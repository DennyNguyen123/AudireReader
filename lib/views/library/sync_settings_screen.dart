// ignore_for_file: deprecated_member_use, avoid_print, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/path_helper.dart';
import '../../services/webdav_service.dart';
import '../../services/sync_service.dart' hide print;
import '../../services/tts_service.dart' hide print;
import '../../services/update_service.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../models/progress.dart';
import '../../core/global_hotkey_manager.dart';
import '../../core/theme_notifier.dart';
import '../../core/locale_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../services/logger_service.dart';
import 'developer_console_screen.dart';
import 'widgets/settings/general_settings_section.dart';
import 'widgets/settings/appearance_settings_section.dart';
import 'widgets/settings/hotkeys_settings_section.dart';
import 'widgets/settings/webdav_settings_section.dart';
import 'widgets/settings/developer_settings_section.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _webDavEnabled = false;
  bool _openLastReadOnLaunch = false;
  bool _autoCheckUpdate = true;
  String _appLocaleCode = 'en';
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  DateTime? _lastSync;
  bool _isLoading = false;
  bool _isTestingConnection = false;
  bool _isCheckingUpdate = false;
  String? _testResult;
  bool _testSuccess = false;

  bool _developerMode = false;
  bool _enableDebugLogs = false;
  bool _enableWebDavDebug = false;

  double _fontSize = 18.0;
  String _fontFamily = 'System';
  String _themeMode = 'System';
  String? _primaryColorHex;
  String _appVersion = '';

  // Hotkeys & Boss Key States
  String _hotkeyNextParagraph = 'Arrow Down';
  String _hotkeyPrevParagraph = 'Arrow Up';
  String _hotkeyNextChapter = 'Control+Arrow Right';
  String _hotkeyPrevChapter = 'Control+Arrow Left';
  String _hotkeyPlayPauseTts = 'Space';
  String _hotkeyOpenChapter = 'Control+o';
  String _hotkeyOpenSetting = 'Control+comma';
  String _hotkeyBossKey = 'Control+b';
  String _bossKeyAction = 'minimize';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    const storage = FlutterSecureStorage();
    final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

    setState(() {
      _webDavEnabled = settings.webDavEnabled;
      _openLastReadOnLaunch = settings.openLastReadOnLaunch;
      _autoCheckUpdate = settings.autoCheckUpdate;
      _appLocaleCode = (settings.appLocale == 'vi' || settings.appLocale == 'en') ? settings.appLocale : 'en';
      _urlController.text = settings.webDavUrl;
      _usernameController.text = settings.webDavUsername;
      _passwordController.text = webDavPassword;
      _lastSync = settings.webDavLastSync;

      // Load cấu hình đọc sách
      _fontSize = settings.fontSize;
      _fontFamily = settings.fontFamily.trim().isEmpty ? 'System' : settings.fontFamily;
      _themeMode = settings.themeMode.trim().isEmpty ? 'System' : settings.themeMode;
      _primaryColorHex = settings.primaryColorHex;

      // Load Hotkeys & Boss Key Configurations
      _hotkeyNextParagraph = settings.hotkeyNextParagraph;
      _hotkeyPrevParagraph = settings.hotkeyPrevParagraph;
      _hotkeyNextChapter = settings.hotkeyNextChapter;
      _hotkeyPrevChapter = settings.hotkeyPrevChapter;
      _hotkeyPlayPauseTts = settings.hotkeyPlayPauseTts;
      _hotkeyOpenChapter = settings.hotkeyOpenChapter;
      _hotkeyOpenSetting = settings.hotkeyOpenSetting;
      _hotkeyBossKey = settings.hotkeyBossKey;
      _bossKeyAction = settings.bossKeyAction;

      _developerMode = settings.developerMode;
      _enableDebugLogs = settings.enableDebugLogs;
      _enableWebDavDebug = settings.enableWebDavDebug;
      LoggerService().init(
        enableDebugLogs: _enableDebugLogs,
        enableWebDavDebug: _enableWebDavDebug,
      );
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _manuallyCheckForUpdates() async {
    if (_isCheckingUpdate) return;
    setState(() {
      _isCheckingUpdate = true;
    });
    try {
      await UpdateService.checkForUpdate(context, showNoUpdateMessage: true);
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }


  Future<void> _saveGeneralPreference(bool val) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.openLastReadOnLaunch = val;
    await db.saveSettings(settings);
  }

  Future<void> _saveAutoCheckUpdatePreference(bool val) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.autoCheckUpdate = val;
    await db.saveSettings(settings);
  }

  Future<void> _saveDeveloperModeSetting(bool val) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.developerMode = val;
    settings.enableDebugLogs = val;
    settings.enableWebDavDebug = val;
    await db.saveSettings(settings);
    LoggerService().setEnableDebugLogs(val);
    LoggerService().setEnableWebDavDebug(val);
    setState(() {
      _developerMode = val;
      _enableDebugLogs = val;
      _enableWebDavDebug = val;
    });
  }

  Future<void> _showDatabaseInspector() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final docDir = await PathHelper.getAppDirectory();
      final db = await DatabaseHelper.getInstance();
      final booksCount = await db.isar.books.count();
      final chaptersCount = await db.isar.chapters.count();
      final progressCount = await db.isar.readingProgress.count();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Database Inspector', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Database Type: Isar NoSQL', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Storage Path:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  SelectableText(docDir.path, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Books Count:'),
                      Text('$booksCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chapters Count:'),
                      Text('$chaptersCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress Records:'),
                      Text('$progressCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to inspect database: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCacheAndResetSync() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final tempDir = await getTemporaryDirectory();
      final appCacheDir = await PathHelper.getAppCacheDirectory();
      int deletedCount = 0;
      if (await tempDir.exists()) {
        final list = tempDir.listSync();
        for (final file in list) {
          try {
            await file.delete(recursive: true);
            deletedCount++;
          } catch (_) {}
        }
      }
      if (await appCacheDir.exists()) {
        final list = appCacheDir.listSync();
        for (final file in list) {
          try {
            await file.delete(recursive: true);
            deletedCount++;
          } catch (_) {}
        }
      }

      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();
      settings.webDavLastSync = null;
      await db.saveSettings(settings);

      setState(() {
        _lastSync = null;
      });

      LoggerService().log('Cleared $deletedCount temporary files & reset WebDAV sync status', tag: 'SYNC', level: LogLevel.warning);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cache cleared and sync data reset successfully.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      LoggerService().log('Failed to clear cache & reset sync', tag: 'SYNC', level: LogLevel.error, error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceSyncNow() async {
    LoggerService().log('Force sync triggered by developer', tag: 'SYNC', level: LogLevel.warning);
    await _triggerManualSync();
  }

  Future<void> _saveReadingPreference({
    double? fontSize,
    String? fontFamily,
    String? themeMode,
    String? primaryColorHex,
  }) async {
    try {
      final ttsService = await TtsService.getInstance();
      await ttsService.updateSettings(
        fontSize: fontSize,
        fontFamily: fontFamily,
        themeMode: themeMode,
        primaryColorHex: primaryColorHex,
      );
    } catch (e) {
      print("Failed to auto-save reading settings: $e");
    }
  }

  Future<void> _saveWebDavEnableSetting(bool val) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.webDavEnabled = val;
    await db.saveSettings(settings);
  }

  Future<void> _saveWebDavTextSettings() async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.webDavUrl = _urlController.text.trim();
    settings.webDavUsername = _usernameController.text.trim();
    await db.saveSettings(settings);

    const storage = FlutterSecureStorage();
    await storage.write(key: 'webdav_password', value: _passwordController.text);
  }

  // --- Hotkeys Settings Operations ---
  Future<void> _saveHotkeySetting(String key, String value) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    
    switch (key) {
      case 'nextParagraph':
        settings.hotkeyNextParagraph = value;
        break;
      case 'prevParagraph':
        settings.hotkeyPrevParagraph = value;
        break;
      case 'nextChapter':
        settings.hotkeyNextChapter = value;
        break;
      case 'prevChapter':
        settings.hotkeyPrevChapter = value;
        break;
      case 'playPauseTts':
        settings.hotkeyPlayPauseTts = value;
        break;
      case 'openChapter':
        settings.hotkeyOpenChapter = value;
        break;
      case 'openSetting':
        settings.hotkeyOpenSetting = value;
        break;
      case 'bossKey':
        settings.hotkeyBossKey = value;
        break;
      case 'bossKeyAction':
        settings.bossKeyAction = value;
        break;
    }
    
    await db.saveSettings(settings);
    
    try {
      final ttsService = await TtsService.getInstance();
      ttsService.notifyListeners();
    } catch (_) {}

    // Cập nhật lại Boss Key toàn cục (nếu có thay đổi)
    await GlobalHotkeyManager.updateBossKey();
  }

  Future<void> _resetHotkeysToDefault() async {
    setState(() {
      _hotkeyNextParagraph = 'Arrow Down';
      _hotkeyPrevParagraph = 'Arrow Up';
      _hotkeyNextChapter = 'Control+Arrow Right';
      _hotkeyPrevChapter = 'Control+Arrow Left';
      _hotkeyPlayPauseTts = 'Space';
      _hotkeyOpenChapter = 'Control+o';
      _hotkeyOpenSetting = 'Control+comma';
      _hotkeyBossKey = 'Control+b';
      _bossKeyAction = 'minimize';
    });

    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    
    settings.hotkeyNextParagraph = 'Arrow Down';
    settings.hotkeyPrevParagraph = 'Arrow Up';
    settings.hotkeyNextChapter = 'Control+Arrow Right';
    settings.hotkeyPrevChapter = 'Control+Arrow Left';
    settings.hotkeyPlayPauseTts = 'Space';
    settings.hotkeyOpenChapter = 'Control+o';
    settings.hotkeyOpenSetting = 'Control+comma';
    settings.hotkeyBossKey = 'Control+b';
    settings.bossKeyAction = 'minimize';
    
    await db.saveSettings(settings);
    
    try {
      final ttsService = await TtsService.getInstance();
      ttsService.notifyListeners();
    } catch (_) {}

    // Cập nhật lại Boss Key toàn cục
    await GlobalHotkeyManager.updateBossKey();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.resetHotkeysSuccess ?? 'All hotkeys reset to default values.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }



  Future<void> _testConnection() async {
    if (_urlController.text.isEmpty || 
        _usernameController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      setState(() {
        _testResult = AppLocalizations.of(context)?.fillCredentialsHint ?? 'Please fill in all credentials first.';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _testResult = null;
    });

    // Tạo WebDAV client tạm thời để kiểm thử
    final tempService = WebDavService.getInstance();
    tempService.init(
      _urlController.text.trim(),
      _usernameController.text.trim(),
      _passwordController.text,
    );

    final success = await tempService.testConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _testSuccess = success;
        _testResult = success 
            ? (AppLocalizations.of(context)?.connectionSuccessDesc ?? 'Connection successful! WebDAV server is active.')
            : (AppLocalizations.of(context)?.connectionFailedDesc ?? 'Connection failed. Please verify URL, username, and password.');
      });
    }
  }

  Future<void> _triggerManualSync() async {
    // Lưu cấu hình trước khi đồng bộ
    await _saveWebDavTextSettings();
    
    if (!mounted) return;
    if (!_webDavEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.enableWebdavFirst ?? 'Please enable WebDAV Sync first.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final syncResult = await SyncService.getInstance().sync();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      // Reload last sync time
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();
      if (!mounted) return;
      setState(() {
        _lastSync = settings.webDavLastSync;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(syncResult.success 
              ? (AppLocalizations.of(context)?.syncSuccessful ?? 'Sync Successful') 
              : (AppLocalizations.of(context)?.syncFailed(syncResult.message) ?? 'Sync Failed')),
          content: Text(syncResult.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.settings ?? 'Settings',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: _isLoading && _urlController.text.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GeneralSettingsSection(
                          openLastReadOnLaunch: _openLastReadOnLaunch,
                          autoCheckUpdate: _autoCheckUpdate,
                          appLocaleCode: _appLocaleCode,
                          isCheckingUpdate: _isCheckingUpdate,
                          onOpenLastReadChanged: (val) {
                            setState(() {
                              _openLastReadOnLaunch = val;
                            });
                            _saveGeneralPreference(val);
                          },
                          onAutoCheckUpdateChanged: (val) {
                            setState(() {
                              _autoCheckUpdate = val;
                            });
                            _saveAutoCheckUpdatePreference(val);
                          },
                          onLocaleChanged: (val) async {
                            if (val != null) {
                              setState(() {
                                _appLocaleCode = val;
                              });
                              final db = await DatabaseHelper.getInstance();
                              final settings = await db.getSettings();
                              settings.appLocale = val;
                              await db.saveSettings(settings);
                              LocaleNotifier.instance.updateLocale(val);
                            }
                          },
                          onCheckUpdates: _manuallyCheckForUpdates,
                        ),
                        const SizedBox(height: 20),
                        AppearanceSettingsSection(
                          themeMode: _themeMode,
                          primaryColorHex: _primaryColorHex,
                          fontSize: _fontSize,
                          fontFamily: _fontFamily,
                          onThemeModeChanged: (tMode) {
                            setState(() {
                              _themeMode = tMode;
                            });
                            _saveReadingPreference(themeMode: tMode);
                            ThemeNotifier.instance.updateTheme(tMode, primaryColorHex: _primaryColorHex);
                          },
                          onPrimaryColorChanged: (hexStr) {
                            setState(() {
                              _primaryColorHex = hexStr;
                            });
                            _saveReadingPreference(primaryColorHex: hexStr);
                            ThemeNotifier.instance.updateTheme(_themeMode, primaryColorHex: hexStr);
                          },
                          onFontSizeChanged: (val) {
                            setState(() {
                              _fontSize = val;
                            });
                            _saveReadingPreference(fontSize: val);
                          },
                          onFontFamilyChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _fontFamily = val;
                              });
                              _saveReadingPreference(fontFamily: val);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ...[
                          HotkeysSettingsSection(
                            hotkeyNextParagraph: _hotkeyNextParagraph,
                            hotkeyPrevParagraph: _hotkeyPrevParagraph,
                            hotkeyNextChapter: _hotkeyNextChapter,
                            hotkeyPrevChapter: _hotkeyPrevChapter,
                            hotkeyPlayPauseTts: _hotkeyPlayPauseTts,
                            hotkeyOpenChapter: _hotkeyOpenChapter,
                            hotkeyOpenSetting: _hotkeyOpenSetting,
                            hotkeyBossKey: _hotkeyBossKey,
                            bossKeyAction: _bossKeyAction,
                            onHotkeyRecordAndSave: (key, val) {
                              setState(() {
                                switch (key) {
                                  case 'nextParagraph':
                                    _hotkeyNextParagraph = val;
                                    break;
                                  case 'prevParagraph':
                                    _hotkeyPrevParagraph = val;
                                    break;
                                  case 'nextChapter':
                                    _hotkeyNextChapter = val;
                                    break;
                                  case 'prevChapter':
                                    _hotkeyPrevChapter = val;
                                    break;
                                  case 'playPauseTts':
                                    _hotkeyPlayPauseTts = val;
                                    break;
                                  case 'openChapter':
                                    _hotkeyOpenChapter = val;
                                    break;
                                  case 'openSetting':
                                    _hotkeyOpenSetting = val;
                                    break;
                                  case 'bossKey':
                                    _hotkeyBossKey = val;
                                    break;
                                }
                              });
                              _saveHotkeySetting(key, val);
                            },
                            onBossKeyActionChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _bossKeyAction = val;
                                });
                                _saveHotkeySetting('bossKeyAction', val);
                              }
                            },
                            onResetHotkeys: _resetHotkeysToDefault,
                          ),
                          const SizedBox(height: 20),
                        ],
                        WebdavSettingsSection(
                          webDavEnabled: _webDavEnabled,
                          urlController: _urlController,
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          isTestingConnection: _isTestingConnection,
                          testResult: _testResult,
                          testSuccess: _testSuccess,
                          lastSync: _lastSync,
                          isLoading: _isLoading,
                          onWebDavEnabledChanged: (val) {
                            setState(() {
                              _webDavEnabled = val;
                            });
                            _saveWebDavEnableSetting(val);
                          },
                          onTestConnection: _testConnection,
                          onSyncNow: _triggerManualSync,
                          onSettingsChanged: _saveWebDavTextSettings,
                        ),
                        const SizedBox(height: 20),
                        DeveloperSettingsSection(
                          developerMode: _developerMode,
                          onDeveloperModeChanged: _saveDeveloperModeSetting,
                          onOpenDebugConsole: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DeveloperConsoleScreen()),
                            );
                          },
                          onShowDatabaseInspector: _showDatabaseInspector,
                          onClearCacheAndResetSync: _clearCacheAndResetSync,
                          onForceSyncNow: _forceSyncNow,
                        ),
                        const SizedBox(height: 20),
                        if (_appVersion.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)?.version(_appVersion) ?? 'Version $_appVersion',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Màn hình loading đồng bộ toàn bộ mây
                if (_isLoading)
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: Colors.black45,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                AppLocalizations.of(context)?.synchronizing ?? 'Synchronizing...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)?.processingSync ?? 'Processing books, cover arts, and reading progress...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

}
