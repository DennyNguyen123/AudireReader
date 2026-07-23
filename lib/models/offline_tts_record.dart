import 'package:isar/isar.dart';

part 'offline_tts_record.g.dart';

@collection
class OfflineTtsRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late String bookUuid;

  @Index()
  late int chapterIndex;

  late String ttsProvider;
  late String voiceName;
  late double speechRate;

  bool isCompleted = false;
  int totalParagraphs = 0;
  int downloadedParagraphs = 0;

  int totalSizeBytes = 0;
  late DateTime downloadedAt;

  // Composite index key helper
  @Index(unique: true, replace: true)
  String get bookChapterKey => '${bookUuid}_$chapterIndex';
  set bookChapterKey(String value) {}
}
