import 'package:audio_service/audio_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io' show Platform;

class MyAudioHandler extends BaseAudioHandler with QueueHandler {
  final FlutterTts _tts = FlutterTts();
  
  // Callback báo từ đang đọc về UI để highlight
  Function(String text, int start, int end, String word)? onWordProgress;
  
  // Callback báo khi đọc xong đoạn văn để chuyển sang đoạn tiếp theo
  Function()? onParagraphComplete;

  bool _isSpeaking = false;
  String _currentText = "";
  double _speechRate = 0.5; // Tốc độ nói hiện tại của TTS (0.5 tương đương 1.0x)
  Timer? _windowsTimer; // Timer giả lập hoàn thành trên Windows

  MyAudioHandler() {
    _initTts();
  }

  void _initTts() {
    _tts.setProgressHandler((String text, int start, int end, String word) {
      _currentText = text;
      onWordProgress?.call(text, start, end, word);
    });

    _tts.setCompletionHandler(() {
      // Trên Windows, cơ chế hoàn thành được giả lập qua WindowsTimer để tránh lỗi Threading và đảm bảo tính di động
      if (Platform.isWindows) return;

      // Nếu trạng thái phát đã bị dừng hoặc ngắt bởi mã nguồn, bỏ qua hoàn toàn sự kiện
      if (!_isSpeaking) return;
      
      _isSpeaking = false;
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.completed,
      ));
      
      // Đưa việc gọi callback ra ngoài Native Thread sang Dart Event Loop (Platform Thread)
      Future.delayed(Duration.zero, () {
        onParagraphComplete?.call();
      });
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _windowsTimer?.cancel();
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
      ));
    });
  }

  void _startWindowsCompletionTimer(String text) {
    _windowsTimer?.cancel();
    
    // Tốc độ chuẩn 1.0x tương ứng với speechRate = 0.5 trong flutter_tts
    final speedMultiplier = _speechRate * 2.0; // Quy đổi về hệ số nhân (0.5 -> 1.0x, 0.75 -> 1.5x)
    
    // Đếm số lượng dấu câu ngắt câu (period, exclamation, question, ellipsis)
    final endPunctCount = RegExp(r'[.!?…]').allMatches(text).length;
    // Đếm số lượng dấu câu ngắt hơi (comma, semicolon, colon, dash)
    final midPunctCount = RegExp(r'[,;:\-]').allMatches(text).length;
    
    // SAPI Windows nói tiếng Việt chuẩn tự nhiên ở tốc độ ~80ms/ký tự
    final baseDurationMs = text.length * 80.0;
    
    // Cộng thêm các khoảng nghỉ tự nhiên của giọng đọc (300ms cho dấu chấm, 150ms cho dấu phẩy)
    final pauseDurationMs = (endPunctCount * 300.0) + (midPunctCount * 150.0);
    
    // Tổng thời gian điều chỉnh theo tốc độ nói + đệm an toàn 750ms giúp dứt chữ hoàn hảo
    final durationMs = ((baseDurationMs + pauseDurationMs + 750.0) / speedMultiplier).round();
    
    _windowsTimer = Timer(Duration(milliseconds: durationMs), () {
      if (_isSpeaking) {
        _isSpeaking = false;
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
        
        // Chuyển sang đoạn tiếp theo trên Platform Thread
        Future.delayed(Duration.zero, () {
          onParagraphComplete?.call();
        });
      }
    });
  }

  Future<void> updateMetadata({
    required String bookTitle,
    required String chapterTitle,
    required int paragraphIndex,
    required int totalParagraphs,
  }) async {
    mediaItem.add(MediaItem(
      id: 'tts_paragraph_$paragraphIndex',
      album: bookTitle,
      title: chapterTitle,
      artist: 'Novel Reader',
      duration: Duration(seconds: totalParagraphs), // Duration giả lập hiển thị
    ));
  }

  Future<void> speak(String text) async {
    // Đặt speak = false trước khi stop để bỏ qua sự kiện completion giả do stop gây ra
    _isSpeaking = false;
    _windowsTimer?.cancel();
    await _tts.stop();
    
    // Chờ một khoảng ngắn (100ms) để bất kỳ callback hoàn thành giả nào (nếu có)
    // từ cuộc gọi stop() ở trên được gửi từ native và xử lý xong trong Dart Event Loop
    // trước khi chúng ta thiết lập _isSpeaking = true cho lượt đọc mới.
    if (!Platform.isWindows) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    _currentText = text;
    _isSpeaking = true;
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      playing: true,
      processingState: AudioProcessingState.ready,
    ));

    await _tts.speak(text);

    // Kích hoạt Timer giả lập trên Windows
    if (Platform.isWindows) {
      _startWindowsCompletionTimer(text);
    }
  }

  @override
  Future<void> play() async {
    if (!_isSpeaking && _currentText.isNotEmpty) {
      await speak(_currentText);
    }
  }

  @override
  Future<void> pause() async {
    _isSpeaking = false;
    _windowsTimer?.cancel();
    await _tts.pause();
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      playing: false,
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    _windowsTimer?.cancel();
    await _tts.stop();
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  Future<void> setSpeed(double speed) async {
    _speechRate = speed;
    await _tts.setSpeechRate(speed);
  }

  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
  }

  Future<List<dynamic>> getVoices() async {
    return await _tts.getVoices;
  }
}
