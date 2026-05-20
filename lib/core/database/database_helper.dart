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
    isar = await Isar.open(
      [
        BookSchema,
        ChapterSchema,
        ReadingProgressSchema,
        AppSettingsSchema,
        PronunciationRuleSchema,
        BookmarkSchema,
        HighlightSchema,
      ],
      directory: dir.path,
    );
    await _migrateBookCoversPath(dir.path);
  }

  Future<void> _migrateBookCoversPath(String newAppDirPath) async {
    try {
      final books = await isar.books.where().findAll();
      final List<Book> booksToUpdate = [];
      for (final book in books) {
        final path = book.coverPath;
        if (path != null && path.isNotEmpty) {
          final normalizedPath = path.replaceAll('\\', '/');
          final expectedPart = '/AudireReader/covers/';
          if (!normalizedPath.contains(expectedPart)) {
            final fileName = p.basename(path);
            final newPath = p.join(newAppDirPath, 'covers', fileName);
            book.coverPath = newPath;
            booksToUpdate.add(book);
          }
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
      await isar.writeTxn(() async {
        // Delete all chapters
        await isar.chapters.filter().bookUuidEqualTo(uuid).deleteAll();
        // Delete progress
        await isar.readingProgress.filter().bookUuidEqualTo(uuid).deleteAll();
        // Delete bookmarks
        await isar.bookmarks.filter().bookUuidEqualTo(uuid).deleteAll();
        // Delete highlights
        await isar.highlights.filter().bookUuidEqualTo(uuid).deleteAll();
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
    return settings ?? AppSettings();
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
}
