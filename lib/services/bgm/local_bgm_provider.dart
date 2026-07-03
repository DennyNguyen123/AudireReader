import '../../models/bgm_track.dart';
import '../../core/database/database_helper.dart';
import 'bgm_provider.dart';

class LocalBgmProvider implements BgmProvider {
  @override
  String get id => 'local';

  @override
  String get name => 'Thư viện của tôi (Local & Link)';

  @override
  Future<List<BgmTrack>> fetchTracks() async {
    final db = await DatabaseHelper.getInstance();
    final tracks = await db.getAllBgmTracks();
    // Trả về cả các track có sourceType là local hoặc direct_url
    return tracks.where((t) => t.sourceType == 'local' || t.sourceType == 'direct_url').toList();
  }
}
