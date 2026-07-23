import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/bgm_track.dart';
import 'bgm_provider.dart';
import '../logger_service.dart';

class RadioBrowserProvider implements BgmProvider {
  @override
  String get id => 'radio_browser';

  @override
  String get name => 'Internet Radio (Lofi)';

  @override
  Future<List<BgmTrack>> fetchTracks() async {
    // API endpoint for fetching popular lofi stations
    final url = Uri.parse(
      'https://de1.api.radio-browser.info/json/stations/search?tag=lofi&limit=20&order=votes&reverse=true&hidebroken=true',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) {
              final track = BgmTrack();
              final url = json['url_resolved'] ?? json['url'];
              track.id = url.hashCode.abs();
              track.name = json['name']?.toString().trim() ?? 'Unknown Station';
              track.sourceType = 'radio';
              track.sourcePath = url;
              track.dateAdded = DateTime.now();
              return track;
            })
            .where((track) => track.sourcePath.isNotEmpty)
            .toList();
      } else {
        LoggerService().log(
          "RadioBrowser fetch failed: ${response.statusCode}",
          tag: 'RadioBrowserProvider',
          level: LogLevel.error,
        );
        return [];
      }
    } catch (e) {
      LoggerService().log(
        "RadioBrowser error",
        tag: 'RadioBrowserProvider',
        level: LogLevel.error,
        error: e.toString(),
      );
      return [];
    }
  }

  Future<List<BgmTrack>> searchTracks(String query) async {
    if (query.trim().isEmpty) {
      return fetchTracks();
    }

    // API endpoint for searching stations by name
    final url = Uri.parse(
      'https://de1.api.radio-browser.info/json/stations/search?name=${Uri.encodeComponent(query)}&limit=20&order=votes&reverse=true&hidebroken=true',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) {
              final track = BgmTrack();
              final url = json['url_resolved'] ?? json['url'];
              track.id = url.hashCode.abs();
              track.name = json['name']?.toString().trim() ?? 'Unknown Station';
              track.sourceType = 'radio';
              track.sourcePath = url;
              track.dateAdded = DateTime.now();
              return track;
            })
            .where((track) => track.sourcePath.isNotEmpty)
            .toList();
      } else {
        LoggerService().log(
          "RadioBrowser search failed: ${response.statusCode}",
          tag: 'RadioBrowserProvider',
          level: LogLevel.error,
        );
        return [];
      }
    } catch (e) {
      LoggerService().log(
        "RadioBrowser search error",
        tag: 'RadioBrowserProvider',
        level: LogLevel.error,
        error: e.toString(),
      );
      return [];
    }
  }
}
