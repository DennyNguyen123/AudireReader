import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

abstract class EdgeTtsChunk {}

class EdgeAudioChunk extends EdgeTtsChunk {
  final List<int> data;
  EdgeAudioChunk(this.data);
}

class EdgeMetadataChunk extends EdgeTtsChunk {
  final String type;
  final int offset;
  final int duration;
  final String text;

  EdgeMetadataChunk({
    required this.type,
    required this.offset,
    required this.duration,
    required this.text,
  });
}

class EdgeTtsService {
  static const String trustedClientToken = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
  static const String baseUri = "speech.platform.bing.com/consumer/speech/synthesize/readaloud";
  static const String voiceListUrl = "https://$baseUri/voices/list?trustedclienttoken=$trustedClientToken";

  static double _clockSkewSeconds = 0.0;
  
  static final HttpClient _client = HttpClient()..userAgent = null;
  static const chromiumFullVersion = "143.0.3650.75";
  static final chromiumMajorVersion = chromiumFullVersion.split(".")[0];

  static Future<void>? _currentRequest;
  static StreamController<EdgeTtsChunk>? _currentController;

  static DateTime? _parseRfc2616Date(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length < 5) return null;
      final day = int.parse(parts[1]);
      final monthStr = parts[2];
      final year = int.parse(parts[3]);
      final timeParts = parts[4].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
      };
      final month = months[monthStr];
      if (month == null) return null;
      return DateTime.utc(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  static Future<void> adjustClockSkew() async {
    try {
      final url = Uri.parse(voiceListUrl);
      final response = await http.head(
        url,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromiumMajorVersion.0.0.0 Safari/537.36 Edg/$chromiumMajorVersion.0.0.0",
        },
      ).timeout(const Duration(seconds: 3));
      final serverDateHeader = response.headers['date'];
      if (serverDateHeader != null) {
        final serverTime = _parseRfc2616Date(serverDateHeader);
        if (serverTime != null) {
          final clientTime = DateTime.now().toUtc();
          final diffMs = serverTime.difference(clientTime).inMilliseconds;
          _clockSkewSeconds = diffMs / 1000.0;
        }
      }
    } catch (e) {
      print("EdgeTtsService: Failed to adjust clock skew: $e");
    }
  }

  static String generateSecMsGec() {
    const int winEpoch = 11644473600;
    double unixTimestamp = DateTime.now().toUtc().millisecondsSinceEpoch / 1000.0;
    unixTimestamp += _clockSkewSeconds;
    int ticks = unixTimestamp.toInt() + winEpoch;
    ticks -= ticks % 300;
    int intervalTicks = ticks * 10000000;
    final strToHash = "$intervalTicks$trustedClientToken";
    final bytes = utf8.encode(strToHash);
    return sha256.convert(bytes).toString().toUpperCase();
  }

  static String generateUuid() {
    final random = Random();
    final hexDigits = '0123456789abcdef';
    String hex(int length) => List.generate(length, (_) => hexDigits[random.nextInt(16)]).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-${hexDigits[8 + random.nextInt(4)]}${hex(3)}-${hex(12)}';
  }

  static Future<List<Map<String, dynamic>>> listVoices() async {
    try {
      final url = Uri.parse(voiceListUrl);
      final response = await http.get(
        url,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromiumMajorVersion.0.0.0 Safari/537.36 Edg/$chromiumMajorVersion.0.0.0",
          "Accept-Encoding": "gzip, deflate, br, zstd",
          "Accept-Language": "en-US,en;q=0.9",
          "Accept": "*/*",
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data.map((item) => Map<String, dynamic>.from(item)));
      } else {
        throw Exception("Failed to fetch Edge TTS voices: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching Edge TTS voices: $e");
      return [];
    }
  }

  static String convertRate(double speechRate) {
    final percentage = ((speechRate - 0.5) / 0.5 * 100).round();
    return percentage >= 0 ? "+$percentage%" : "$percentage%";
  }

  static Map<String, String> parseHeaders(String text) {
    final Map<String, String> headers = {};
    for (final line in text.split('\r\n')) {
      if (line.contains(':')) {
        final parts = line.split(':');
        headers[parts[0].trim()] = parts.sublist(1).join(':').trim();
      }
    }
    return headers;
  }

  static List<String> _splitText(String text, {int maxBytes = 3500}) {
    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      int end = start + maxBytes;
      if (end >= text.length) {
        chunks.add(text.substring(start));
        break;
      }
      int breakPoint = -1;
      for (final punc in ['.', '!', '?', '\\n', ',', ';']) {
        final idx = text.lastIndexOf(punc, end);
        if (idx > start) {
          if (idx > breakPoint) breakPoint = idx;
        }
      }
      if (breakPoint == -1) {
        final idx = text.lastIndexOf(' ', end);
        breakPoint = idx > start ? idx : end;
      } else {
        breakPoint++; 
      }
      chunks.add(text.substring(start, breakPoint).trim());
      start = breakPoint;
    }
    return chunks.where((s) => s.isNotEmpty).toList();
  }

  

  static Stream<EdgeTtsChunk> synthesize({
    required String text,
    required String voice,
    double rate = 0.5,
    double pitch = 1.0,
  }) async* {
    while (_currentRequest != null) {
      await _currentRequest;
    }

    final completer = Completer<void>();
    _currentRequest = completer.future;

    try {
      final rateStr = convertRate(rate);
      final chunksText = _splitText(text);
      int offsetAccumulator = 0;

      for (final chunkText in chunksText) {
        // Wait 500ms between WebSocket connections to prevent rate limit
        if (offsetAccumulator > 0) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        final secMsGec = generateSecMsGec();
        final connectionId = generateUuid().replaceAll('-', '');
        final wsUrlStr = "wss://$baseUri/edge/v1?TrustedClientToken=$trustedClientToken&ConnectionId=$connectionId&Sec-MS-GEC=$secMsGec&Sec-MS-GEC-Version=1-$chromiumFullVersion";
        
        WebSocket? ws;
        try {
          ws = await WebSocket.connect(
            wsUrlStr,
            headers: {
              "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromiumMajorVersion.0.0.0 Safari/537.36 Edg/$chromiumMajorVersion.0.0.0",
              "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
            },
            customClient: _client,
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          await adjustClockSkew();
          final newSecMsGec = generateSecMsGec();
          final newWsUrlStr = "wss://$baseUri/edge/v1?TrustedClientToken=$trustedClientToken&ConnectionId=$connectionId&Sec-MS-GEC=$newSecMsGec&Sec-MS-GEC-Version=1-$chromiumFullVersion";
          ws = await WebSocket.connect(
            newWsUrlStr,
            headers: {
              "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromiumMajorVersion.0.0.0 Safari/537.36 Edg/$chromiumMajorVersion.0.0.0",
              "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
            },
            customClient: _client,
          ).timeout(const Duration(seconds: 10));
        }

        _currentController = StreamController<EdgeTtsChunk>();

        ws.listen((message) {
          if (_currentController == null || _currentController!.isClosed) return;

          if (message is String) {
            final splitIndex = message.indexOf("\r\n\r\n");
            if (splitIndex == -1) return;
            final headersText = message.substring(0, splitIndex);
            final bodyText = message.substring(splitIndex + 4);
            final headers = parseHeaders(headersText);
            final path = headers["Path"];

            if (path == "audio.metadata") {
              try {
                final Map<String, dynamic> json = jsonDecode(bodyText);
                final List<dynamic>? metadata = json["Metadata"];
                if (metadata != null) {
                  for (final item in metadata) {
                    if (item["Type"] == "WordBoundary") {
                      final dataObj = item["Data"];
                      _currentController!.add(EdgeMetadataChunk(
                        type: "WordBoundary",
                        offset: (dataObj["Offset"] as int) ~/ 10000,
                        duration: (dataObj["Duration"] as int) ~/ 10000,
                        text: dataObj["text"]["Text"] as String,
                      ));
                    }
                  }
                }
              } catch (_) {}
            } else if (path == "turn.end") {
              _currentController!.close();
            }
          } else if (message is List<int>) {
            if (message.length < 2) return;
            final headerLength = (message[0] << 8) | message[1];
            if (headerLength > message.length - 2) return;
            final headerBytes = message.sublist(2, 2 + headerLength);
            final headers = parseHeaders(utf8.decode(headerBytes));
            if (headers["Path"] == "audio") {
              final audioData = message.sublist(2 + headerLength);
              if (audioData.isNotEmpty) {
                _currentController!.add(EdgeAudioChunk(audioData));
              }
            }
          }
        }, onDone: () {
          if (_currentController != null && !_currentController!.isClosed) {
            _currentController!.addError(Exception("WebSocket disconnected unexpectedly"));
            _currentController!.close();
          }
        }, onError: (err) {
          if (_currentController != null && !_currentController!.isClosed) {
            _currentController!.addError(err);
            _currentController!.close();
          }
        });

        final now = DateTime.now().toUtc();
        final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        final weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
        String pad(int n) => n.toString().padLeft(2, '0');
        final jsDateStr = "${weekdays[now.weekday - 1]} ${months[now.month - 1]} ${pad(now.day)} ${now.year} ${pad(now.hour)}:${pad(now.minute)}:${pad(now.second)} GMT+0000 (Coordinated Universal Time)";

        final configMsg =
            "X-Timestamp:$jsDateStr\r\n"
            "Content-Type:application/json; charset=utf-8\r\n"
            "Path:speech.config\r\n\r\n"
            '{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"true"},"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}';
        ws.add(configMsg);

        final escapedText = chunkText
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&apos;');

        final ssml =
            "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>"
            "<voice name='$voice'>"
            "<prosody rate='$rateStr' pitch='+0Hz' volume='+0%'>"
            "$escapedText"
            "</prosody>"
            "</voice>"
            "</speak>";

        final requestId = generateUuid().replaceAll('-', '');
        final ssmlMsg =
            "X-RequestId:$requestId\r\n"
            "Content-Type:application/ssml+xml\r\n"
            "X-Timestamp:${jsDateStr}Z\r\n"
            "Path:ssml\r\n\r\n"
            "$ssml";
        ws.add(ssmlMsg);

        int currentMaxOffset = 0;
        int currentMaxDuration = 0;

        try {
          await for (final chunk in _currentController!.stream) {
            if (chunk is EdgeMetadataChunk) {
              if (chunk.offset > currentMaxOffset) {
                currentMaxOffset = chunk.offset;
                currentMaxDuration = chunk.duration;
              }
              yield EdgeMetadataChunk(
                type: chunk.type,
                offset: chunk.offset + offsetAccumulator,
                duration: chunk.duration,
                text: chunk.text,
              );
            } else {
              yield chunk;
            }
          }
        } finally {
          ws.close();
        }

        offsetAccumulator += currentMaxOffset + currentMaxDuration;
      }
    } finally {
      completer.complete();
      if (_currentRequest == completer.future) {
        _currentRequest = null;
      }
      _currentController = null;
    }
  }
}
