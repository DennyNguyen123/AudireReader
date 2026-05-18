import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/progress.dart';
import '../models/settings.dart';
import 'audio_handler.dart';
import '../core/database/database_helper.dart';

class TtsService extends ChangeNotifier {
  static TtsService? _instance;
  late final MyAudioHandler audioHandler;

  Book? _activeBook;
  List<Chapter> _chapters = [];
  int _currentChapterIndex = 0;
  int _currentParagraphIndex = 0;

  // Highlight vị trí từ đang đọc
  int wordStart = 0;
  int wordEnd = 0;
  String currentWord = "";

  bool get isPlaying => audioHandler.playbackState.value.playing;
  Book? get activeBook => _activeBook;
  List<Chapter> get chapters => _chapters;
  int get currentChapterIndex => _currentChapterIndex;
  int get currentParagraphIndex => _currentParagraphIndex;

  TtsService._();

  static Future<TtsService> getInstance() async {
    if (_instance == null) {
      _instance = TtsService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    // 1. Cấu hình AudioSession cho nền tảng di động phát chạy nền
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // 2. Khởi tạo Audio Service
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.novelspace.reader.channel.audio',
        androidNotificationChannelName: 'Novel Reader Audio Playback',
        androidNotificationOngoing: true,
      ),
    );

    // 3. Đăng ký các Callbacks để cập nhật UI
    audioHandler.onWordProgress = (text, start, end, word) {
      wordStart = start;
      wordEnd = end;
      currentWord = word;
      notifyListeners();
    };

    audioHandler.onParagraphComplete = () {
      _onParagraphFinished();
    };

    // Lắng nghe thay đổi trạng thái phát từ OS (lock screen bấm dừng/phát)
    audioHandler.playbackState.listen((state) {
      notifyListeners();
    });

    // Áp dụng các cài đặt đã lưu tự động
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();
      await audioHandler.setSpeed(settings.speechRate);
      
