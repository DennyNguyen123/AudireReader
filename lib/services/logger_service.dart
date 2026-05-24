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

    // 1. Xác định xem log này có được phép ghi nhận hay không
    bool shouldLog = false;
    if (level == LogLevel.error || level == LogLevel.warning || error != null) {
      // Luôn ghi log lỗi hoặc cảnh báo để hỗ trợ chẩn đoán
      shouldLog = true;
    } else {
      // Chỉ ghi nhận log debug khi Developer Mode được bật (được đồng bộ qua cờ _enableDebugLogs)
      shouldLog = _enableDebugLogs;
    }

    if (!shouldLog) return;

    // 2. Quyết định in ra Console của terminal gỡ lỗi
    // Đối với môi trường debug (kDebugMode), luôn in ra console các log được phép ghi nhận
    bool shouldPrintToConsole = kDebugMode || _enableDebugLogs;
    if (shouldPrintToConsole) {
      final consoleMsg = '[$tag][${entry.levelName}] $message${error != null ? ' | Error: $error' : ''}';
      debugPrint(consoleMsg);
    }

    // 3. Thêm vào danh sách log trong RAM của ứng dụng
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
