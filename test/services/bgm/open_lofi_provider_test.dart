import 'package:flutter_test/flutter_test.dart';
import 'package:audire_reader/services/bgm/open_lofi_provider.dart';

void main() {
  group('OpenLofiProvider Tests', () {
    late OpenLofiProvider provider;

    setUp(() {
      provider = OpenLofiProvider();
    });

    test('Provider ID and Name are correct', () {
      expect(provider.id, 'open_lofi');
      expect(provider.name, 'Lofi Playlist (Online)');
    });

    test('fetchTracks returns hardcoded list of valid BgmTrack', () async {
      // Act
      final tracks = await provider.fetchTracks();

      // Assert
      expect(tracks, isNotEmpty);
      expect(tracks.length, 3); // Currently hardcoded to 3 tracks

      for (final track in tracks) {
        expect(track.sourceType, 'openlofi');
        expect(track.name, isNotEmpty);
        expect(track.sourcePath, isNotEmpty);
        expect(track.sourcePath.startsWith('http'), isTrue);
      }
    });
  });
}