      if (settings.selectedVoiceName != null && settings.selectedVoiceLocale != null) {
        final voices = await audioHandler.getVoices();
        final savedVoice = voices.firstWhere(
          (v) => v['name']?.toString() == settings.selectedVoiceName &&
                 v['locale']?.toString() == settings.selectedVoiceLocale,
          orElse: () => null,
        );
        if (savedVoice != null) {
          final voiceMap = Map<String, String>.from(
            (savedVoice as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
          );
          await audioHandler.setVoice(voiceMap);
        }
      }
    } catch (e) {
      print("Failed to restore TTS settings: $e");
    }
  }

  Future<void> loadBook(Book book, List<Chapter> chapters, {int startChapter = 0, int startParagraph = 0}) async {
    _activeBook = book;
    _chapters = chapters;
    _currentChapterIndex = startChapter;
    _currentParagraphIndex = startParagraph;
    wordStart = 0;
    wordEnd = 0;
    currentWord = "";
    notifyListeners();
  }

  Future<void> _saveProgressLocally() async {
    if (_activeBook == null) return;
    final db = await DatabaseHelper.getInstance();
    final progress = await db.getProgress(_activeBook!.uuid) ??
        (ReadingProgress()..bookUuid = _activeBook!.uuid);
    
    progress.currentChapterIndex = _currentChapterIndex;
    progress.currentParagraphIndex = _currentParagraphIndex;
    progress.currentCharacterOffset = 0;
    progress.lastRead = DateTime.now();
    await db.saveProgress(progress);
  }

  Future<void> _onStateChanged({bool forceSpeak = false}) async {
    wordStart = 0;
    wordEnd = 0;
    currentWord = "";

    if (isPlaying || forceSpeak) {
      await startSpeaking();
    } else {
      if (_activeBook == null || _chapters.isEmpty) return;
      final chapter = _chapters[_currentChapterIndex];
      await audioHandler.updateMetadata(
        bookTitle: _activeBook!.title,
        chapterTitle: chapter.title,
        paragraphIndex: _currentParagraphIndex,
        totalParagraphs: chapter.paragraphs.length,
      );
      notifyListeners();
      await _saveProgressLocally();
    }
  }

  Future<void> startSpeaking() async {
    if (_activeBook == null || _chapters.isEmpty) return;

    final chapter = _chapters[_currentChapterIndex];
    if (chapter.paragraphs.isEmpty) return;

    final text = chapter.paragraphs[_currentParagraphIndex];

    await audioHandler.updateMetadata(
      bookTitle: _activeBook!.title,
      chapterTitle: chapter.title,
      paragraphIndex: _currentParagraphIndex,
      totalParagraphs: chapter.paragraphs.length,
    );

    await audioHandler.speak(text);
    notifyListeners();

    // Lưu tiến độ đọc vào database tạm
    await _saveProgressLocally();
  }

  Future<void> pauseSpeaking() async {
    await audioHandler.pause();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pauseSpeaking();
    } else {
      await startSpeaking();
    }
  }

  Future<void> nextParagraph() async {
    if (_activeBook == null || _chapters.isEmpty) return;
    final chapter = _chapters[_currentChapterIndex];

    if (_currentParagraphIndex < chapter.paragraphs.length - 1) {
      _currentParagraphIndex++;
      await _onStateChanged();
    } else {
      // Chuyển chương tiếp theo
      await nextChapter();
    }
  }

  Future<void> previousParagraph() async {
    if (_activeBook == null || _chapters.isEmpty) return;

    if (_currentParagraphIndex > 0) {
      _currentParagraphIndex--;
      await _onStateChanged();
    } else if (_currentChapterIndex > 0) {
      // Về cuối chương trước
      _currentChapterIndex--;
      final prevChapter = _chapters[_currentChapterIndex];
      _currentParagraphIndex = prevChapter.paragraphs.isNotEmpty ? prevChapter.paragraphs.length - 1 : 0;
      await _onStateChanged();
    }
  }

  Future<void> nextChapter() async {
    if (_activeBook == null || _chapters.isEmpty) return;

    if (_currentChapterIndex < _chapters.length - 1) {
      _currentChapterIndex++;
      _currentParagraphIndex = 0;
      await _onStateChanged();
    } else {
      // Đã hết sách
      await audioHandler.stop();
      notifyListeners();
    }
  }

  Future<void> previousChapter() async {
    if (_activeBook == null || _chapters.isEmpty) return;

    if (_currentChapterIndex > 0) {
      _currentChapterIndex--;
      _currentParagraphIndex = 0;
      await _onStateChanged();
    }
  }

  Future<void> jumpToParagraph(int index) async {
    _currentParagraphIndex = index;
    // Bấm thủ công vào đoạn văn nào luôn luôn kích hoạt phát tiếng từ đó
    await _onStateChanged(forceSpeak: true);
  }

  Future<void> jumpToChapter(int index) async {
    if (_activeBook == null || _chapters.isEmpty) return;
    if (index < 0 || index >= _chapters.length) return;

    _currentChapterIndex = index;
    _currentParagraphIndex = 0;
    await _onStateChanged();
  }

  void _onParagraphFinished() {
    nextParagraph();
  }

  Future<AppSettings> getSettings() async {
    final db = await DatabaseHelper.getInstance();
    return await db.getSettings();
  }

  Future<void> updateSettings({
    double? fontSize,
    double? speechRate,
    Map<String, String>? voice,
    String? fontFamily,
    String? themeMode,
  }) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    
    if (fontSize != null) settings.fontSize = fontSize;
    if (speechRate != null) {
      settings.speechRate = speechRate;
      await audioHandler.setSpeed(speechRate);
    }
    if (voice != null) {
      settings.selectedVoiceName = voice['name'];
      settings.selectedVoiceLocale = voice['locale'];
      await audioHandler.setVoice(voice);
    }
    if (fontFamily != null) {
      settings.fontFamily = fontFamily;
    }
    if (themeMode != null) {
      settings.themeMode = themeMode;
    }
    
    await db.saveSettings(settings);
    notifyListeners();
  }
}
