import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sdk/helper.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'logger_service.dart';

class SupertonicService extends ChangeNotifier {
  static SupertonicService? _instance;
  
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  bool _isInitialized = false;
  bool _isLoadingModel = false;

  TextToSpeech? _textToSpeech;
  Style? _activeStyle;
  String _currentVoiceStyleName = ''; // 'M1' hoặc 'F1'

  // Trạng thái các biến getter
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get downloadStatus => _downloadStatus;
  bool get isInitialized => _isInitialized;
  bool get isLoadingModel => _isLoadingModel;
  String get currentVoiceStyleName => _currentVoiceStyleName;

  SupertonicService._();

  static SupertonicService getInstance() {
    _instance ??= SupertonicService._();
    return _instance!;
  }

  /// Trích xuất thư mục lưu trữ asset của Supertonic cục bộ
  Future<Directory> _getAssetsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final assetsDir = Directory(p.join(appDir.path, 'supertonic_assets'));
    if (!assetsDir.existsSync()) {
      assetsDir.createSync(recursive: true);
    }
    return assetsDir;
  }

  /// Kiểm tra xem toàn bộ các tệp tin model đã được tải đầy đủ cục bộ chưa
  Future<bool> checkModelExists() async {
    try {
      final dir = await _getAssetsDirectory();
      final requiredFiles = [
        'duration_predictor.onnx',
        'text_encoder.onnx',
        'vector_estimator.onnx',
        'vocoder.onnx',
        'tts.json',
        'unicode_indexer.json',
        'M1.json',
        'F1.json',
      ];

      for (final filename in requiredFiles) {
        final file = File(p.join(dir.path, filename));
        if (!file.existsSync() || file.lengthSync() == 0) {
          return false;
        }
      }
      return true;
    } catch (e) {
      LoggerService().log("Error checking model files: $e", tag: 'SUPERTONIC', level: LogLevel.error);
      return false;
    }
  }

  /// Bắt đầu tải xuống toàn bộ tệp tin mô hình từ Hugging Face thủ công
  Future<bool> downloadModelFiles() async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _downloadStatus = 'Connecting to Hugging Face...';
    notifyListeners();

    final dir = await _getAssetsDirectory();
    final client = http.Client();

    // Định nghĩa danh sách các tệp tin và link tải tương ứng từ CDN Hugging Face của Supertonic-3
    final baseUrl = 'https://huggingface.co/Supertone/supertonic-3/resolve/main';
    final filesToDownload = {
      'tts.json': '$baseUrl/onnx/tts.json',
      'unicode_indexer.json': '$baseUrl/onnx/unicode_indexer.json',
      'M1.json': '$baseUrl/voice_styles/M1.json',
      'F1.json': '$baseUrl/voice_styles/F1.json',
      'duration_predictor.onnx': '$baseUrl/onnx/duration_predictor.onnx',
      'text_encoder.onnx': '$baseUrl/onnx/text_encoder.onnx',
      'vector_estimator.onnx': '$baseUrl/onnx/vector_estimator.onnx',
      'vocoder.onnx': '$baseUrl/onnx/vocoder.onnx',
    };

    // Tính tổng dung lượng ước lượng (~96MB) để tính toán tiến trình tổng quát
    // Gán kích thước các file để tính progress chuẩn xác
    final fileSizes = {
      'tts.json': 635,
      'unicode_indexer.json': 207399,
      'M1.json': 24707,
      'F1.json': 24707,
      'duration_predictor.onnx': 8920150,
      'text_encoder.onnx': 29910543,
      'vector_estimator.onnx': 38043521,
      'vocoder.onnx': 22971213,
    };

    final double totalBytes = fileSizes.values.fold(0.0, (sum, size) => sum + size);
    double downloadedBytesTotal = 0.0;

    try {
      for (final entry in filesToDownload.entries) {
        final filename = entry.key;
        final url = entry.value;
        final destinationFile = File(p.join(dir.path, filename));

        _downloadStatus = 'Downloading $filename...';
        notifyListeners();

        LoggerService().log("Downloading file: $filename from $url", tag: 'SUPERTONIC');

        final request = http.Request('GET', Uri.parse(url));
        final response = await client.send(request).timeout(const Duration(seconds: 45));

        if (response.statusCode != 200) {
          throw Exception("Failed to download $filename: HTTP ${response.statusCode}");
        }

        final fileStream = destinationFile.openWrite();
        double fileDownloadedBytes = 0;
        final fileSize = fileSizes[filename] ?? response.contentLength ?? 1;

        await response.stream.listen(
          (chunk) {
            fileStream.add(chunk);
            fileDownloadedBytes += chunk.length;
            
            // Tính toán tiến trình tổng dựa trên dung lượng byte đã tải thực tế
            final currentTotalProgress = (downloadedBytesTotal + fileDownloadedBytes) / totalBytes;
            _downloadProgress = currentTotalProgress.clamp(0.0, 1.0);
            notifyListeners();
          },
          onDone: () async {
            await fileStream.flush();
            await fileStream.close();
            downloadedBytesTotal += fileSize;
            LoggerService().log("Finished downloading $filename", tag: 'SUPERTONIC');
          },
          onError: (err) {
            fileStream.close();
            throw err;
          },
          cancelOnError: true,
        ).asFuture();
      }

      _isDownloading = false;
      _downloadProgress = 1.0;
      _downloadStatus = 'All files downloaded successfully!';
      notifyListeners();
      LoggerService().log("Successfully downloaded all Supertonic assets.", tag: 'SUPERTONIC');
      return true;
    } catch (e) {
      _isDownloading = false;
      _downloadStatus = 'Error downloading: $e';
      notifyListeners();
      LoggerService().log("Fatal error downloading model files: $e", tag: 'SUPERTONIC', level: LogLevel.error);
      return false;
    } finally {
      client.close();
    }
  }

  /// Khởi tạo và nạp Engine Supertonic từ ổ cứng cục bộ vào bộ nhớ
  Future<bool> initializeEngine({String voiceStyle = 'M1'}) async {
    if (_isInitialized && _currentVoiceStyleName == voiceStyle) return true;
    if (_isLoadingModel) return false;

    _isLoadingModel = true;
    notifyListeners();

    try {
      final hasModels = await checkModelExists();
      if (!hasModels) {
        throw Exception("Model files are missing. Please download first.");
      }

      final dir = await _getAssetsDirectory();
      
      LoggerService().log("Loading Supertonic 3 models offline from ${dir.path}...", tag: 'SUPERTONIC');

      // Giải phóng engine cũ nếu có trước khi nạp mới
      await releaseEngine();

      // Nạp cấu hình & các session ONNX trực tiếp từ file vật lý cục bộ
      final cfgs = jsonDecode(File(p.join(dir.path, 'tts.json')).readAsStringSync()) as Map<String, dynamic>;
      final textProcessor = await UnicodeProcessor.load(p.join(dir.path, 'unicode_indexer.json'));
      
      final ort = OnnxRuntime();
      final models = [
        'duration_predictor',
        'text_encoder',
        'vector_estimator',
        'vocoder'
      ];

      // Khởi tạo OrtSession từ file vật lý
      final sessions = await Future.wait(models.map((name) async {
        final filePath = p.join(dir.path, '$name.onnx');
        LoggerService().log("Loading ONNX session for $name...", tag: 'SUPERTONIC');
        return ort.createSessionFromAsset(filePath);
      }));

      _textToSpeech = TextToSpeech(
        cfgs,
        textProcessor,
        sessions[0],
        sessions[1],
        sessions[2],
        sessions[3],
      );

      // Nạp style giọng đọc được chọn ('M1' hoặc 'F1')
      final stylePath = p.join(dir.path, '$voiceStyle.json');
      _activeStyle = await loadVoiceStyle([stylePath]);
      _currentVoiceStyleName = voiceStyle;
      _isInitialized = true;
      _isLoadingModel = false;
      
      notifyListeners();
      LoggerService().log("Supertonic 3 Engine loaded successfully offline with style $voiceStyle!", tag: 'SUPERTONIC');
      return true;
    } catch (e) {
      _isLoadingModel = false;
      _isInitialized = false;
      _textToSpeech = null;
      _activeStyle = null;
      _currentVoiceStyleName = '';
      notifyListeners();
      LoggerService().log("Error loading offline models: $e", tag: 'SUPERTONIC', level: LogLevel.error);
      return false;
    }
  }

  /// Đọc văn bản offline và sinh ra tệp WAV tạm thời, trả về đường dẫn file âm thanh sinh ra
  Future<String?> synthesizeToWav(String text, {double speed = 1.05, String lang = 'vi'}) async {
    if (!_isInitialized || _textToSpeech == null || _activeStyle == null) {
      LoggerService().log("Engine is not initialized yet.", tag: 'SUPERTONIC', level: LogLevel.error);
      return null;
    }

    try {
      final cleanText = text.trim();
      if (cleanText.isEmpty) return null;

      LoggerService().log("Generating speech offline using Supertonic v3. Text: \"${cleanText.substring(0, cleanText.length > 25 ? 25 : cleanText.length)}...\"", tag: 'SUPERTONIC');

      // Tự động phân tích ngôn ngữ hợp lệ (mặc định 'vi' nếu có, hoặc fallback 'en')
      final targetLang = isValidLang(lang) ? lang : 'vi';

      // Chạy suy luận nơ-ron cục bộ thông qua ONNX
      // ví dụ chạy denoising loop mặc định với 8 steps cho tốc độ tối ưu
      final result = await _textToSpeech!.call(
        cleanText,
        targetLang,
        _activeStyle!,
        8,
        speed: speed,
      );

      final List<double> wav = result['wav'] is List<double>
          ? result['wav'] as List<double>
          : (result['wav'] as List).cast<double>();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = p.join(tempDir.path, 'supertonic_$timestamp.wav');

      // Ghi ra file WAV tiêu chuẩn
      writeWavFile(outputPath, wav, _textToSpeech!.sampleRate);
      
      final file = File(outputPath);
      if (file.existsSync() && file.lengthSync() > 0) {
        LoggerService().log("Audio successfully synthesized and saved offline to: $outputPath", tag: 'SUPERTONIC');
        return file.absolute.path;
      } else {
        throw Exception("Failed to generate valid WAV file.");
      }
    } catch (e) {
      LoggerService().log("Fatal error in offline synthesis: $e", tag: 'SUPERTONIC', level: LogLevel.error);
      return null;
    }
  }

  /// Giải phóng bộ nhớ RAM bằng cách hủy các session của Engine ONNX
  Future<void> releaseEngine() async {
    if (!_isInitialized) return;

    try {
      LoggerService().log("Releasing Supertonic 3 ONNX sessions...", tag: 'SUPERTONIC');
      
      // Hủy session ONNX trong engine thông qua các API close và dispose
      // Giải phóng OrtSession
      await _textToSpeech?.dpOrt.close();
      await _textToSpeech?.textEncOrt.close();
      await _textToSpeech?.vectorEstOrt.close();
      await _textToSpeech?.vocoderOrt.close();
      
      // Giải phóng OrtValue trong style
      _activeStyle?.ttl.dispose();
      _activeStyle?.dp.dispose();

      _textToSpeech = null;
      _activeStyle = null;
      _currentVoiceStyleName = '';
      _isInitialized = false;
      notifyListeners();
      
      LoggerService().log("Supertonic 3 Engine released successfully.", tag: 'SUPERTONIC');
    } catch (e) {
      LoggerService().log("Error releasing engine: $e", tag: 'SUPERTONIC', level: LogLevel.error);
    }
  }

  /// Xóa các tệp mô hình offline để giải phóng dung lượng đĩa
  Future<void> deleteModelFiles() async {
    await releaseEngine();
    
    try {
      final dir = await _getAssetsDirectory();
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        LoggerService().log("Successfully deleted offline model directory.", tag: 'SUPERTONIC');
      }
      notifyListeners();
    } catch (e) {
      LoggerService().log("Error deleting model files: $e", tag: 'SUPERTONIC', level: LogLevel.error);
    }
  }
}
