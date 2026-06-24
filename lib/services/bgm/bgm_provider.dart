import '../../models/bgm_track.dart';

abstract class BgmProvider {
  String get id;
  String get name;
  
  /// Fetches the list of tracks or stations from this provider.
  Future<List<BgmTrack>> fetchTracks();
}
