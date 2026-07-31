import 'package:audire_reader/src/rust/api/models.dart';

abstract class BgmProvider {
  String get id;
  String get name;

  /// Fetches the list of tracks or stations from this provider.
  Future<List<BgmTrack>> fetchTracks();
}
