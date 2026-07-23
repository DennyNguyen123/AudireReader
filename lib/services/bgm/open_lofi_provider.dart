import '../../models/bgm_track.dart';
import 'bgm_provider.dart';

class OpenLofiProvider implements BgmProvider {
  @override
  String get id => 'open_lofi';

  @override
  String get name => 'Lofi Playlist (Online)';

  @override
  Future<List<BgmTrack>> fetchTracks() async {
    // Return a curated list of public domain / royalty free Lofi tracks.
    // In a real scenario, this could be fetched from a JSON file on Github.
    final tracksData = [
      {
        'name': 'Lofi Chill 1 (Sample)',
        'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      },
      {
        'name': 'Lofi Study (Sample)',
        'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      },
      {
        'name': 'Ambient Lofi (Sample)',
        'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      },
    ];

    return tracksData.map((data) {
      final track = BgmTrack();
      track.id = data['url'].hashCode.abs();
      track.name = data['name']!;
      track.sourceType = 'openlofi';
      track.sourcePath = data['url']!;
      track.dateAdded = DateTime.now();
      return track;
    }).toList();
  }
}
