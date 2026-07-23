import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import '../utils/path_helper.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../models/progress.dart';
import '../../models/settings.dart';
import '../../models/pronunciation_rule.dart';
import '../../models/bookmark.dart';
import '../../models/highlight.dart';
import '../../models/bgm_track.dart';
import '../../models/offline_tts_record.dart';
import '../utils/device_helper.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  late Isar isar;

  DatabaseHelper._();

  static Future<DatabaseHelper> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseHelper._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final dir = await PathHelper.getAppDirectory();
    try {
      isar = await _openIsar(dir.path);
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseHelper] Error opening Isar DB: $e. Recreating database...');
      // Xóa tất cả các file liên quan đến Isar DB cũ bị lỗi Schema
      final directory = Directory(dir.path);
      if (await directory.exists()) {
        final files = directory.listSync();
        for (final file in files) {
          final name = p.basename(file.path);
          if (file is File && (name.endsWith('.isar') || name.contains('isar_lock'))) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
      isar = await _openIsar(dir.path);
    }
    await _migrateBookCoversPath(dir.path);
  }

  Future<Isar> _openIsar(String path) async {
    return await Isar.open(
      [
        BookSchema,
        ChapterSchema,
        ReadingProgressSchema,
        AppSettingsSchema,
        PronunciationRuleSchema,
        BookmarkSchema,
        HighlightSchema,
        BgmTrackSchema,
        OfflineTtsRecordSchema,
      ],
      directory: path,
    );
  }

  Future<void> _migrateBookCoversPath(String newAppDirPath) async {
    try {
      final books = await isar.books.where().findAll();
      final List<Book> booksToUpdate = [];
      for (final book in books) {
        final path = book.coverPath;
        if (path != null && path.isNotEmpty) {
          final fileName = p.basename(path);
          final newPath = p.join(newAppDirPath, 'covers', fileName);
          final fileExists = File(newPath).existsSync();
          // ignore: avoid_print
          print('[Migration] Book "${book.title}":\n  Old Path: $path\n  New Path: $newPath\n  File exists: $fileExists');
          
          if (path != newPath) {
            book.coverPath = newPath;
            booksToUpdate.add(book);
          }
        } else {
          // ignore: avoid_print
          print('[Migration] Book "${book.title}": coverPath is null or empty');
        }
      }
      if (booksToUpdate.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.books.putAll(booksToUpdate);
        });
        // ignore: avoid_print
        print('[Migration] Migrated ${booksToUpdate.length} book cover paths to new directory.');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[Migration] Error migrating book cover paths in database: $e');
    }
  }

  // --- Book Operations ---
  Future<void> saveBook(Book book) async {
    await isar.writeTxn(() async {
      await isar.books.put(book);
    });
  }

  Future<List<Book>> getAllBooks() async {
    return await isar.books.where().sortByDateAddedDesc().findAll();
  }

  Future<List<String>> getAllBookTags() async {
    final books = await getAllBooks();
    final Set<String> tags = {};
    for (final book in books) {
      tags.addAll(book.tags);
    }
    return tags.toList();
  }

  Future<List<Book>> getBooks({String? tag, String? status, String sortBy = 'dateAdded'}) async {
    var query = isar.books.where();
    List<Book> books;
    
    if (sortBy == 'title') {
      books = await query.sortByTitle().findAll();
    } else if (sortBy == 'author') {
      books = await query.sortByAuthor().findAll();
    } else {
      // Mặc định sort theo ngày thêm
      books = await query.sortByDateAddedDesc().findAll();
    }

    // Lọc theo tag
    if (tag != null && tag != 'All') {
      books = books.where((b) => b.tags.contains(tag)).toList();
    }
    
    // Lọc theo status
    if (status != null && status != 'All') {
      books = books.where((b) {
        final bStatus = b.status.trim().isEmpty ? 'unread' : b.status;
        return bStatus.toLowerCase() == status.toLowerCase();
      }).toList();
    }

    // Sắp xếp theo recentlyRead
    if (sortBy == 'recentlyRead') {
      final progressList = await isar.readingProgress.where().sortByLastReadDesc().findAll();
      final progressMap = {for (var p in progressList) p.bookUuid: p.lastRead};
      books.sort((a, b) {
        final timeA = progressMap[a.uuid] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = progressMap[b.uuid] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA); // Sách đọc gần đây nhất xếp lên đầu
      });
    }

    return books;
  }

  Future<Book?> getBookByUuid(String uuid) async {
    return await isar.books.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<void> deleteBook(String uuid) async {
    final book = await getBookByUuid(uuid);
    if (book != null) {
      // 1. Xóa ảnh bìa của sách nếu có
      if (book.coverPath != null && book.coverPath!.isNotEmpty) {
        try {
          final file = File(book.coverPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // ignore: avoid_print
          print('[DatabaseHelper] Error deleting physical cover file: $e');
        }
      }

      // Xóa các file TTS offline của sách
      try {
        final appDir = await PathHelper.getAppDirectory();
        final ttsDir = Directory(p.join(appDir.path, 'tts_offline', uuid));
        if (await ttsDir.exists()) {
          await ttsDir.delete(recursive: true);
        }
      } catch (e) {
        // ignore: avoid_print
        print('[DatabaseHelper] Error deleting offline TTS directory: $e');
      }

      // 2. Xóa các bản ghi liên quan trong DB
      await isar.writeTxn(() async {
        // Delete all chapters
        await isar.chapters.filter().bookUuidEqualTo(uuid).deleteAll();
        // Delete progress
        await isar.readingProgress.filter().bookUuidEqualTo(uuid).deleteAll();
        // Delete bookmarks
        await isar.bookmarks.filter().bookUuidEqualTo(uuid).deleteAll();
        // Delete highlights
        await isar.highlights.filter().bookUuidEqualTo(uuid).deleteAll();
        // Delete offline TTS records
        await isar.offlineTtsRecords.filter().bookUuidEqualTo(uuid).deleteAll();
        // Delete book
        await isar.books.delete(book.id);
      });
    }
  }

  // --- Chapter Operations ---
  Future<void> saveChapters(List<Chapter> chapters) async {
    await isar.writeTxn(() async {
      await isar.chapters.putAll(chapters);
    });
  }

  Future<List<Chapter>> getChaptersForBook(String bookUuid) async {
    return await isar.chapters
        .filter()
        .bookUuidEqualTo(bookUuid)
        .sortByChapterIndex()
        .findAll();
  }

  Future<Chapter?> getChapter(String bookUuid, int chapterIndex) async {
    return await isar.chapters
        .filter()
        .bookUuidEqualTo(bookUuid)
        .and()
        .chapterIndexEqualTo(chapterIndex)
        .findFirst();
  }

  // --- Reading Progress Operations ---
  Future<void> saveProgress(ReadingProgress progress) async {
    await isar.writeTxn(() async {
      await isar.readingProgress.put(progress);
    });
  }

  Future<ReadingProgress?> getProgress(String bookUuid) async {
    return await isar.readingProgress
        .filter()
        .bookUuidEqualTo(bookUuid)
        .findFirst();
  }

  // --- App Settings Operations ---
  Future<void> saveSettings(AppSettings settings) async {
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  Future<AppSettings> getSettings() async {
    final settings = await isar.appSettings.get(1);
    if (settings != null) {
      bool needSave = false;
      if (settings.deviceId == null || settings.deviceName == null) {
        settings.deviceId ??= DeviceHelper.generateDeviceId();
        settings.deviceName ??= DeviceHelper.getDefaultDeviceName();
        needSave = true;
      }
      if (settings.ttsDownloadConcurrency < 1 || settings.ttsDownloadConcurrency > 10) {
        settings.ttsDownloadConcurrency = 3;
        needSave = true;
      }
      if (needSave) {
        await saveSettings(settings);
      }
      return settings;
    }
 else {
      final newSettings = AppSettings();
      newSettings.deviceId = DeviceHelper.generateDeviceId();
      newSettings.deviceName = DeviceHelper.getDefaultDeviceName();
      await saveSettings(newSettings);
      return newSettings;
    }
  }

  // --- Pronunciation Rule Operations ---
  Future<void> savePronunciationRule(PronunciationRule rule) async {
    await isar.writeTxn(() async {
      await isar.pronunciationRules.put(rule);
    });
  }

  Future<List<PronunciationRule>> getAllPronunciationRules() async {
    return await isar.pronunciationRules.where().findAll();
  }

  Future<List<PronunciationRule>> getActivePronunciationRules() async {
    return await isar.pronunciationRules.filter().activeEqualTo(true).findAll();
  }

  Future<void> deletePronunciationRule(int id) async {
    await isar.writeTxn(() async {
      await isar.pronunciationRules.delete(id);
    });
  }

  // --- Bookmark Operations ---
  Future<void> saveBookmark(Bookmark bookmark) async {
    await isar.writeTxn(() async {
      await isar.bookmarks.put(bookmark);
    });
  }

  Future<List<Bookmark>> getBookmarksForBook(String bookUuid) async {
    return await isar.bookmarks
        .filter()
        .bookUuidEqualTo(bookUuid)
        .sortByDateAddedDesc()
        .findAll();
  }

  Future<Bookmark?> getBookmarkAt(String bookUuid, int chapterIndex, int paragraphIndex) async {
    return await isar.bookmarks
        .filter()
        .bookUuidEqualTo(bookUuid)
        .and()
        .chapterIndexEqualTo(chapterIndex)
        .and()
        .paragraphIndexEqualTo(paragraphIndex)
        .findFirst();
  }

  Future<void> deleteBookmark(int id) async {
    await isar.writeTxn(() async {
      await isar.bookmarks.delete(id);
    });
  }

  Future<void> deleteBookmarkAt(String bookUuid, int chapterIndex, int paragraphIndex) async {
    await isar.writeTxn(() async {
      await isar.bookmarks
          .filter()
          .bookUuidEqualTo(bookUuid)
          .and()
          .chapterIndexEqualTo(chapterIndex)
          .and()
          .paragraphIndexEqualTo(paragraphIndex)
          .deleteAll();
    });
  }

  // --- Highlight Operations ---
  Future<void> saveHighlight(Highlight highlight) async {
    await isar.writeTxn(() async {
      await isar.highlights.put(highlight);
    });
  }

  Future<List<Highlight>> getHighlightsForBook(String bookUuid) async {
    return await isar.highlights
        .filter()
        .bookUuidEqualTo(bookUuid)
        .sortByDateAddedDesc()
        .findAll();
  }

  Future<Highlight?> getHighlightAt(String bookUuid, int chapterIndex, int paragraphIndex) async {
    return await isar.highlights
        .filter()
        .bookUuidEqualTo(bookUuid)
        .and()
        .chapterIndexEqualTo(chapterIndex)
        .and()
        .paragraphIndexEqualTo(paragraphIndex)
        .findFirst();
  }

  Future<void> deleteHighlight(int id) async {
    await isar.writeTxn(() async {
      await isar.highlights.delete(id);
    });
  }

  Future<void> deleteHighlightAt(String bookUuid, int chapterIndex, int paragraphIndex) async {
    await isar.writeTxn(() async {
      await isar.highlights
          .filter()
          .bookUuidEqualTo(bookUuid)
          .and()
          .chapterIndexEqualTo(chapterIndex)
          .and()
          .paragraphIndexEqualTo(paragraphIndex)
          .deleteAll();
    });
  }

  // --- Background Music (BGM) Track Operations ---
  Future<void> saveBgmTrack(BgmTrack track) async {
    await isar.writeTxn(() async {
      await isar.bgmTracks.put(track);
    });
  }

  Future<List<BgmTrack>> getAllBgmTracks() async {
    return await isar.bgmTracks.where().sortByDateAddedDesc().findAll();
  }

  Future<BgmTrack?> getBgmTrack(int id) async {
    return await isar.bgmTracks.get(id);
  }

  Future<void> deleteBgmTrack(int id) async {
    await isar.writeTxn(() async {
      await isar.bgmTracks.delete(id);
    });
  }

  // --- Offline TTS Record Operations ---
  Future<void> saveOfflineTtsRecord(OfflineTtsRecord record) async {
    await isar.writeTxn(() async {
      await isar.offlineTtsRecords.put(record);
    });
  }

  Future<OfflineTtsRecord?> getOfflineTtsRecord(String bookUuid, int chapterIndex) async {
    final key = '${bookUuid}_$chapterIndex';
    return await isar.offlineTtsRecords.filter().bookChapterKeyEqualTo(key).findFirst();
  }

  Future<List<OfflineTtsRecord>> getOfflineTtsRecordsForBook(String bookUuid) async {
    return await isar.offlineTtsRecords
        .filter()
        .bookUuidEqualTo(bookUuid)
        .sortByChapterIndex()
        .findAll();
  }

  Future<void> deleteOfflineTtsRecord(String bookUuid, int chapterIndex) async {
    final key = '${bookUuid}_$chapterIndex';
    await isar.writeTxn(() async {
      await isar.offlineTtsRecords.filter().bookChapterKeyEqualTo(key).deleteAll();
    });
  }

  Future<void> deleteOfflineTtsRecordsForBook(String bookUuid) async {
    await isar.writeTxn(() async {
      await isar.offlineTtsRecords.filter().bookUuidEqualTo(bookUuid).deleteAll();
    });
  }
}

