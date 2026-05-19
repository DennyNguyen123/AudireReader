// ignore_for_file: deprecated_member_use, avoid_print, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/database/database_helper.dart';
import '../../core/shortcut_helper.dart';
import '../../core/utils/path_helper.dart';
import '../../services/webdav_service.dart';
import '../../services/sync_service.dart' hide print;
import '../../services/tts_service.dart' hide print;
import '../../services/update_service.dart';
import '../../models/settings.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../models/progress.dart';
import '../../core/global_hotkey_manager.dart';
import '../../core/theme_notifier.dart';
import '../../services/logger_service.dart';
import 'developer_console_screen.dart';
import 'pronunciation_dictionary_screen.dart';
import 'package:path_provider/path_provider.dart';

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
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _speedController = TextEditingController();
  
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
  double _speechRate = 0.5;
  String _fontFamily = 'System';
  String _themeMode = 'System';
  List<dynamic> _voices = [];
  Map<String, String>? _selectedVoice;
  String _ttsProvider = 'system';
  String _selectedLanguageFilter = 'all';
  final _voiceSearchController = TextEditingController();
  String _voiceSearchQuery = '';

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
    _speedController.dispose();
    _voiceSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();

    setState(() {
      _webDavEnabled = settings.webDavEnabled;
      _openLastReadOnLaunch = settings.openLastReadOnLaunch;
      _autoCheckUpdate = settings.autoCheckUpdate;
      _urlController.text = settings.webDavUrl;
      _usernameController.text = settings.webDavUsername;
      _passwordController.text = settings.webDavPassword;
      _lastSync = settings.webDavLastSync;

      // Load cấu hình đọc sách
      _fontSize = settings.fontSize;
      _speechRate = settings.speechRate;
      _speedController.text = (_speechRate * 2).toStringAsFixed(3);
      _fontFamily = settings.fontFamily.trim().isEmpty ? 'System' : settings.fontFamily;
      _themeMode = settings.themeMode.trim().isEmpty ? 'System' : settings.themeMode;
      final provider = settings.ttsProvider;
      _ttsProvider = (provider == 'microsoft_edge') ? 'microsoft_edge' : 'system';

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

    await _loadVoices(settings);

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

  Future<void> _loadVoices(AppSettings settings) async {
    try {
      final ttsService = await TtsService.getInstance();
      final list = await ttsService.getVoicesForProvider(settings.ttsProvider);

      Map<String, String>? initialVoice;
      if (settings.selectedVoiceName != null && settings.selectedVoiceLocale != null) {
        dynamic matched;
        for (final v in list) {
          if (v['name']?.toString() == settings.selectedVoiceName &&
              v['locale']?.toString() == settings.selectedVoiceLocale) {
            matched = v;
            break;
          }
        }
        if (matched != null) {
          initialVoice = Map<String, String>.from(
            (matched as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
          );
        }
      } else if (settings.ttsProvider == 'microsoft_edge' && list.isNotEmpty) {
        // Tự động gán mặc định giọng HoaiMy cho Edge TTS
        dynamic matched;
        for (final v in list) {
          if (v['name']?.toString() == 'vi-VN-HoaiMyNeural') {
            matched = v;
            break;
          }
        }
        matched ??= list.first;
        initialVoice = Map<String, String>.from(
          (matched as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
        );
        ttsService.updateSettings(voice: initialVoice);
      }

      setState(() {
        _voices = list;
        _selectedVoice = initialVoice;
      });
    } catch (e) {
      print("Failed to load settings voices: $e");
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
    await db.saveSettings(settings);
    setState(() {
      _developerMode = val;
    });
  }

  Future<void> _saveEnableDebugLogs(bool val) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.enableDebugLogs = val;
    await db.saveSettings(settings);
    LoggerService().setEnableDebugLogs(val);
    setState(() {
      _enableDebugLogs = val;
    });
  }

  Future<void> _saveEnableWebDavDebug(bool val) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.enableWebDavDebug = val;
    await db.saveSettings(settings);
    LoggerService().setEnableWebDavDebug(val);
    setState(() {
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
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
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
          const SnackBar(
            content: Text('Cache cleared and sync data reset successfully.'),
            backgroundColor: Colors.amber,
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
    double? speechRate,
    Map<String, String>? voice,
    String? fontFamily,
    String? themeMode,
    String? ttsProvider,
  }) async {
    try {
      final ttsService = await TtsService.getInstance();
      await ttsService.updateSettings(
        fontSize: fontSize,
        speechRate: speechRate,
        voice: voice,
        fontFamily: fontFamily,
        themeMode: themeMode,
        ttsProvider: ttsProvider,
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
    settings.webDavPassword = _passwordController.text;
    await db.saveSettings(settings);
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
        const SnackBar(
          content: Text('All hotkeys reset to default values.'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

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
                  'Record Hotkey: $keyName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Press your keyboard combination. Avoid using system reserve keys.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
                          color: Colors.amber.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          recordedShortcut.isEmpty
                              ? 'Press keys...'
                              : ShortcutHelper.getDisplayLabel(recordedShortcut),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: recordedShortcut.isEmpty 
                                ? (isDark ? Colors.white30 : Colors.black26)
                                : Colors.amber[700],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isRecording)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Captured successfully!',
                            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber[700]),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Listening for keystroke...',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  if (!isRecording)
                    ElevatedButton(
                      onPressed: () {
                        onSave(recordedShortcut);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  ShortcutHelper.getDisplayLabel(currentShortcut),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.amber[700],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_urlController.text.isEmpty || 
        _usernameController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      setState(() {
        _testResult = 'Please fill in all credentials first.';
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
            ? 'Connection successful! WebDAV server is active.'
            : 'Connection failed. Please verify URL, username, and password.';
      });
    }
  }

  Future<void> _triggerManualSync() async {
    // Lưu cấu hình trước khi đồng bộ
    await _saveWebDavTextSettings();
    
    if (!mounted) return;
    if (!_webDavEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable WebDAV Sync first.'),
          backgroundColor: Colors.amber,
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
          title: Text(syncResult.success ? 'Sync Successful' : 'Sync Failed'),
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
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: _isLoading && _urlController.text.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber),
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
                        // Cấu hình chung
                        _buildGlassCard(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.settings_suggest_rounded, color: Colors.amber[700], size: 28),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'General Preferences',
                                    style: TextStyle(
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
                                title: const Text(
                                  'Auto-Open Last Read',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: const Text(
                                  'Automatically resume reading the most recently read book on launch.',
                                  style: TextStyle(fontSize: 11),
                                ),
                                value: _openLastReadOnLaunch,
                                activeColor: Colors.amber[700],
                                onChanged: (val) {
                                  setState(() {
                                    _openLastReadOnLaunch = val;
                                  });
                                  _saveGeneralPreference(val);
                                },
                              ),
                              const Divider(height: 1, thickness: 1),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Auto Check for Updates',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: const Text(
                                  'Automatically check for new versions from GitHub when the app starts.',
                                  style: TextStyle(fontSize: 11),
                                ),
                                value: _autoCheckUpdate,
                                activeColor: Colors.amber[700],
                                onChanged: (val) {
                                  setState(() {
                                    _autoCheckUpdate = val;
                                  });
                                  _saveAutoCheckUpdatePreference(val);
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isCheckingUpdate ? null : _manuallyCheckForUpdates,
                                      icon: _isCheckingUpdate
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                              ),
                                            )
                                          : const Icon(Icons.system_update_alt_rounded),
                                      label: const Text(
                                        'Check for Updates Now',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.amber[700],
                                        side: BorderSide(
                                          color: Colors.amber[700]!.withOpacity(0.5),
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
                        ),
                        const SizedBox(height: 20),

                        // Thẻ Cài đặt Hiển thị & Kiểu chữ (Reading Appearance & Typography Card)
                        _buildGlassCard(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.chrome_reader_mode_rounded, color: Colors.amber[700], size: 28),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Reading Appearance & Typography',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // CHỦ ĐỀ ĐỌC
                              const Text(
                                'Reading Theme',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: ['System', 'Light', 'Dark', 'Sepia'].map((theme) {
                                  final isSelected = _themeMode == theme;
                                  Color btnBg;
                                  Color textCol;
                                  IconData icon;
                                  
                                  if (theme == 'System') {
                                    btnBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
                                    textCol = isDark ? Colors.white70 : Colors.black87;
                                    icon = Icons.brightness_auto_rounded;
                                  } else if (theme == 'Light') {
                                    btnBg = Colors.white;
                                    textCol = Colors.black87;
                                    icon = Icons.wb_sunny_rounded;
                                  } else if (theme == 'Dark') {
                                    btnBg = const Color(0xFF121212);
                                    textCol = Colors.white70;
                                    icon = Icons.nightlight_round;
                                  } else { // Sepia
                                    btnBg = const Color(0xFFF4ECD8);
                                    textCol = const Color(0xFF5B4636);
                                    icon = Icons.menu_book_rounded;
                                  }
                                  
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _themeMode = theme;
                                        });
                                        _saveReadingPreference(themeMode: theme);
                                        ThemeNotifier.instance.updateTheme(theme);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: btnBg,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected 
                                                ? Colors.amber[700]! 
                                                : (isDark ? Colors.white10 : Colors.black12),
                                            width: isSelected ? 2.5 : 1,
                                          ),
                                          boxShadow: isSelected ? [
                                            BoxShadow(
                                              color: Colors.amber[700]!.withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ] : null,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              icon, 
                                              color: isSelected ? Colors.amber[700] : textCol.withOpacity(0.8), 
                                              size: 18
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              theme,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected ? Colors.amber[700] : textCol,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),

                              // CỠ CHỮ SLIDER
                              Row(
                                children: [
                                  const Icon(Icons.format_size_rounded, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Font Size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Expanded(
                                    child: Slider(
                                      value: _fontSize,
                                      min: 14.0,
                                      max: 28.0,
                                      divisions: 7,
                                      activeColor: Colors.amber[700],
                                      label: _fontSize.round().toString(),
                                      onChanged: (val) {
                                        setState(() {
                                          _fontSize = val;
                                        });
                                        _saveReadingPreference(fontSize: val);
                                      },
                                    ),
                                  ),
                                  Text(
                                    '${_fontSize.round()}px',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // CHỌN PHÔNG CHỮ DROPDOWN
                              const Text('Font Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: ['System', 'Serif', 'Sans-Serif', 'Monospace'].contains(_fontFamily) 
                                    ? _fontFamily 
                                    : 'System',
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
                                items: ['System', 'Serif', 'Sans-Serif', 'Monospace'].map((font) {
                                  return DropdownMenuItem<String>(
                                    value: font,
                                    child: Text(
                                      font,
                                      style: TextStyle(
                                        fontFamily: font == 'System' ? null : font.toLowerCase()
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _fontFamily = val;
                                    });
                                    _saveReadingPreference(fontFamily: val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Thẻ Cấu hình Giọng đọc (Text-to-Speech Configurations Card)
                        _buildGlassCard(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.volume_up_rounded, color: Colors.amber[700], size: 28),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Text-to-Speech Configurations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // TỐC ĐỘ ĐỌC TTS SLIDER
                              Row(
                                children: [
                                  const Icon(Icons.speed_rounded, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Reading Speed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Expanded(
                                    child: Slider(
                                      value: _speechRate,
                                      min: 0.05,
                                      max: 1.0,
                                      activeColor: Colors.amber[700],
                                      onChanged: (val) {
                                        setState(() {
                                          _speechRate = val;
                                          _speedController.text = (val * 2).toStringAsFixed(3);
                                        });
                                        _saveReadingPreference(speechRate: val);
                                      },
                                    ),
                                  ),
                                  // Hộp nhập số tốc độ chính xác 3 số lẻ thập phân
                                  SizedBox(
                                    width: 85,
                                    height: 38,
                                    child: TextField(
                                      controller: _speedController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                        suffixText: 'x',
                                        suffixStyle: TextStyle(
                                          fontSize: 11, 
                                          fontWeight: FontWeight.bold, 
                                          color: isDark ? Colors.amber[300] : Colors.amber[850]
                                        ),
                                        filled: true,
                                        fillColor: isDark ? Colors.white10 : Colors.black12,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (text) {
                                        final double? val = double.tryParse(text);
                                        if (val != null) {
                                          final clampedMultiplier = val.clamp(0.1, 2.0);
                                          final newRate = clampedMultiplier / 2.0;
                                          setState(() {
                                            _speechRate = newRate;
                                          });
                                          _saveReadingPreference(speechRate: newRate);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // CHỌN TTS PROVIDER DROPDOWN (Bằng tiếng Anh)
                              const Text('TTS Provider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _ttsProvider,
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
                                items: const [
                                  DropdownMenuItem<String>(
                                    value: 'system',
                                    child: Text('System TTS (Offline)', style: TextStyle(fontSize: 13)),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'microsoft_edge',
                                    child: Text('Microsoft Edge TTS (Online)', style: TextStyle(fontSize: 13)),
                                  ),
                                ],
                                onChanged: (val) async {
                                  if (val != null) {
                                    setState(() {
                                      _ttsProvider = val;
                                    });
                                    await _saveReadingPreference(ttsProvider: val);
                                    
                                    // Tải lại danh sách giọng đọc của provider mới
                                    final db = await DatabaseHelper.getInstance();
                                    final settings = await db.getSettings();
                                    await _loadVoices(settings);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),



                              // CHỌN GIỌNG ĐỌC & BỘ LỌC NGÔN NGỮ DROPDOWN
                              if (_voices.isNotEmpty) ...[
                                // BỘ LỌC NGÔN NGỮ
                                const Text('Language Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedLanguageFilter,
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
                                  items: const [
                                    DropdownMenuItem<String>(
                                      value: 'all',
                                      child: Text('All Languages', style: TextStyle(fontSize: 13)),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'vi',
                                      child: Text('Vietnamese', style: TextStyle(fontSize: 13)),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'en',
                                      child: Text('English', style: TextStyle(fontSize: 13)),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'others',
                                      child: Text('Others (Japanese, French...)', style: TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedLanguageFilter = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Ô TÌM KIẾM GIỌNG ĐỌC (Bằng tiếng Anh)
                                const Text('Search Voice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _voiceSearchController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark ? Colors.white10 : Colors.black12,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    hintText: 'Type to search voice name...',
                                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 13),
                                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.withOpacity(0.8)),
                                    suffixIcon: _voiceSearchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear_rounded, color: Colors.grey.withOpacity(0.8)),
                                            onPressed: () {
                                              _voiceSearchController.clear();
                                              setState(() {
                                                _voiceSearchQuery = '';
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _voiceSearchQuery = val.trim().toLowerCase();
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),

                                const Text('Select Voice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                () {
                                  final filteredDisplayVoices = _voices.where((v) {
                                    final lang = v['locale']?.toString().toLowerCase() ?? '';
                                    final name = v['name']?.toString().toLowerCase() ?? '';

                                    // 1. Lọc theo ngôn ngữ
                                    bool matchesLang = true;
                                    if (_selectedLanguageFilter == 'vi') {
                                      matchesLang = lang.startsWith('vi');
                                    } else if (_selectedLanguageFilter == 'en') {
                                      matchesLang = lang.startsWith('en');
                                    } else if (_selectedLanguageFilter == 'others') {
                                      matchesLang = !lang.startsWith('vi') && !lang.startsWith('en');
                                    }

                                    if (!matchesLang) return false;

                                    // 2. Lọc theo ô tìm kiếm
                                    if (_voiceSearchQuery.isNotEmpty) {
                                      return name.contains(_voiceSearchQuery) || lang.contains(_voiceSearchQuery);
                                    }

                                    return true;
                                  }).toList();

                                  return DropdownButtonFormField<String>(
                                    value: filteredDisplayVoices.any((v) => v['name']?.toString() == _selectedVoice?['name'])
                                        ? (_selectedVoice?['name'])
                                        : null,
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
                                    items: () {
                                      final Set<String> seenNames = {};
                                      final List<DropdownMenuItem<String>> menuItems = [];
                                      for (final v in filteredDisplayVoices) {
                                        final name = v['name']?.toString() ?? 'Unknown';
                                        final locale = v['locale']?.toString() ?? '';
                                        if (!seenNames.contains(name)) {
                                          seenNames.add(name);
                                          menuItems.add(DropdownMenuItem<String>(
                                            value: name,
                                            child: Text(
                                              '$name ($locale)',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ));
                                        }
                                      }
                                      return menuItems;
                                    }(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        dynamic selectedMap;
                                        for (final v in filteredDisplayVoices) {
                                          if (v['name']?.toString() == val) {
                                            selectedMap = v;
                                            break;
                                          }
                                        }
                                        if (selectedMap != null) {
                                          final voiceMap = Map<String, String>.from(
                                            (selectedMap as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
                                          );
                                          setState(() {
                                            _selectedVoice = voiceMap;
                                          });
                                          _saveReadingPreference(voice: voiceMap);
                                        }
                                      }
                                    },
                                  );
                                }(),
                              ],
                              const SizedBox(height: 16),
                              const Divider(height: 1, thickness: 1),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const PronunciationDictionaryScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.record_voice_over_rounded),
                                      label: const Text(
                                        'Manage Pronunciation Rules',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber[700],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // THẺ CẤU HÌNH PHÍM TẮT (Hotkey Configurations Card)
                        if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ...[
                          _buildGlassCard(
                            context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.keyboard_rounded, color: Colors.amber[700], size: 28),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Hotkey Configurations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Customize keyboard shortcuts for system commands and reading controls.',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              
                              _buildHotkeyItem('Next Paragraph', _hotkeyNextParagraph, (val) {
                                setState(() => _hotkeyNextParagraph = val);
                                _saveHotkeySetting('nextParagraph', val);
                              }),
                              _buildHotkeyItem('Previous Paragraph', _hotkeyPrevParagraph, (val) {
                                setState(() => _hotkeyPrevParagraph = val);
                                _saveHotkeySetting('prevParagraph', val);
                              }),
                              _buildHotkeyItem('Next Chapter', _hotkeyNextChapter, (val) {
                                setState(() => _hotkeyNextChapter = val);
                                _saveHotkeySetting('nextChapter', val);
                              }),
                              _buildHotkeyItem('Previous Chapter', _hotkeyPrevChapter, (val) {
                                setState(() => _hotkeyPrevChapter = val);
                                _saveHotkeySetting('prevChapter', val);
                              }),
                              _buildHotkeyItem('Play/Pause TTS', _hotkeyPlayPauseTts, (val) {
                                setState(() => _hotkeyPlayPauseTts = val);
                                _saveHotkeySetting('playPauseTts', val);
                              }),
                              _buildHotkeyItem('Open Chapter Shelf', _hotkeyOpenChapter, (val) {
                                setState(() => _hotkeyOpenChapter = val);
                                _saveHotkeySetting('openChapter', val);
                              }),
                              _buildHotkeyItem('Open Reader Setting', _hotkeyOpenSetting, (val) {
                                setState(() => _hotkeyOpenSetting = val);
                                _saveHotkeySetting('openSetting', val);
                              }),
                              _buildHotkeyItem('Boss Key', _hotkeyBossKey, (val) {
                                setState(() => _hotkeyBossKey = val);
                                _saveHotkeySetting('bossKey', val);
                              }),
                              
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Divider(height: 1, color: Colors.white10),
                              ),
                              
                              const Text(
                                'Boss Key Action',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: ['minimize', 'hide'].contains(_bossKeyAction) ? _bossKeyAction : 'minimize',
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
                                items: const [
                                  DropdownMenuItem(
                                    value: 'minimize',
                                    child: Text('Minimize Window'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'hide',
                                    child: Text('Hide Window (Completely invisible)'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _bossKeyAction = val;
                                    });
                                    _saveHotkeySetting('bossKeyAction', val);
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _resetHotkeysToDefault,
                                      icon: const Icon(Icons.restore_rounded),
                                      label: const Text('Reset to Default Hotkeys', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const SizedBox(height: 20),
                      ],

                      // ĐỒNG BỘ THƯ VIỆN ĐÁM MÂY (Gộp toàn bộ thành 1 Card duy nhất giống General Preferences)
                        _buildGlassCard(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Tiêu đề & Mô tả chính
                              Row(
                                children: [
                                  Icon(Icons.cloud_sync_rounded, color: Colors.amber[700], size: 28),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Cloud Library Sync',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
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
                                title: const Text(
                                  'Enable WebDAV Sync',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                subtitle: const Text(
                                  'Auto-sync when launching or leaving a book',
                                  style: TextStyle(fontSize: 12),
                                ),
                                value: _webDavEnabled,
                                activeColor: Colors.amber[700],
                                onChanged: (val) {
                                  setState(() {
                                    _webDavEnabled = val;
                                  });
                                  _saveWebDavEnableSetting(val);
                                },
                              ),

                              // Phần mở rộng cấu hình & trạng thái (chỉ hiện khi bật WebDAV)
                              if (_webDavEnabled) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Divider(height: 1, color: Colors.white10),
                                ),
                                
                                const Text(
                                  'WebDAV Server Configuration',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // URL Server WebDAV
                                TextFormField(
                                  controller: _urlController,
                                  onChanged: (val) => _saveWebDavTextSettings(),
                                  decoration: InputDecoration(
                                    labelText: 'WebDAV Server URL',
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
                                    if (_webDavEnabled && (val == null || val.trim().isEmpty)) {
                                      return 'Please enter WebDAV URL';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Username
                                TextFormField(
                                  controller: _usernameController,
                                  onChanged: (val) => _saveWebDavTextSettings(),
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                    filled: true,
                                    fillColor: isDark ? Colors.black26 : Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (_webDavEnabled && (val == null || val.trim().isEmpty)) {
                                      return 'Please enter Username';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  onChanged: (val) => _saveWebDavTextSettings(),
                                  decoration: InputDecoration(
                                    labelText: 'Password / App Password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    filled: true,
                                    fillColor: isDark ? Colors.black26 : Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (_webDavEnabled && (val == null || val.isEmpty)) {
                                      return 'Please enter Password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Nút Test Connection
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isTestingConnection ? null : _testConnection,
                                        icon: _isTestingConnection 
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Icon(Icons.network_ping_rounded),
                                        label: const Text('Test Connection', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                if (_testResult != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _testSuccess 
                                          ? Colors.green.withOpacity(0.15) 
                                          : Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _testSuccess ? Colors.green : Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _testSuccess 
                                              ? Icons.check_circle_outline_rounded 
                                              : Icons.error_outline_rounded,
                                          color: _testSuccess ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _testResult!,
                                            style: TextStyle(
                                              color: _testSuccess ? Colors.green[300] : Colors.red[300],
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
                                    const Text(
                                      'Sync Status',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      _lastSync != null 
                                          ? 'Last Synced: ${_lastSync!.toLocal().toString().split('.')[0]}'
                                          : 'Last Synced: Never',
                                      style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _triggerManualSync,
                                  icon: const Icon(Icons.sync_rounded),
                                  label: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildGlassCard(
                          context,
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Developer Mode',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Unlock advanced diagnostic tools, database inspector, and system logs.',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: _developerMode,
                            activeColor: Colors.amber[700],
                            onChanged: (val) {
                              _saveDeveloperModeSetting(val);
                            },
                          ),
                        ),
                        if (_developerMode) ...[
                          const SizedBox(height: 20),
                          _buildGlassCard(
                            context,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.developer_mode_rounded, color: Colors.amber[700], size: 28),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Developer Settings',
                                      style: TextStyle(
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
                                  title: const Text(
                                    'Enable Debug Logs',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: const Text(
                                    'Keep a history of application logs for troubleshooting.',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  value: _enableDebugLogs,
                                  activeColor: Colors.amber[700],
                                  onChanged: (val) {
                                    _saveEnableDebugLogs(val);
                                  },
                                ),
                                const Divider(height: 1, thickness: 1),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'WebDAV Debug Console',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: const Text(
                                    'Output raw WebDAV HTTP requests and responses to system log.',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  value: _enableWebDavDebug,
                                  activeColor: Colors.amber[700],
                                  onChanged: (val) {
                                    _saveEnableWebDavDebug(val);
                                  },
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const DeveloperConsoleScreen()),
                                          );
                                        },
                                        icon: const Icon(Icons.terminal_rounded),
                                        label: const Text('Open Debug Console', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                        onPressed: _showDatabaseInspector,
                                        icon: const Icon(Icons.storage_rounded),
                                        label: const Text('Database Inspector', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                        onPressed: _clearCacheAndResetSync,
                                        icon: const Icon(Icons.cleaning_services_rounded),
                                        label: const Text('Clear Cache & Reset Sync', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                        onPressed: _forceSyncNow,
                                        icon: const Icon(Icons.sync_problem_rounded),
                                        label: const Text('Force Sync Now', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const SizedBox(height: 20),
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
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Synchronizing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Processing books, cover arts, and reading progress...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
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

  Widget _buildGlassCard(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
