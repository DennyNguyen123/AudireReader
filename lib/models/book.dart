import 'package:isar/isar.dart';

part 'book.g.dart';

@collection
class Book {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String title;
  late String author;
  String? coverPath;
  late int totalChapters;
  late DateTime dateAdded;

  // Reading status: 'unread', 'reading', 'completed'
  String status = 'unread';

  // Tags/Collections for classification
  List<String> tags = [];
}
