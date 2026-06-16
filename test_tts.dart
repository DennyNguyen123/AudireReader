import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

const String baseUri = "speech.platform.bing.com/consumer/speech/synthesize/readaloud";
const String trustedClientToken = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
const String chromiumMajorVersion = "143";
const String chromiumFullVersion = "143.0.3650.75";

String generateSecMsGec() {
  const int winEpoch = 11644473600;
  double unixTimestamp = DateTime.now().toUtc().millisecondsSinceEpoch / 1000.0;
  int ticks = unixTimestamp.toInt() + winEpoch;
  ticks -= ticks % 300;
  int intervalTicks = ticks * 10000000;
  final strToHash = "$intervalTicks$trustedClientToken";
  final bytes = utf8.encode(strToHash);
  return sha256.convert(bytes).toString().toUpperCase();
}

String generateUuid() {
  final random = Random();
  final hexDigits = '0123456789abcdef';
  String hex(int length) => List.generate(length, (_) => hexDigits[random.nextInt(16)]).join();
  return '${hex(8)}-${hex(4)}-4${hex(3)}-${hexDigits[8 + random.nextInt(4)]}${hex(3)}-${hex(12)}';
}

void main() async {
  final secMsGec = generateSecMsGec();
  final connectionId = generateUuid().replaceAll('-', '');
  final wsUrlStr = "wss://$baseUri/edge/v1?TrustedClientToken=$trustedClientToken&ConnectionId=$connectionId&Sec-MS-GEC=$secMsGec&Sec-MS-GEC-Version=1-$chromiumFullVersion";
  
  print("Connecting to: $wsUrlStr");
  

  WebSocket? ws;
  try {
      ws = await WebSocket.connect(
        wsUrlStr,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0",
          "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
        },
      );
  } catch (e) {
      print('First try failed: ' + e.toString());
      final response = await http.head(
        Uri.parse('https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=6A5AA1D4EAFF4E9FB37E23D68491D6F4'),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0",
        },
      );
      final serverDateHeader = response.headers['date'];
      if (serverDateHeader != null) {
          // parse roughly
          print('Server date: ' + serverDateHeader);
      }
      ws = await WebSocket.connect(
        wsUrlStr,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0",
          "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
        },
      );
  }


  print("Connected!");
  
  ws!.listen((message) {
    if (message is String) {
      print("TEXT: $message");
    } else {
      print("BINARY length: ${(message as List<int>).length}");
    }
  }, onDone: () {
    print("onDone: WebSocket closed! closeCode=${ws!.closeCode}, closeReason=${ws!.closeReason}");
  }, onError: (e) {
    print("onError: $e");
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

  final ssmlMsg =
      "X-RequestId:$connectionId\r\n"
      "Content-Type:application/ssml+xml\r\n"
      "X-Timestamp:${jsDateStr}Z\r\n"
      "Path:ssml\r\n\r\n"
      "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'><voice name='vi-VN-HoaiMyNeural'><prosody rate='0%' pitch='+0Hz' volume='+0%'>Xin chào thế giới</prosody></voice></speak>";
  ws.add(ssmlMsg);
  
  await Future.delayed(Duration(seconds: 5));
  await ws.close();
}
