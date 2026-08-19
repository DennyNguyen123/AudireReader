import 'package:flutter/foundation.dart';
import '../utils/path_helper.dart';
import 'package:audire_reader/src/rust/api/models.dart';
import 'package:audire_reader/src/rust/api/database.dart' as rust_db;
import '../utils/device_helper.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;

  DatabaseHelper._();

  static Future<DatabaseHelper> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseHelper._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    // Rust SQLite database is initialized in main() via rust_db.initDatabase
  }

  // --- Book Operations ---
  Future<void> saveBook(Book book) async {
    await rust_db.insertBook(book: book);
  }

  Future<List<Book>> getAllBooks() async {
    return await rust_db.getAllBooks();
  }

  Future<List<String>> getAllBookTags() async {
    final books = await rust_db.getAllBooks();
    final Set<String> tags = {};
    for (final book in books) {
      tags.addAll(book.tags);
    }
    return tags.toList();
  }

  Future<List<Book>> getBooks({
    String? tag,
    String? status,
    String sortBy = 'dateAdded',
  }) async {
    return await rust_db.getBooksFiltered(
      tag: tag,
      status: status,
      sortBy: sortBy,
    );
  }

  Future<Book?> getBookByUuid(String uuid) async {
    return await rust_db.getBookByUuid(uuid: uuid);
  }

  Future<void> deleteBook(String uuid) async {
    try {
      final appDir = await PathHelper.getAppDirectory();
      await rust_db.deleteBookCascade(uuid: uuid, baseDir: appDir.path);
    } catch (e) {
      debugPrint('[DatabaseHelper] Error deleting book cascade: $e');
    }
  }

  Future<void> vacuum() async {
    try {
      await rust_db.vacuumDatabase();
    } catch (e) {
      debugPrint('[DatabaseHelper] Vacuum DB error: $e');
    }
  }

  // --- Chapter Operations ---
  Future<void> saveChapters(List<Chapter> chapters) async {
    await rust_db.insertChapters(chapters: chapters);
  }

  Future<List<Chapter>> getChapterHeaders(String bookUuid) async {
    return await rust_db.getChapterHeaders(bookUuid: bookUuid);
  }

  Future<List<Chapter>> getChaptersForBook(String bookUuid) async {
    return await rust_db.getChapters(bookUuid: bookUuid);
  }

  Future<Chapter?> getChapter(String bookUuid, int chapterIndex) async {
    return await rust_db.getChapter(bookUuid: bookUuid, chapterIndex: chapterIndex);
  }

  // --- Reading Progress Operations ---
  Future<void> saveProgress(ReadingProgress progress) async {
    await rust_db.saveReadingProgress(progress: progress);
  }

  Future<ReadingProgress?> getProgress(String bookUuid) async {
    return await rust_db.getReadingProgress(bookUuid: bookUuid);
  }

  Future<List<ReadingProgress>> getAllReadingProgress() async {
    return await rust_db.getAllReadingProgress();
  }

  // --- App Settings Operations ---
  Future<void> saveSettings(AppSettings settings) async {
    await rust_db.saveSettings(settings: settings);
  }

  Future<AppSettings> getSettings() async {
    final settings = await rust_db.getSettings();
    if (settings != null) {
      bool needSave = false;
      String? devId = settings.deviceId;
      String? devName = settings.deviceName;
      int concurrency = settings.ttsDownloadConcurrency;

      if (devId == null || devName == null) {
        devId ??= DeviceHelper.generateDeviceId();
        devName ??= DeviceHelper.getDefaultDeviceName();
        needSave = true;
      }
      if (concurrency < 1 || concurrency > 100) {
        concurrency = 3;
        needSave = true;
      }

      final updated = settings.copyWith(
        deviceId: devId,
        deviceName: devName,
        ttsDownloadConcurrency: concurrency,
      );

      if (needSave) {
        await saveSettings(updated);
      }
      return updated;
    } else {
      final defaultSet = defaultAppSettings(
        deviceId: DeviceHelper.generateDeviceId(),
        deviceName: DeviceHelper.getDefaultDeviceName(),
      );
      await saveSettings(defaultSet);
      return defaultSet;
    }
  }

  // --- Pronunciation Rule Operations ---
  Future<void> savePronunciationRule(PronunciationRule rule) async {
    await rust_db.savePronunciationRule(rule: rule);
  }

  Future<List<PronunciationRule>> getAllPronunciationRules() async {
    return await rust_db.getPronunciationRules();
  }

  Future<List<PronunciationRule>> getActivePronunciationRules() async {
    final rules = await rust_db.getPronunciationRules();
    return rules.where((r) => r.active).toList();
  }

  Future<void> deletePronunciationRule(int id) async {
    await rust_db.deletePronunciationRule(id: id);
  }

  // --- Bookmark Operations ---
  Future<void> saveBookmark(Bookmark bookmark) async {
    await rust_db.addBookmark(bookmark: bookmark);
  }

  Future<List<Bookmark>> getBookmarksForBook(String bookUuid) async {
    final bookmarks = await rust_db.getBookmarks(bookUuid: bookUuid);
    bookmarks.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return bookmarks;
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    return await rust_db.getAllBookmarks();
  }

  Future<Bookmark?> getBookmarkAt(
    String bookUuid,
    int chapterIndex,
    int paragraphIndex,
  ) async {
    final bookmarks = await rust_db.getBookmarks(bookUuid: bookUuid);
    for (var b in bookmarks) {
      if (b.chapterIndex == chapterIndex && b.paragraphIndex == paragraphIndex) {
        return b;
      }
    }
    return null;
  }

  Future<void> deleteBookmark(int id) async {
    await rust_db.deleteBookmark(id: id);
  }

  Future<void> deleteBookmarkAt(
    String bookUuid,
    int chapterIndex,
    int paragraphIndex,
  ) async {
    final b = await getBookmarkAt(bookUuid, chapterIndex, paragraphIndex);
    if (b != null && b.id != null) {
      await rust_db.deleteBookmark(id: b.id!.toInt());
    }
  }

  // --- Highlight Operations ---
  Future<void> saveHighlight(Highlight highlight) async {
    await rust_db.addHighlight(highlight: highlight);
  }

  Future<List<Highlight>> getHighlightsForBook(String bookUuid) async {
    final highlights = await rust_db.getHighlights(bookUuid: bookUuid);
    highlights.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return highlights;
  }

  Future<List<Highlight>> getAllHighlights() async {
    return await rust_db.getAllHighlights();
  }

  Future<Highlight?> getHighlightAt(
    String bookUuid,
    int chapterIndex,
    int paragraphIndex,
  ) async {
    final list = await rust_db.getHighlights(bookUuid: bookUuid);
    for (var h in list) {
      if (h.chapterIndex == chapterIndex && h.paragraphIndex == paragraphIndex) {
        return h;
      }
    }
    return null;
  }

  Future<void> deleteHighlight(int id) async {
    await rust_db.deleteHighlight(id: id);
  }

  Future<void> deleteHighlightAt(
    String bookUuid,
    int chapterIndex,
    int paragraphIndex,
  ) async {
    final h = await getHighlightAt(bookUuid, chapterIndex, paragraphIndex);
    if (h != null && h.id != null) {
      await rust_db.deleteHighlight(id: h.id!.toInt());
    }
  }

  // --- Background Music (BGM) Track Operations ---
  Future<void> saveBgmTrack(BgmTrack track) async {
    await rust_db.addBgmTrack(track: track);
  }

  Future<List<BgmTrack>> getAllBgmTracks() async {
    final tracks = await rust_db.getBgmTracks();
    tracks.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return tracks;
  }

  Future<BgmTrack?> getBgmTrack(int id) async {
    final tracks = await rust_db.getBgmTracks();
    for (var t in tracks) {
      if (t.id != null && t.id == id) return t;
    }
    return null;
  }

  Future<void> deleteBgmTrack(int id) async {
    await rust_db.deleteBgmTrack(id: id);
  }

  // --- Offline TTS Record Operations ---
  Future<void> saveOfflineTtsRecord(OfflineTtsRecord record) async {
    await rust_db.saveOfflineTtsRecord(record: record);
  }

  Future<OfflineTtsRecord?> getOfflineTtsRecord(
    String bookUuid,
    int chapterIndex,
  ) async {
    return await rust_db.getOfflineTtsRecord(bookUuid: bookUuid, chapterIndex: chapterIndex);
  }

  Future<List<OfflineTtsRecord>> getOfflineTtsRecordsForBook(
    String bookUuid,
  ) async {
    final records = await rust_db.getOfflineTtsRecords(bookUuid: bookUuid);
    records.sort((a, b) => a.chapterIndex.compareTo(b.chapterIndex));
    return records;
  }

  Future<void> deleteOfflineTtsRecord(String bookUuid, int chapterIndex) async {
    await rust_db.deleteOfflineTtsRecord(bookUuid: bookUuid, chapterIndex: chapterIndex);
  }

  Future<void> deleteOfflineTtsRecordsForBook(String bookUuid) async {
    await rust_db.deleteOfflineTtsRecordsForBook(bookUuid: bookUuid);
  }
}

