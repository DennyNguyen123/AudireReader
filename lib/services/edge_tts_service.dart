import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

class EdgeToken {
  final String key;
  final String token;
  final String cookie;
  EdgeToken({required this.key, required this.token, required this.cookie});
}

class EdgeTtsService {
  static const String trustedClientToken = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
  static const String baseUri = "speech.platform.bing.com/consumer/speech/synthesize/readaloud";
  static const String voiceListUrl = "https://$baseUri/voices/list?trustedclienttoken=$trustedClientToken";
  static const String _userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  static EdgeToken? _cachedToken;
  static int _tokenTime = 0;
  static const int _tokenTtl = 5 * 60 * 1000; // 5 minutes

  static Future<EdgeToken> _getToken(http.Client client) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_cachedToken != null && (now - _tokenTime < _tokenTtl)) {
      return _cachedToken!;
    }

    final res = await client.get(
      Uri.parse("https://www.bing.com/translator"),
      headers: {
        "User-Agent": _userAgent,
        "Accept-Language": "vi,en-US;q=0.9,en;q=0.8",
        "Connection": "close",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Bing translator fetch failed: ${res.statusCode}");
    }

    // Extract cookies
    final rawCookies = res.headers['set-cookie'];
    String cookie = "";
    if (rawCookies != null) {
      final parts = rawCookies.split(',');
      final list = parts.map((c) => c.split(';')[0]).toList();
      cookie = list.join('; ');
    }

    final html = res.body;
    final regex = RegExp(r'params_AbusePreventionHelper\s*=\s*\[([^,]+),([^,]+),');
    final match = regex.firstMatch(html);

    if (match == null) {
      throw Exception("Failed to parse Bing token");
    }

    final key = match.group(1)!;
    final token = match.group(2)!.replaceAll('"', '');

    _cachedToken = EdgeToken(key: key, token: token, cookie: cookie);
    _tokenTime = now;
    return _cachedToken!;
  }

  // Đã gỡ bỏ: static final http.Client _httpClient = http.Client();

  static Future<int> synthesizeToFile({
    required String text,
    required String voice,
    required File targetFile,
    double rate = 0.5,
  }) async {
    final chunksText = _splitText(text);
    int totalBytesWritten = 0;
    final sink = targetFile.openWrite();

    final client = http.Client();

    try {
      for (final chunkText in chunksText) {
        final token = await _getToken(client);
        final bytesWritten = await _ttsRequestStreamToSink(chunkText, voice, rate, token, sink, client);
        totalBytesWritten += bytesWritten;
      }
    } finally {
      client.close();
      await sink.flush();
      await sink.close();
    }

    return totalBytesWritten;
  }

  static Future<int> _ttsRequestStreamToSink(
    String text, 
    String voiceId, 
    double rate, 
    EdgeToken token,
    IOSink sink,
    http.Client client,
  ) async {
    final rateStr = convertRate(rate);
    final parts = voiceId.split("-");
    final xmlLang = parts.length >= 2 ? parts.sublist(0, 2).join("-") : "en-US";
    final gender = voiceId.toLowerCase().contains("male") ? "Male" : "Female";
    
    final escapedText = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    final ssml = "<speak version='1.0' xml:lang='$xmlLang'><voice xml:lang='$xmlLang' xml:gender='$gender' name='$voiceId'><prosody rate='$rateStr'>$escapedText</prosody></voice></speak>";

    final url = Uri.parse("https://www.bing.com/tfettts?isVertical=1&&IG=1&IID=translator.5023&SFX=1");
    final req = http.Request('POST', url);
    req.headers.addAll({
      "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "*/*",
      "Origin": "https://www.bing.com",
      "Referer": "https://www.bing.com/translator",
      "User-Agent": _userAgent,
      "Connection": "close",
    });
    if (token.cookie.isNotEmpty) {
      req.headers["Cookie"] = token.cookie;
    }
    req.bodyFields = {
      "ssml": ssml,
      "token": token.token,
      "key": token.key,
    };

    final response = await client.send(req);

    if (response.statusCode == 429 || response.statusCode == 403) {
      _cachedToken = null;
      _tokenTime = 0;
      final newToken = await _getToken(client);
      final retryReq = http.Request('POST', url);
      retryReq.headers.addAll(req.headers);
      if (newToken.cookie.isNotEmpty) {
        retryReq.headers["Cookie"] = newToken.cookie;
      }
      retryReq.bodyFields = {
        "ssml": ssml,
        "token": newToken.token,
        "key": newToken.key,
      };
      final retryRes = await client.send(retryReq);
      if (retryRes.statusCode != 200) {
        throw Exception("Bing TTS failed on retry: ${retryRes.statusCode}");
      }
      int count = 0;
      final byteStream = retryRes.stream.map((chunk) {
        count += chunk.length;
        return chunk;
      });
      await sink.addStream(byteStream);
      return count;
    }

    if (response.statusCode != 200) {
      throw Exception("Bing TTS failed: ${response.statusCode}");
    }

    int count = 0;
    final byteStream = response.stream.map((chunk) {
      count += chunk.length;
      return chunk;
    });
    await sink.addStream(byteStream);
    return count;
  }

  static Future<List<int>> _ttsRequest(String text, String voiceId, double rate, EdgeToken token) async {

    final rateStr = convertRate(rate);
    final parts = voiceId.split("-");
    final xmlLang = parts.length >= 2 ? parts.sublist(0, 2).join("-") : "en-US";
    final gender = voiceId.toLowerCase().contains("male") ? "Male" : "Female";
    
    final escapedText = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    final ssml = "<speak version='1.0' xml:lang='$xmlLang'><voice xml:lang='$xmlLang' xml:gender='$gender' name='$voiceId'><prosody rate='$rateStr'>$escapedText</prosody></voice></speak>";

    final body = {
      "ssml": ssml,
      "token": token.token,
      "key": token.key,
    };

    final headers = {
      "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "*/*",
      "Origin": "https://www.bing.com",
      "Referer": "https://www.bing.com/translator",
      "User-Agent": _userAgent,
    };

    if (token.cookie.isNotEmpty) {
      headers["Cookie"] = token.cookie;
    }

    final res = await http.post(
      Uri.parse("https://www.bing.com/tfettts?isVertical=1&&IG=1&IID=translator.5023&SFX=1"),
      body: body,
      headers: headers,
    );

    if (res.statusCode == 429 || res.statusCode == 403) {
      _cachedToken = null;
      _tokenTime = 0;
      final newToken = await _getToken(http.Client());
      
      final newHeaders = Map<String, String>.from(headers);
      if (newToken.cookie.isNotEmpty) {
        newHeaders["Cookie"] = newToken.cookie;
      }
      
      final retryRes = await http.post(
        Uri.parse("https://www.bing.com/tfettts?isVertical=1&&IG=1&IID=translator.5023&SFX=1"),
        body: {
          "ssml": ssml,
          "token": newToken.token,
          "key": newToken.key,
        },
        headers: newHeaders,
      );
      
      if (retryRes.statusCode != 200) {
        throw Exception("Bing TTS failed on retry: ${retryRes.statusCode} - ${retryRes.body}");
      }
      return retryRes.bodyBytes;
    }

    if (res.statusCode != 200) {
      throw Exception("Bing TTS failed: ${res.statusCode} - ${res.body}");
    }

    if (res.bodyBytes.length < 1024) {
      throw Exception("Bing TTS returned empty or very small audio. SSML: $ssml");
    }

    return res.bodyBytes;
  }

  static Future<List<Map<String, dynamic>>> listVoices() async {
    try {
      final url = Uri.parse(voiceListUrl);
      final response = await http.get(
        url,
        headers: {
          "User-Agent": _userAgent,
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

  static List<String> _splitText(String text, {int maxBytes = 1500}) {
    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      int end = start + maxBytes;
      if (end >= text.length) {
        chunks.add(text.substring(start));
        break;
      }
      int breakPoint = -1;
      for (final punc in ['.', '!', '?', '\n', ',', ';']) {
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
    // Bing translator API can't handle very large SSML at once. So we split.
    final chunksText = _splitText(text);

    final client = http.Client();
    try {
      for (final chunkText in chunksText) {
        final token = await _getToken(client);
        final audioBytes = await _ttsRequest(chunkText, voice, rate, token);
        yield EdgeAudioChunk(audioBytes);
      }
    } finally {
      client.close();
    }
  }
}
