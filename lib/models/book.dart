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
}
