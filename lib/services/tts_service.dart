import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/progress.dart';
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
    final db = await DatabaseHelper.getInstance();
    final progress = await db.getProgress(_activeBook!.uuid) ??
        (ReadingProgress()..bookUuid = _activeBook!.uuid);
    
    progress.currentChapterIndex = _currentChapterIndex;
    progress.currentParagraphIndex = _currentParagraphIndex;
    progress.currentCharacterOffset = 0;
    progress.lastRead = DateTime.now();
    await db.saveProgress(progress);
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
      wordStart = 0;
      wordEnd = 0;
      currentWord = "";
      await startSpeaking();
    } else {
      // Chuyển chương tiếp theo
      await nextChapter();
    }
  }

  Future<void> previousParagraph() async {
    if (_activeBook == null || _chapters.isEmpty) return;

    if (_currentParagraphIndex > 0) {
      _currentParagraphIndex--;
      wordStart = 0;
      wordEnd = 0;
      currentWord = "";
      await startSpeaking();
    } else if (_currentChapterIndex > 0) {
      // Về cuối chương trước
      _currentChapterIndex--;
      final prevChapter = _chapters[_currentChapterIndex];
      _currentParagraphIndex = prevChapter.paragraphs.isNotEmpty ? prevChapter.paragraphs.length - 1 : 0;
      wordStart = 0;
      wordEnd = 0;
      currentWord = "";
      await startSpeaking();
    }
  }

  Future<void> nextChapter() async {
    if (_activeBook == null || _chapters.isEmpty) return;

    if (_currentChapterIndex < _chapters.length - 1) {
      _currentChapterIndex++;
      _currentParagraphIndex = 0;
      wordStart = 0;
      wordEnd = 0;
      currentWord = "";
      await startSpeaking();
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
      wordStart = 0;
      wordEnd = 0;
      currentWord = "";
      await startSpeaking();
    }
  }

  Future<void> jumpToParagraph(int index) async {
    _currentParagraphIndex = index;
    wordStart = 0;
    wordEnd = 0;
    currentWord = "";
    await startSpeaking();
  }

  void _onParagraphFinished() {
    nextParagraph();
  }
}
