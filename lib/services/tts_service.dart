// ignore_for_file: avoid_print
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/progress.dart';
import '../models/settings.dart';
import '../models/pronunciation_rule.dart';
import 'audio_handler.dart';
import 'supertonic_service.dart';
import 'edge_tts_service.dart';
import '../core/database/database_helper.dart';
import 'sync_service.dart';
import 'logger_service.dart';

void print(Object? object) {
  final message = object?.toString() ?? '';
  LogLevel level = LogLevel.info;
  if (message.toLowerCase().contains('error') || 
      message.toLowerCase().contains('failed') || 
      message.toLowerCase().contains('fatal')) {
    level = LogLevel.error;
  } else if (message.toLowerCase().contains('warning')) {
    level = LogLevel.warning;
  }
  LoggerService().log(message, tag: 'TTS', level: level);
}

class TtsService extends ChangeNotifier {
  static TtsService? _instance;
  late final MyAudioHandler audioHandler;

  Book? _activeBook;
  List<Chapter> _chapters = [];
  int _currentChapterIndex = 0;
  int _currentParagraphIndex = 0;
  double _speechRate = 0.5; // Tốc độ nói hiện tại của TTS

  // Highlight vị trí từ đang đọc
  int wordStart = 0;
  int wordEnd = 0;
  String currentWord = "";

  // Hẹn giờ tắt (Sleep Timer)
  Timer? _sleepTimer;
  int? _sleepTimerDuration; // giây
  bool _stopAtEndOfChapter = false;

  // Từ điển phát âm
  List<PronunciationRule> _activeRules = [];

  bool get isPlaying => audioHandler.playbackState.value.playing;
  Book? get activeBook => _activeBook;
  List<Chapter> get chapters => _chapters;
  int get currentChapterIndex => _currentChapterIndex;
  int get currentParagraphIndex => _currentParagraphIndex;

