import 'package:isar/isar.dart';

part 'progress.g.dart';

@collection
class ReadingProgress {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String bookUuid;

  late int currentChapterIndex;
  late int currentParagraphIndex;
  late int currentCharacterOffset;
  late DateTime lastRead;
}
