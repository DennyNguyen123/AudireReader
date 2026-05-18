import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../models/progress.dart';

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
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [BookSchema, ChapterSchema, ReadingProgressSchema],
      directory: dir.path,
    );
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
}
