import 'package:audio_service/audio_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler {
  final FlutterTts _tts = FlutterTts();
  
  // Callback báo từ đang đọc về UI để highlight
  Function(String text, int start, int end, String word)? onWordProgress;
  
  // Callback báo khi đọc xong đoạn văn để chuyển sang đoạn tiếp theo
  Function()? onParagraphComplete;

  bool _isSpeaking = false;
  String _currentText = "";

  MyAudioHandler() {
    _initTts();
  }

  void _initTts() {
    _tts.setProgressHandler((String text, int start, int end, String word) {
      _currentText = text;
      onWordProgress?.call(text, start, end, word);
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.completed,
      ));
      onParagraphComplete?.call();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
      ));
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
  }

  @override
  Future<void> play() async {
    if (!_isSpeaking && _currentText.isNotEmpty) {
      await speak(_currentText);
    }
  }

  @override
  Future<void> pause() async {
    await _tts.stop();
    _isSpeaking = false;
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
    await _tts.stop();
    _isSpeaking = false;
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  Future<void> setSpeed(double speed) async {
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
