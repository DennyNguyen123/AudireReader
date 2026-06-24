import 'package:flutter_test/flutter_test.dart';
import 'package:audire_reader/services/bgm/radio_browser_provider.dart';

void main() {
  group('RadioBrowserProvider Tests', () {
    late RadioBrowserProvider provider;

    setUp(() {
      provider = RadioBrowserProvider();
    });

    test('Provider ID and Name are correct', () {
      expect(provider.id, 'radio_browser');
      expect(provider.name, 'Internet Radio (Lofi)');
    });

    test('fetchTracks returns a list of BgmTrack with valid stream URLs', () async {
      // Act
      final tracks = await provider.fetchTracks();

      // Assert
      expect(tracks, isNotNull);
      // It might be empty if there's a network issue during the test, 
      // but assuming the network is fine, it should return some tracks.
      if (tracks.isNotEmpty) {
        expect(tracks.length, lessThanOrEqualTo(20)); // because we set limit=20

        for (final track in tracks) {
          expect(track.sourceType, 'radio');
          expect(track.name, isNotEmpty);
          expect(track.sourcePath, isNotEmpty);
          expect(track.sourcePath.startsWith('http'), isTrue, reason: 'URL should start with http or https');
        }
      } else {
        // Warning if empty, though could happen in CI without internet
        print('Warning: RadioBrowser returned empty list. Check internet connection.');
      }
    });
  });
}
