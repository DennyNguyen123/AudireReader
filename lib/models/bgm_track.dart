import 'package:isar/isar.dart';

part 'bgm_track.g.dart';

@collection
class BgmTrack {
  Id id = Isar.autoIncrement;

  late String name; // Tên hiển thị bài nhạc nền
  late String sourceType; // 'youtube', 'direct_url', 'local'
  late String sourcePath; // ID video youtube, link stream hoặc đường dẫn file cục bộ
  
  DateTime dateAdded = DateTime.now();
}
