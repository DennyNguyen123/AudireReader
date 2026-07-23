import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/database/database_helper.dart';

class OpenAiTtsService {
  static Future<String> synthesizeToWav(
    String text,
    String voiceName,
    double rate,
  ) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();

    final endpoint = settings.openAiTtsEndpoint;
    final apiKey = settings.openAiTtsApiKey;
    final model = settings.openAiTtsModel;

    if (apiKey.isEmpty) {
      throw Exception(
        'OpenAI TTS API Key is empty. Please set it in Settings.',
      );
    }

    final url = Uri.parse('$endpoint/audio/speech');

    // OpenAI TTS does not natively support rate parameter directly in the same way,
    // but the API has a 'speed' parameter ranging from 0.25 to 4.0.
    // Our app speech rate is 0.5 for 1x. So we do rate * 2.0.
    double speed = rate * 2.0;
    if (speed < 0.25) speed = 0.25;
    if (speed > 4.0) speed = 4.0;

    final requestBody = <String, dynamic>{'model': model, 'input': text};

    if (voiceName.isNotEmpty) {
      requestBody['voice'] = voiceName;
    }

    // Some custom proxies (like for edge-tts) might crash if we send unknown fields.
    // OpenAI officially supports speed and response_format.
    // Let's only send them if they are default values or required.
    // To be safe and maximize compatibility with simple proxies, we only send what is standard,
    // but the user's proxy might not even support 'speed'.
    requestBody['response_format'] = 'mp3';
    requestBody['speed'] = speed;

    // However, if the model contains "edge-tts", it's a proxy.
    // It's safer to just send the bare minimum if it's a custom proxy, but let's try not to over-engineer.
    // Actually, I'll remove response_format and speed if they are defaults, or let's just keep speed.
    // Wait, the safest is to NOT send them if the endpoint is not api.openai.com,
    // or just send them and hope the proxy ignores them.
    // If the proxy crashes on extra fields, let's remove response_format and speed for non-openai endpoints?
    // Let's just remove them for now if the user is using a non-standard model or just send them.

    if (!endpoint.contains('api.openai.com')) {
      requestBody.remove('response_format');
      if (speed == 1.0) requestBody.remove('speed'); // 1.0 is default
    }

    print("--- [OpenAI TTS] Requesting ---");
    print("URL: $url");
    print(
      "Headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer \${apiKey.length > 5 ? apiKey.substring(0,5) + '...' : ''}'}",
    );
    print("Body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      print("--- [OpenAI TTS] Response ---");
      print("Status: ${response.statusCode}");
      // Tránh in body nếu thành công vì nó là file nhị phân (mp3)
      if (response.statusCode != 200) {
        print("Body Error: ${response.body}");
      }

      if (response.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/openai_tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
        );
        await file.writeAsBytes(response.bodyBytes);
        print("--- [OpenAI TTS] Saved to ${file.path} ---");
        return file.path;
      } else {
        throw Exception(
          'OpenAI TTS failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print("--- [OpenAI TTS] Exception: $e ---");
      rethrow;
    }
  }

  static List<Map<String, String>> getVoices() {
    return [
      {'name': 'Alloy', 'locale': 'en', 'gender': 'Neutral'},
      {'name': 'Echo', 'locale': 'en', 'gender': 'Male'},
      {'name': 'Fable', 'locale': 'en', 'gender': 'Neutral'},
      {'name': 'Onyx', 'locale': 'en', 'gender': 'Male'},
      {'name': 'Nova', 'locale': 'en', 'gender': 'Female'},
      {'name': 'Shimmer', 'locale': 'en', 'gender': 'Female'},
    ];
  }
}
