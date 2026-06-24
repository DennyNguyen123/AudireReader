import '../../models/bgm_track.dart';
import '../../core/database/database_helper.dart';
import 'bgm_provider.dart';

class LocalBgmProvider implements BgmProvider {
  @override
  String get id => 'local';

  @override
  String get name => 'Thư viện máy (Local)';

  @override
  Future<List<BgmTrack>> fetchTracks() async {
    final db = await DatabaseHelper.getInstance();
    final tracks = await db.getAllBgmTracks();
    // Return only local tracks from database
    return tracks.where((t) => t.sourceType == 'local').toList();
  }
}
