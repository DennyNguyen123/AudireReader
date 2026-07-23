import 'package:isar/isar.dart';

part 'highlight.g.dart';

@collection
class Highlight {
  Id id = Isar.autoIncrement;

  @Index()
  late String bookUuid;

  late int chapterIndex;
  late int paragraphIndex;

  int? startOffset; // Vị trí bắt đầu của highlight trong đoạn văn (nếu có)
  int? endOffset; // Vị trí kết thúc của highlight trong đoạn văn (nếu có)

  late String text; // Nội dung văn bản được highlight
  late String colorHex; // Mã màu hex để bôi màu nền (ví dụ: '#FFEB3B')
  String? note; // Ghi chú đính kèm đoạn highlight
  late DateTime dateAdded;
}
