import 'package:isar/isar.dart';

part 'chapter.g.dart';

@collection
class Chapter {
  Id id = Isar.autoIncrement;

  @Index()
  late String bookUuid;

  late int chapterIndex;
  late String title;
  
  // Lưu trữ danh sách đoạn văn giúp tối ưu hóa việc phân tách và highlight từng đoạn khi TTS đọc
  late List<String> paragraphs;
}
