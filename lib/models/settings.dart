import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class AppSettings {
  Id id = 1; // Luôn luôn là 1 để ghi đè cấu hình duy nhất

  double fontSize = 18.0;
  double speechRate = 0.5;
  
  String? selectedVoiceName;
  String? selectedVoiceLocale;

  String fontFamily = 'System'; // 'System', 'Serif', 'Sans-Serif', 'Monospace'
  String themeMode = 'System';  // 'System', 'Light', 'Dark', 'Sepia'
}
