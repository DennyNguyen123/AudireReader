import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error, tts, sync, webdav }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? error;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
  });

  String get levelName => level.name.toUpperCase();
}

class LoggerService extends ChangeNotifier {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final List<LogEntry> _logs = [];
  bool _enableDebugLogs = false;
  bool _enableWebDavDebug = false;

  bool get enableDebugLogs => _enableDebugLogs;
  bool get enableWebDavDebug => _enableWebDavDebug;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void init({required bool enableDebugLogs, required bool enableWebDavDebug}) {
    _enableDebugLogs = enableDebugLogs;
    _enableWebDavDebug = enableWebDavDebug;
  }

  void setEnableDebugLogs(bool val) {
    _enableDebugLogs = val;
    notifyListeners();
  }

  void setEnableWebDavDebug(bool val) {
    _enableWebDavDebug = val;
    notifyListeners();
  }

  void log(String message, {LogLevel level = LogLevel.info, String tag = 'APP', String? error}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
    );

    bool shouldPrintToConsole = kDebugMode || _enableDebugLogs;
    
    // Các tag nội bộ chỉ in ra Console khi người dùng bật enableDebugLogs trong Developer Settings
    // kDebugMode (môi trường flutter run) không tự động in các log này ra nữa
    const suppressedTags = {'WEBDAV', 'SYNC', 'TTS'};
    if (suppressedTags.contains(tag) && !_enableDebugLogs) {
      // Ngoại lệ: WEBDAV chỉ in khi bật riêng cờ _enableWebDavDebug
      if (tag == 'WEBDAV' && _enableWebDavDebug) {
        shouldPrintToConsole = true;
      } else {
        shouldPrintToConsole = false;
      }
    }

    if (shouldPrintToConsole) {
      final consoleMsg = '[$tag][${entry.levelName}] $message${error != null ? ' | Error: $error' : ''}';
      debugPrint(consoleMsg);
    }

    _logs.add(entry);

    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }

    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }
}
