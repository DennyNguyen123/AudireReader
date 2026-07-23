import 'package:isar/isar.dart';

part 'bookmark.g.dart';

@collection
class Bookmark {
  Id id = Isar.autoIncrement;

  @Index()
  late String bookUuid;

  late int chapterIndex;
  late int paragraphIndex;

  late String contentSnippet; // Đoạn text ngắn để hiển thị trên danh sách
  late DateTime dateAdded;
}
