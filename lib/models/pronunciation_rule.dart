import 'package:isar/isar.dart';

part 'pronunciation_rule.g.dart';

@collection
class PronunciationRule {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String target;       // Từ hoặc cụm từ gốc cần sửa (ví dụ: 'ko')

  late String replacement;  // Từ thay thế (ví dụ: 'không')

  bool isRegex = false;     // Có áp dụng Regex khi tìm kiếm thay thế không

  bool active = true;       // Trạng thái kích hoạt của quy tắc này
}
