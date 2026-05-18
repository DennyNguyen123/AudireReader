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

  bool webDavEnabled = false;
  String webDavUrl = '';
  String webDavUsername = '';
  String webDavPassword = '';
  DateTime? webDavLastSync;

  bool openLastReadOnLaunch = false;

  // --- Hotkeys & Boss Key Settings ---
  String hotkeyNextParagraph = 'Arrow Down';
  String hotkeyPrevParagraph = 'Arrow Up';
  String hotkeyNextChapter = 'Control+Arrow Right';
  String hotkeyPrevChapter = 'Control+Arrow Left';
  String hotkeyPlayPauseTts = 'Space';
  String hotkeyOpenChapter = 'Control+o';
  String hotkeyOpenSetting = 'Control+comma';
  String hotkeyBossKey = 'Control+b';
  String bossKeyAction = 'minimize'; // 'minimize' or 'hide'

  bool autoCheckUpdate = true;
}