  int? get sleepTimerDuration => _sleepTimerDuration;
  bool get isSleepTimerActive => _sleepTimer != null;
  bool get stopAtEndOfChapter => _stopAtEndOfChapter;
  List<PronunciationRule> get activeRules => _activeRules;

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
        androidNotificationChannelName: 'Audire Reader Audio Playback',
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
      if (state.playing) {
        _prefetchNextParagraphs();
      }
      notifyListeners();
    });

    audioHandler.onSkipToNext = () {
      nextParagraph();
    };

    audioHandler.onSkipToPrevious = () {
      previousParagraph();
    };

    audioHandler.onSeekToParagraph = (index) {
      jumpToParagraph(index);
    };

    // Áp dụng các cài đặt đã lưu tự động
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();
      _speechRate = settings.speechRate;
      await audioHandler.setSpeed(settings.speechRate);
      
      final provider = settings.ttsProvider;
      if (provider == 'supertonic') {
        final supertonic = SupertonicService.getInstance();
        final voiceName = settings.selectedVoiceName ?? 'M1';
        if (await supertonic.checkModelExists()) {
          unawaited(supertonic.initializeEngine(voiceStyle: voiceName));
        }
      } else if (provider == 'system' &&
          settings.selectedVoiceName != null && 
          settings.selectedVoiceLocale != null) {
        final voices = await audioHandler.getVoices();
        dynamic savedVoice;
        for (final v in voices) {
          if (v['name']?.toString() == settings.selectedVoiceName &&
              v['locale']?.toString() == settings.selectedVoiceLocale) {
            savedVoice = v;
            break;
          }
        }
        if (savedVoice != null) {
          final voiceMap = Map<String, String>.from(
            (savedVoice as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
          );
          await audioHandler.setVoice(voiceMap);
        }
      }

      // Tải từ điển phát âm
      await loadPronunciationRules();
    } catch (e) {
      print("Failed to restore TTS settings: $e");
    }
  }

  // --- Pronunciation Dictionary Operations ---
  Future<void> loadPronunciationRules() async {
    try {
      final db = await DatabaseHelper.getInstance();
      _activeRules = await db.getActivePronunciationRules();
      notifyListeners();
    } catch (e) {
      print("Failed to load pronunciation rules: $e");
    }
  }

  String applyPronunciationRules(String text) {
    if (_activeRules.isEmpty || text.isEmpty) return text;
    String result = text;
    for (final rule in _activeRules) {
      if (rule.target.isEmpty) continue;
      if (rule.isRegex) {
        try {
          final regex = RegExp(rule.target, caseSensitive: false, unicode: true);
          result = result.replaceAll(regex, rule.replacement);
        } catch (e) {
          print("Invalid regex rule target '${rule.target}': $e");
        }
      } else {
        try {
          final regex = RegExp(RegExp.escape(rule.target), caseSensitive: false, unicode: true);
          result = result.replaceAll(regex, rule.replacement);
        } catch (e) {
          result = result.replaceAll(rule.target, rule.replacement);
        }
      }
    }
    return result;
  }

  // --- Sleep Timer Operations ---
  void startSleepTimer(int minutes) {
    cancelSleepTimer();
    _stopAtEndOfChapter = false;
    _sleepTimerDuration = minutes * 60;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerDuration != null && _sleepTimerDuration! > 0) {
        _sleepTimerDuration = _sleepTimerDuration! - 1;
        notifyListeners();
      } else {
        cancelSleepTimer();
        pauseSpeaking();
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerDuration = null;
    notifyListeners();
  }

  void enableStopAtEndOfChapter(bool enable) {
    cancelSleepTimer();
    _stopAtEndOfChapter = enable;
    notifyListeners();
  }

  Future<void> loadBook(Book book, List<Chapter> chapters, {int startChapter = 0, int startParagraph = 0}) async {
    LoggerService().log('Loading book "${book.title}" at Chapter $startChapter, Paragraph $startParagraph', tag: 'TTS', level: LogLevel.tts);
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

    final isLastChapter = _currentChapterIndex >= _chapters.length - 1;
    final isLastParagraph = _chapters.isEmpty || 
        _currentParagraphIndex >= _chapters[_currentChapterIndex].paragraphs.length - 1;
    final newStatus = (isLastChapter && isLastParagraph) ? 'completed' : 'reading';

    if (_activeBook!.status != newStatus) {
      _activeBook!.status = newStatus;
      await db.saveBook(_activeBook!);
    }
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

      final charPerSec = getCharsPerSecond();
      final chapterDuration = getChapterDuration();
      final startPos = getParagraphStartPos(_currentParagraphIndex);

      audioHandler.setChapterData(
        chapter.paragraphs,
        chapterDuration,
        startPos,
        charPerSec,
      );

      await audioHandler.updateMetadata(
        bookTitle: _activeBook!.title,
        chapterTitle: chapter.title,
        paragraphIndex: _currentParagraphIndex,
        totalParagraphs: chapter.paragraphs.length,
        coverPath: _activeBook!.coverPath,
        chapterDuration: chapterDuration,
        chapterPosition: startPos,
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
    LoggerService().log('TTS speaking Chapter $_currentChapterIndex, Paragraph $_currentParagraphIndex: "${text.substring(0, text.length > 30 ? 30 : text.length)}..."', tag: 'TTS', level: LogLevel.tts);

    final charPerSec = getCharsPerSecond();
    final chapterDuration = getChapterDuration();
    final startPos = getParagraphStartPos(_currentParagraphIndex);

    audioHandler.setChapterData(
      chapter.paragraphs,
      chapterDuration,
      startPos,
      charPerSec,
    );

    await audioHandler.updateMetadata(
      bookTitle: _activeBook!.title,
      chapterTitle: chapter.title,
      paragraphIndex: _currentParagraphIndex,
      totalParagraphs: chapter.paragraphs.length,
      coverPath: _activeBook!.coverPath,
      chapterDuration: chapterDuration,
      chapterPosition: startPos,
    );

    // Áp dụng từ điển sửa phát âm
    final processedText = applyPronunciationRules(text);
    await audioHandler.speak(processedText);
    notifyListeners();

    // Lưu tiến độ đọc vào database tạm
    await _saveProgressLocally();

    // Tải trước các đoạn văn tiếp theo
    _prefetchNextParagraphs();
  }

  Future<void> pauseSpeaking() async {
    LoggerService().log('TTS speaking paused', tag: 'TTS', level: LogLevel.tts);
    await audioHandler.pause();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pauseSpeaking();
    } else {
      final state = audioHandler.playbackState.value;
      if (state.processingState == AudioProcessingState.ready && _activeBook != null) {
        // Resume từ chỗ đang dừng
        LoggerService().log('TTS resuming from pause', tag: 'TTS', level: LogLevel.tts);
        await audioHandler.play();
        notifyListeners();
      } else {
        await startSpeaking();
      }
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
      SyncService.getInstance().syncBookProgress(_activeBook!.uuid);
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
      SyncService.getInstance().syncBookProgress(_activeBook!.uuid);
    }
  }

  Future<void> jumpToParagraph(int index) async {
    _currentParagraphIndex = index;
    // Nếu đang phát tiếng thì tiếp tục phát ở đoạn mới, nếu không phát thì chỉ cập nhật vị trí
    await _onStateChanged();
  }

  Future<void> jumpToChapter(int index) async {
    if (_activeBook == null || _chapters.isEmpty) return;
    if (index < 0 || index >= _chapters.length) return;

    _currentChapterIndex = index;
    _currentParagraphIndex = 0;
    await _onStateChanged();
    SyncService.getInstance().syncBookProgress(_activeBook!.uuid);
  }

  void _prefetchNextParagraphs() {
    if (_activeBook == null || _chapters.isEmpty) return;
    if (!isPlaying) return;

    final nextParagraphs = <String>[];
    int tempChIdx = _currentChapterIndex;
    int tempPgIdx = _currentParagraphIndex + 1;

    // Tải trước tối đa 2 đoạn văn tiếp theo
    while (nextParagraphs.length < 2) {
      if (tempChIdx >= _chapters.length) break;
      final ch = _chapters[tempChIdx];
      if (tempPgIdx < ch.paragraphs.length) {
        // Áp dụng từ điển sửa phát âm cho đoạn prefetch
        nextParagraphs.add(applyPronunciationRules(ch.paragraphs[tempPgIdx]));
        tempPgIdx++;
      } else {
        tempChIdx++;
        tempPgIdx = 0;
      }
    }

    if (nextParagraphs.isNotEmpty) {
      audioHandler.prefetch(nextParagraphs);
    }
  }

  void _onParagraphFinished() {
    if (_activeBook == null || _chapters.isEmpty) return;
    final chapter = _chapters[_currentChapterIndex];
    if (_currentParagraphIndex >= chapter.paragraphs.length - 1 && _stopAtEndOfChapter) {
      _stopAtEndOfChapter = false;
      pauseSpeaking();
      // Nhảy sang đầu chương tiếp theo nhưng không phát
      if (_currentChapterIndex < _chapters.length - 1) {
        _currentChapterIndex++;
        _currentParagraphIndex = 0;
        _onStateChanged(forceSpeak: false);
      }
      notifyListeners();
    } else {
      nextParagraph();
    }
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
    String? ttsProvider,
    String? openAiTtsEndpoint,
    String? openAiTtsApiKey,
    String? openAiTtsModel,
    double? lineHeight,
    double? paragraphSpacing,
    String? textAlignment,
    double? sideMargin,
    String? customBackgroundColor,
    String? customTextColor,
    String? primaryColorHex,
  }) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    
    if (fontSize != null) settings.fontSize = fontSize;
    if (speechRate != null) {
      _speechRate = speechRate;
      settings.speechRate = speechRate;
      await audioHandler.setSpeed(speechRate);
    }
    if (openAiTtsEndpoint != null) settings.openAiTtsEndpoint = openAiTtsEndpoint;
    if (openAiTtsApiKey != null) settings.openAiTtsApiKey = openAiTtsApiKey;
    if (openAiTtsModel != null) settings.openAiTtsModel = openAiTtsModel;
    if (voice != null) {
      settings.selectedVoiceName = voice['name'];
      settings.selectedVoiceLocale = voice['locale'];
      if (settings.ttsProvider == 'system') {
        await audioHandler.setVoice(voice);
      } else if (settings.ttsProvider == 'supertonic') {
        final voiceName = voice['name'] ?? 'M1';
        unawaited(SupertonicService.getInstance().initializeEngine(voiceStyle: voiceName));
      }
    }
    if (fontFamily != null) {
      settings.fontFamily = fontFamily;
    }
    if (themeMode != null) {
      settings.themeMode = themeMode;
    }
    if (ttsProvider != null) {
      settings.ttsProvider = ttsProvider;
      if (ttsProvider == 'supertonic') {
        settings.selectedVoiceName = 'M1';
        settings.selectedVoiceLocale = 'offline';
        unawaited(SupertonicService.getInstance().initializeEngine(voiceStyle: 'M1'));
      } else if (ttsProvider == 'openai') {
        settings.selectedVoiceName = 'alloy';
        settings.selectedVoiceLocale = 'en';
      } else {
        settings.selectedVoiceName = null;
        settings.selectedVoiceLocale = null;
      }
    }
    
    if (lineHeight != null) settings.lineHeight = lineHeight;
    if (paragraphSpacing != null) settings.paragraphSpacing = paragraphSpacing;
    if (textAlignment != null) settings.textAlignment = textAlignment;
    if (sideMargin != null) settings.sideMargin = sideMargin;
    if (customBackgroundColor != null) settings.customBackgroundColor = customBackgroundColor;
    if (customTextColor != null) settings.customTextColor = customTextColor;
    if (primaryColorHex != null) settings.primaryColorHex = primaryColorHex;
    
    await db.saveSettings(settings);
    notifyListeners();
  }

  Future<List<dynamic>> getVoicesForProvider(String provider) async {
    if (provider == 'supertonic') {
      return [
        {'name': 'M1', 'locale': 'offline', 'gender': 'Male'},
        {'name': 'M2', 'locale': 'offline', 'gender': 'Male'},
        {'name': 'M3', 'locale': 'offline', 'gender': 'Male'},
        {'name': 'M4', 'locale': 'offline', 'gender': 'Male'},
        {'name': 'M5', 'locale': 'offline', 'gender': 'Male'},
        {'name': 'F1', 'locale': 'offline', 'gender': 'Female'},
        {'name': 'F2', 'locale': 'offline', 'gender': 'Female'},
        {'name': 'F3', 'locale': 'offline', 'gender': 'Female'},
        {'name': 'F4', 'locale': 'offline', 'gender': 'Female'},
        {'name': 'F5', 'locale': 'offline', 'gender': 'Female'},
      ];
    }
    if (provider == 'openai') {
      // Lazy load openAiTtsService if needed, but it's just static now
      // Actually we will hardcode the voices here or return from OpenAiTtsService
      return [
        {'name': 'alloy', 'locale': 'en', 'gender': 'Neutral'},
        {'name': 'echo', 'locale': 'en', 'gender': 'Male'},
        {'name': 'fable', 'locale': 'en', 'gender': 'Neutral'},
        {'name': 'onyx', 'locale': 'en', 'gender': 'Male'},
        {'name': 'nova', 'locale': 'en', 'gender': 'Female'},
        {'name': 'shimmer', 'locale': 'en', 'gender': 'Female'},
      ];
    }
    final normalizedProvider = (provider == 'microsoft_edge') ? 'microsoft_edge' : 'system';
    if (normalizedProvider == 'microsoft_edge') {
      try {
        final rawVoices = await EdgeTtsService.listVoices();
        // Chuẩn hóa danh sách giọng đọc từ Edge sang cấu trúc tương thích với FlutterTts
        return rawVoices.map((v) => {
          'name': v['ShortName'] ?? v['Name'] ?? '',
          'locale': v['Locale'] ?? '',
          'gender': v['Gender'] ?? '',
        }).toList();
      } catch (e) {
        print("Error fetching edge voices: $e");
        return [];
      }
    } else {
      return await audioHandler.getVoices();
    }
  }

  // --- TTS Duration & Progress Calculations ---
  double getSpeechRateMultiplier() {
    return _speechRate * 2.0;
  }

  double getCharsPerSecond() {
    return 15.0 * getSpeechRateMultiplier();
  }

  double estimateParagraphDuration(String text) {
    if (text.isEmpty) return 0.0;
    return text.length / getCharsPerSecond();
  }

  double getChapterDuration() {
    if (_activeBook == null || _chapters.isEmpty) return 0.0;
    final chapter = _chapters[_currentChapterIndex];
    double total = 0.0;
    for (final p in chapter.paragraphs) {
      total += estimateParagraphDuration(p);
    }
    return total;
  }

  double getChapterPosition() {
    if (_activeBook == null || _chapters.isEmpty) return 0.0;
    final pos = audioHandler.playbackState.value.position.inSeconds.toDouble();
    final duration = getChapterDuration();
    if (pos > duration) return duration;
    if (pos < 0) return 0.0;
    return pos;
  }

  double getParagraphStartPos(int paragraphIndex) {
    if (_activeBook == null || _chapters.isEmpty) return 0.0;
    final chapter = _chapters[_currentChapterIndex];
    double pos = 0.0;
    for (int i = 0; i < paragraphIndex; i++) {
      pos += estimateParagraphDuration(chapter.paragraphs[i]);
    }
    return pos;
  }

  double getBookDuration() {
    if (_activeBook == null || _chapters.isEmpty) return 0.0;
    double total = 0.0;
    for (final chapter in _chapters) {
      for (final p in chapter.paragraphs) {
        total += estimateParagraphDuration(p);
      }
    }
    return total;
  }

  double getBookPosition() {
    if (_activeBook == null || _chapters.isEmpty) return 0.0;
    double pos = 0.0;
    for (int i = 0; i < _currentChapterIndex; i++) {
      final ch = _chapters[i];
      for (final p in ch.paragraphs) {
        pos += estimateParagraphDuration(p);
      }
    }
    pos += getChapterPosition();
    return pos;
  }

  String formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) return "00:00";
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    }
  }

  String get chapterProgressTimeStr => "${formatDuration(getChapterPosition())} / ${formatDuration(getChapterDuration())}";
  String get bookProgressTimeStr => "${formatDuration(getBookPosition())} / ${formatDuration(getBookDuration())}";
}
