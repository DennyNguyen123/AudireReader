import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:audire_reader/src/rust/api/supertonic.dart' as rust_supertonic;
import 'logger_service.dart';

class SupertonicService extends ChangeNotifier {
  static SupertonicService? _instance;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  bool _isInitialized = false;
  bool _isLoadingModel = false;
  String _currentVoiceStyleName = '';

  // Trạng thái các biến getter
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get downloadStatus => _downloadStatus;
  bool get isInitialized => _isInitialized;
  bool get isLoadingModel => _isLoadingModel;
  String get currentVoiceStyleName => _currentVoiceStyleName;

  /// Tự động phát hiện ngôn ngữ của văn bản
  Future<String> detectLanguage(String text) async {
    return await rust_supertonic.detectLanguage(text: text);
  }

  SupertonicService._();

  static SupertonicService getInstance() {
    _instance ??= SupertonicService._();
    return _instance!;
  }

  Future<String> _getBaseDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    return appDir.path;
  }

  /// Kiểm tra xem toàn bộ các tệp tin model đã được tải đầy đủ chưa
  Future<bool> checkModelExists() async {
    try {
      final baseDir = await _getBaseDirectory();
      return rust_supertonic.checkSupertonicModelExists(baseDir: baseDir);
    } catch (e) {
      LoggerService().log(
        "Error checking model files: $e",
        tag: 'SUPERTONIC',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Bắt đầu tải xuống toàn bộ tệp tin mô hình từ Hugging Face qua Rust
  Future<bool> downloadModelFiles() async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _downloadStatus = 'Connecting to Hugging Face...';
    notifyListeners();

    try {
      final baseDir = await _getBaseDirectory();
      await rust_supertonic.downloadSupertonicModels(baseDir: baseDir);

      _isDownloading = false;
      _downloadProgress = 1.0;
      _downloadStatus = 'All files downloaded successfully!';
      notifyListeners();
      LoggerService().log(
        "Successfully downloaded all Supertonic assets via Rust.",
        tag: 'SUPERTONIC',
      );
      return true;
    } catch (e) {
      _isDownloading = false;
      _downloadStatus = 'Error downloading: $e';
      notifyListeners();
      LoggerService().log(
        "Fatal error downloading model files: $e",
        tag: 'SUPERTONIC',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Khởi tạo và nạp Engine Supertonic từ ổ cứng cục bộ vào bộ nhớ
  Future<bool> initializeEngine({String voiceStyle = 'M1'}) async {
    if (_isInitialized && _currentVoiceStyleName == voiceStyle) return true;
    if (_isLoadingModel) return false;

    _isLoadingModel = true;
    notifyListeners();

    try {
      final baseDir = await _getBaseDirectory();
      final success = await rust_supertonic.initSupertonicEngine(
        baseDir: baseDir,
        voiceStyle: voiceStyle,
      );

      _isInitialized = success;
      _isLoadingModel = false;
      if (success) {
        _currentVoiceStyleName = voiceStyle;
        LoggerService().log(
          "Supertonic 3 Engine loaded successfully offline with style $voiceStyle via Rust!",
          tag: 'SUPERTONIC',
        );
      }
      notifyListeners();
      return success;
    } catch (e) {
      _isLoadingModel = false;
      _isInitialized = false;
      _currentVoiceStyleName = '';
      notifyListeners();
      LoggerService().log(
        "Error loading offline models: $e",
        tag: 'SUPERTONIC',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Đọc văn bản offline và sinh ra tệp WAV tạm thời
  Future<String?> synthesizeToWav(
    String text, {
    double speed = 1.05,
    String lang = 'vi',
  }) async {
    try {
      if (!_isInitialized) {
        LoggerService().log(
          "Engine is not initialized yet.",
          tag: 'SUPERTONIC',
          level: LogLevel.error,
        );
        return null;
      }

      final cleanText = text.trim();
      if (cleanText.isEmpty) return null;

      final wavBytes = await rust_supertonic.synthesizeSupertonic(
        text: cleanText,
        lang: lang,
        speed: speed,
        denoiseSteps: 16,
      );

      if (wavBytes.isEmpty) return null;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = p.join(tempDir.path, 'supertonic_$timestamp.wav');

      final file = File(outputPath);
      await file.writeAsBytes(wavBytes, flush: true);

      return file.path;
    } catch (e) {
      LoggerService().log(
        "Fatal error in offline synthesis via Rust: $e",
        tag: 'SUPERTONIC',
        level: LogLevel.error,
      );
      return null;
    }
  }

  /// Giải phóng bộ nhớ RAM
  Future<void> releaseEngine() async {
    if (!_isInitialized) return;

    try {
      await rust_supertonic.releaseSupertonicEngine();
      _currentVoiceStyleName = '';
      _isInitialized = false;
      notifyListeners();
      LoggerService().log(
        "Supertonic 3 Engine released successfully.",
        tag: 'SUPERTONIC',
      );
    } catch (e) {
      LoggerService().log(
        "Error releasing engine: $e",
        tag: 'SUPERTONIC',
        level: LogLevel.error,
      );
    }
  }

  /// Xóa các tệp mô hình offline
  Future<void> deleteModelFiles() async {
    await releaseEngine();
    try {
      final baseDir = await _getBaseDirectory();
      await rust_supertonic.deleteSupertonicModels(baseDir: baseDir);
      notifyListeners();
    } catch (e) {
      LoggerService().log(
        "Error deleting model files: $e",
        tag: 'SUPERTONIC',
        level: LogLevel.error,
      );
    }
  }
}