AppSettings defaultAppSettings({String? deviceId, String? deviceName}) {
  return AppSettings(
    id: 1,
    fontSize: 18.0,
    speechRate: 0.5,
    selectedVoiceName: null,
    selectedVoiceLocale: null,
    ttsProvider: 'system',
    openAiTtsEndpoint: 'https://api.openai.com/v1',
    openAiTtsApiKey: '',
    openAiTtsModel: 'tts-1',
    ttsDownloadConcurrency: 3,
    fontFamily: 'System',
    themeMode: 'System',
    appLocale: 'en',
    lineHeight: 1.6,
    paragraphSpacing: 14.0,
    paragraphIndent: 0.0,
    textAlignment: 'left',
    sideMargin: 20.0,
    customBackgroundColor: null,
    customTextColor: null,
    primaryColorHex: null,
    webDavEnabled: false,
    webDavAutoSync: true,
    webDavUrl: '',
    webDavUsername: '',
    webDavLastSync: null,
    deviceId: deviceId,
    deviceName: deviceName,
    openLastReadOnLaunch: false,
    hotkeyNextParagraph: 'Arrow Down',
    hotkeyPrevParagraph: 'Arrow Up',
    hotkeyNextChapter: 'Control+Arrow Right',
    hotkeyPrevChapter: 'Control+Arrow Left',
    hotkeyPlayPauseTts: 'Space',
    hotkeyOpenChapter: 'Control+o',
    hotkeyOpenSetting: 'Control+comma',
    hotkeyBossKey: 'Control+b',
    bossKeyAction: 'minimize',
    autoCheckUpdate: true,
    bgmEnabled: false,
    bgmVolume: 0.15,
    currentBgmTrackId: null,
    currentBgmTrackUrl: null,
    currentBgmTrackName: null,
    bgmLoopMode: 'all',
    bgmProviderId: 'local',
    lastLocalTrackUrl: null,
    lastRadioTrackUrl: null,
    lastRadioTrackName: null,
    lastLofiTrackUrl: null,
    lastLofiTrackName: null,
    sortBy: 'dateAdded',
    showAssistiveButton: false,
    assistiveButtonX: -1.0,
    assistiveButtonY: -1.0,
    assistiveSingleTapAction: 'nextParagraph',
    assistiveDoubleTapAction: 'prevParagraph',
    assistiveLongPressAction: 'playPause',
    developerMode: false,
    enableDebugLogs: false,
    enableWebDavDebug: false,
    audioPanelCollapsed: false,
    libraryViewMode: 'grid',
    searchHistory: const [],
  );
}

