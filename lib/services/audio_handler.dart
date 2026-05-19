import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io' show Platform, File;
import '../core/database/database_helper.dart';
import 'edge_tts_service.dart';

enum TtsEngineType { system, edge }

class MyAudioHandler extends BaseAudioHandler with QueueHandler {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _edgePlayer = AudioPlayer();
  
  // Callback báo từ đang đọc về UI để highlight
  Function(String text, int start, int end, String word)? onWordProgress;
  
  // Callback báo khi đọc xong đoạn văn để chuyển sang đoạn tiếp theo
  Function()? onParagraphComplete;

  bool _isSpeaking = false;
  String _currentText = "";
  double _speechRate = 0.5; // Tốc độ nói hiện tại của TTS (0.5 tương đương 1.0x)
  Timer? _windowsTimer; // Timer giả lập hoàn thành trên Windows

  TtsEngineType _activeEngine = TtsEngineType.system;
  final List<EdgeMetadataChunk> _edgeMetadata = [];
  int _lastHighlightIndex = 0;
  String _lastWord = "";

  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;

  MyAudioHandler() {
    _initTts();
    _initEdgePlayer();
  }

  void _initTts() {
    if (!Platform.isWindows) {
      _tts.setSharedInstance(true);
    }
    _tts.setProgressHandler((String text, int start, int end, String word) {
      if (_activeEngine != TtsEngineType.system) return;
      _currentText = text;
      onWordProgress?.call(text, start, end, word);
    });

    _tts.setCompletionHandler(() {
      if (Platform.isWindows) return;
      if (_activeEngine != TtsEngineType.system) return;

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
      if (_activeEngine != TtsEngineType.system) return;
      _isSpeaking = false;
      _windowsTimer?.cancel();
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
      ));
    });
  }

  void _initEdgePlayer() {
    _positionSub = _edgePlayer.onPositionChanged.listen((duration) {
      if (_activeEngine != TtsEngineType.edge || !_isSpeaking) return;

      final currentMs = duration.inMilliseconds;
      EdgeMetadataChunk? currentWordChunk;

      for (final chunk in _edgeMetadata) {
        if (currentMs >= chunk.offset && currentMs <= chunk.offset + chunk.duration) {
          currentWordChunk = chunk;
          break;
        }
      }

      if (currentWordChunk != null && currentWordChunk.text != _lastWord) {
        _lastWord = currentWordChunk.text;
        
        // Stateful search để tìm chính xác index của từ lặp lại trong chuỗi
        int startIdx = _currentText.indexOf(_lastWord, _lastHighlightIndex);
        if (startIdx == -1) {
          // Fallback nếu không tìm thấy từ kế tiếp, tìm từ đầu
          startIdx = _currentText.indexOf(_lastWord);
        }
        
        if (startIdx != -1) {
          _lastHighlightIndex = startIdx + _lastWord.length;
          onWordProgress?.call(_currentText, startIdx, startIdx + _lastWord.length, _lastWord);
        }
      }
    });

    _completeSub = _edgePlayer.onPlayerComplete.listen((_) {
      if (_activeEngine != TtsEngineType.edge || !_isSpeaking) return;

      _isSpeaking = false;
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.completed,
      ));

      Future.delayed(Duration.zero, () {
        onParagraphComplete?.call();
      });
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
      if (_isSpeaking && _activeEngine == TtsEngineType.system) {
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
    // 1. Dừng mọi tác vụ phát cũ một cách an toàn và tuần tự
    _isSpeaking = false;
    _windowsTimer?.cancel();
    
    await _tts.stop();
    await _edgePlayer.stop();
    
    if (!Platform.isWindows) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    _currentText = text;
    _lastHighlightIndex = 0;
    _lastWord = "";
    
    // 2. Đọc cấu hình nhà cung cấp từ cơ sở dữ liệu Isar
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    final provider = (settings.ttsProvider == 'microsoft_edge') ? 'microsoft_edge' : 'system';
    
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

    if (provider == 'microsoft_edge') {
      _activeEngine = TtsEngineType.edge;
      
      final audioBytes = <int>[];
      _edgeMetadata.clear();
      
      try {
        // Tải luồng byte âm thanh đám mây kèm theo Word boundaries
        await for (final chunk in EdgeTtsService.synthesize(
          text: text,
          voice: settings.selectedVoiceName ?? "vi-VN-HoaiMyNeural",
          rate: _speechRate,
        )) {
          if (chunk is EdgeAudioChunk) {
            audioBytes.addAll(chunk.data);
          } else if (chunk is EdgeMetadataChunk) {
            _edgeMetadata.add(chunk);
          }
        }
        
        if (audioBytes.isEmpty) {
          throw Exception("No audio bytes received from Microsoft Edge TTS");
        }
        
        // Ghi dữ liệu âm thanh MP3 ra file tạm thời
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/tts_temp.mp3');
        await tempFile.writeAsBytes(audioBytes, flush: true);
        
        // Bắt đầu phát âm thanh bằng audioplayers
        _isSpeaking = true;
        await _edgePlayer.play(DeviceFileSource(tempFile.path));
        await _edgePlayer.setPlaybackRate(_speechRate * 2.0); // Quy đổi 0.5 -> 1.0x tốc độ chuẩn
        
      } catch (e) {
        debugPrint("Edge TTS failed, falling back to System TTS: $e");
        
        // HỆ THỐNG FALLBACK AN TOÀN: Chuyển về System TTS ngay lập tức
        _activeEngine = TtsEngineType.system;
        _isSpeaking = true;
        
        await _tts.speak(text);
        if (Platform.isWindows) {
          _startWindowsCompletionTimer(text);
        }
      }
    } else {
      // Luồng chạy mặc định sử dụng System TTS
      _activeEngine = TtsEngineType.system;
      _isSpeaking = true;
      
      await _tts.speak(text);
      if (Platform.isWindows) {
        _startWindowsCompletionTimer(text);
      }
    }
  }

  @override
  Future<void> play() async {
    if (!_isSpeaking && _currentText.isNotEmpty) {
      if (_activeEngine == TtsEngineType.edge) {
        _isSpeaking = true;
        playbackState.add(playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
          ],
          playing: true,
          processingState: AudioProcessingState.ready,
        ));
        await _edgePlayer.resume();
      } else {
        await speak(_currentText);
      }
    }
  }

  @override
  Future<void> pause() async {
    _isSpeaking = false;
    _windowsTimer?.cancel();
    
    if (_activeEngine == TtsEngineType.edge) {
      await _edgePlayer.pause();
    } else {
      await _tts.stop();
    }
    
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
    
    if (_activeEngine == TtsEngineType.edge) {
      await _edgePlayer.stop();
    } else {
      await _tts.stop();
    }
    
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speechRate = speed;
    await _tts.setSpeechRate(speed);
    if (_activeEngine == TtsEngineType.edge) {
      await _edgePlayer.setPlaybackRate(speed * 2.0);
    }
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

  Future<void> cleanUp() async {
    await _positionSub?.cancel();
    await _completeSub?.cancel();
    await _edgePlayer.dispose();
  }
}
