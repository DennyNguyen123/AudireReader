// ignore_for_file: avoid_print
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
  final String type; // 'WordBoundary'
  final int offset; // offset in milliseconds
  final int duration; // duration in milliseconds
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
  static const String baseUri =
      "speech.platform.bing.com/consumer/speech/synthesize/readaloud";
  static const String wssUrl =
      "wss://$baseUri/edge/v1?TrustedClientToken=$trustedClientToken";
  static const String voiceListUrl =
      "https://$baseUri/voices/list?trustedclienttoken=$trustedClientToken";

  // Biến lưu độ lệch thời gian (clock skew) tính bằng giây
  static double _clockSkewSeconds = 0.0;

  /// Phân tích định dạng ngày Date chuẩn RFC 2616 sang DateTime
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

  /// Tự động đồng bộ hóa thời gian hệ thống với Bing Speech API để tính clock skew
  static Future<void> adjustClockSkew() async {
    try {
      final chromiumFullVersion = "143.0.3650.75";
      final chromiumMajorVersion = chromiumFullVersion.split(".")[0];
      final url = Uri.parse(voiceListUrl);
      
      final response = await http.head(
        url,
        headers: {
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromiumMajorVersion.0.0.0 Safari/537.36 Edg/$chromiumMajorVersion.0.0.0",
        },
      ).timeout(const Duration(seconds: 3));
      
      final serverDateHeader = response.headers['date'];
      if (serverDateHeader != null) {
        final serverTime = _parseRfc2616Date(serverDateHeader);
        if (serverTime != null) {
          final clientTime = DateTime.now().toUtc();
          final diffMs = serverTime.difference(clientTime).inMilliseconds;
          _clockSkewSeconds = diffMs / 1000.0;
          print("EdgeTtsService: Adjusted clock skew by ${_clockSkewSeconds.toStringAsFixed(3)} seconds");
        }
      }
    } catch (e) {
      print("EdgeTtsService: Failed to adjust clock skew: $e");
    }
  }

  /// Sinh mã token bảo mật Sec-MS-GEC bằng Epoch Windows File Time (1601-01-01) làm tròn 5 phút, có bù độ lệch thời gian
  static String generateSecMsGec() {
    const int winEpoch =
        11644473600; // Khoảng cách giây giữa Unix Epoch và Windows Epoch

    // Lấy thời gian UTC hiện tại tính bằng giây và bù clock skew
    double unixTimestamp = DateTime.now().toUtc().millisecondsSinceEpoch / 1000.0;
    unixTimestamp += _clockSkewSeconds;

    int ticks = unixTimestamp.toInt() + winEpoch;
    ticks -= ticks % 300; // Làm tròn xuống 5 phút (300 giây)

    // Đổi sang khoảng thời gian 100-nanosecond (Windows file time format)
    int intervalTicks = ticks * 10000000;

    // Băm SHA-256 chuỗi ticks kết hợp với trusted client token
    final strToHash = "$intervalTicks$trustedClientToken";
    final bytes = utf8.encode(strToHash);
    final digest = sha256.convert(bytes);

    return digest.toString().toUpperCase();
  }

  /// Sinh chuỗi UUID v4 ngẫu nhiên
  static String generateUuid() {
    final random = Random();
    final hexDigits = '0123456789abcdef';
    String hex(int length) =>
        List.generate(length, (_) => hexDigits[random.nextInt(16)]).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-${hexDigits[8 + random.nextInt(4)]}${hex(3)}-${hex(12)}';
  }

  /// Sinh mã định danh MUID ngẫu nhiên cho cookie
  static String generateMuid() {
    final random = Random();
    final hexDigits = '0123456789ABCDEF';
    return List.generate(32, (_) => hexDigits[random.nextInt(16)]).join();
  }

  /// Lấy danh sách toàn bộ giọng đọc từ Edge TTS API
  static Future<List<Map<String, dynamic>>> listVoices() async {
    try {
      final chromiumFullVersion = "143.0.3650.75";
      final chromiumMajorVersion = chromiumFullVersion.split(".")[0];
      final url = Uri.parse(voiceListUrl);

      final response = await http.get(
        url,
        headers: {
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromiumMajorVersion.0.0.0 Safari/537.36 Edg/$chromiumMajorVersion.0.0.0",
          "Accept-Encoding": "gzip, deflate, br, zstd",
          "Accept-Language": "en-US,en;q=0.9",
          "Accept": "*/*",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item)),
        );
      } else {
        throw Exception(
          "Failed to fetch Edge TTS voices: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error fetching Edge TTS voices: $e");
      return [];
    }
  }

  /// Helper chuyển đổi tốc độ đọc (0.0 -> 1.0, trong đó 0.5 là 1.0x) sang định dạng phần trăm của Edge TTS (+50%, -20%)
  static String convertRate(double speechRate) {
    // Trong flutter_tts: 0.5 là 1.0x (bình thường).
    // Ta quy đổi: 0.5 tương ứng +0%. Tăng lên 0.75 tương ứng +50%, giảm xuống 0.25 tương ứng -50%.
    final percentage = ((speechRate - 0.5) / 0.5 * 100).round();
    if (percentage >= 0) {
      return "+$percentage%";
    } else {
      return "$percentage%";
    }
  }

  /// Trích xuất headers từ chuỗi raw text
  static Map<String, String> parseHeaders(String text) {
    final Map<String, String> headers = {};
    for (final line in text.split('\r\n')) {
      if (line.contains(':')) {
        final parts = line.split(':');
        final key = parts[0].trim();
        final value = parts.sublist(1).join(':').trim();
        headers[key] = value;
      }
    }
    return headers;
  }

  /// Gửi yêu cầu WebSocket và stream dữ liệu nhị phân MP3 cùng với Word boundary metadata
  static Stream<EdgeTtsChunk> synthesize({
    required String text,
    required String voice,
    double rate = 0.5, // 0.5 tương ứng 1.0x tốc độ chuẩn
    double pitch = 1.0,
  }) async* {
    final rateStr = convertRate(rate);
    final pitchStr = "+0Hz"; // Giữ pitch chuẩn

    final secMsGec = generateSecMsGec();
    final chromiumFullVersion = "143.0.3650.75";
    final chromiumMajorVersion = chromiumFullVersion.split(".")[0];
    final connectionId = generateUuid().replaceAll('-', '');

    final wsUrlStr =
        "wss://$baseUri/edge/v1?TrustedClientToken=$trustedClientToken&ConnectionId=$connectionId&Sec-MS-GEC=$secMsGec&Sec-MS-GEC-Version=1-$chromiumFullVersion";

    WebSocket? ws;
    final client = HttpClient();
    client.userAgent = null; // Vô hiệu hóa User-Agent mặc định của Dart (tránh bị chặn 403)

    try {
      try {
        ws = await WebSocket.connect(
          wsUrlStr,
          headers: {
            "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromiumMajorVersion.0.0.0 Safari/537.36 Edg/$chromiumMajorVersion.0.0.0",
            "Accept-Encoding": "gzip, deflate, br, zstd",
            "Accept-Language": "en-US,en;q=0.9",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache",
            "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
            "Cookie": "muid=${generateMuid()};",
          },
          customClient: client,
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        print("EdgeTtsService: First connection attempt failed. Adjusting clock skew and retrying...");
        await adjustClockSkew();
        
        final newSecMsGec = generateSecMsGec();
        final newWsUrlStr =
            "wss://$baseUri/edge/v1?TrustedClientToken=$trustedClientToken&ConnectionId=$connectionId&Sec-MS-GEC=$newSecMsGec&Sec-MS-GEC-Version=1-$chromiumFullVersion";
            
        ws = await WebSocket.connect(
          newWsUrlStr,
          headers: {
            "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromiumMajorVersion.0.0.0 Safari/537.36 Edg/$chromiumMajorVersion.0.0.0",
            "Accept-Encoding": "gzip, deflate, br, zstd",
            "Accept-Language": "en-US,en;q=0.9",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache",
            "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
            "Cookie": "muid=${generateMuid()};",
          },
          customClient: client,
        ).timeout(const Duration(seconds: 5));
      }

      // 1. Tạo chuỗi thời gian JavaScript
      final now = DateTime.now().toUtc();
      final months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      final weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      String pad(int n) => n.toString().padLeft(2, '0');
      final jsDateStr =
          "${weekdays[now.weekday - 1]} ${months[now.month - 1]} ${pad(now.day)} ${now.year} ${pad(now.hour)}:${pad(now.minute)}:${pad(now.second)} GMT+0000 (Coordinated Universal Time)";

      // 2. Gửi config khởi động định dạng âm thanh
      final configMsg =
          "X-Timestamp:$jsDateStr\r\n"
          "Content-Type:application/json; charset=utf-8\r\n"
          "Path:speech.config\r\n\r\n"
          '{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"true"},"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}';
      ws.add(configMsg);

      // 3. Gửi SSML
      final requestId = generateUuid().replaceAll('-', '');
      final escapedText = text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');

      final ssml =
          "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>"
          "<voice name='$voice'>"
          "<prosody rate='$rateStr' pitch='$pitchStr' volume='+0%'>"
          "$escapedText"
          "</prosody>"
          "</voice>"
          "</speak>";

      final ssmlMsg =
          "X-RequestId:$requestId\r\n"
          "Content-Type:application/ssml+xml\r\n"
          "X-Timestamp:${jsDateStr}Z\r\n"
          "Path:ssml\r\n\r\n"
          "$ssml";
      ws.add(ssmlMsg);

      // 4. Lắng nghe phản hồi từ WebSocket
      await for (final message in ws) {
        if (message is String) {
          // Xử lý gói tin văn bản (Metadata)
          final splitIndex = message.indexOf("\r\n\r\n");
          if (splitIndex == -1) continue;

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
                    final offsetTicks = dataObj["Offset"] as int;
                    final durationTicks = dataObj["Duration"] as int;
                    final wordText = dataObj["text"]["Text"] as String;

                    // Quy đổi ticks sang milliseconds (1 ms = 10,000 ticks)
                    yield EdgeMetadataChunk(
                      type: "WordBoundary",
                      offset: offsetTicks ~/ 10000,
                      duration: durationTicks ~/ 10000,
                      text: wordText,
                    );
                  }
                }
              }
            } catch (e) {
              print("Error parsing Edge TTS metadata JSON: $e");
            }
          } else if (path == "turn.end") {
            // Nhận tín hiệu kết thúc phiên đọc
            break;
          }
        } else if (message is List<int>) {
          // Xử lý gói tin nhị phân (Binary Frame - Audio)
          if (message.length < 2) continue;

          // Đọc độ dài phần text header (2 byte đầu tiên, định dạng Big Endian)
          final headerLength = (message[0] << 8) | message[1];
          if (headerLength > message.length - 2) continue;

          final headerBytes = message.sublist(2, 2 + headerLength);
          final headerText = utf8.decode(headerBytes);

          final headers = parseHeaders(headerText);
          final path = headers["Path"];

          if (path == "audio") {
            // Phần byte còn lại chính là dữ liệu file MP3
            final audioData = message.sublist(2 + headerLength);
            if (audioData.isNotEmpty) {
              yield EdgeAudioChunk(audioData);
            }
          }
        }
      }
    } catch (e) {
      print("WebSocket session error in Edge TTS: $e");
      rethrow;
    } finally {
      if (ws != null) {
        await ws.close().catchError((err) {
          print("Error closing WebSocket: $err");
          return null;
        });
      }
    }
  }
}
