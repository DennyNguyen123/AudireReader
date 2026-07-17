import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class AppSettings {
  Id id = 1; // Luôn luôn là 1 để ghi đè cấu hình duy nhất

  double fontSize = 18.0;
  double speechRate = 0.5;
  
  String? selectedVoiceName;
  String? selectedVoiceLocale;
  String ttsProvider = 'system'; // 'system' hoặc 'microsoft_edge' hoặc 'supertonic' hoặc 'openai'

  // --- OpenAI TTS Settings ---
  String openAiTtsEndpoint = 'https://api.openai.com/v1';
  String openAiTtsApiKey = '';
  String openAiTtsModel = 'tts-1';


  String fontFamily = 'System'; // 'System', 'Serif', 'Sans-Serif', 'Monospace', 'Lora', 'Merriweather', 'Inter', 'Nunito'
  String themeMode = 'System';  // 'System', 'Light', 'Dark', 'Sepia', 'Custom'
  String appLocale = 'en';      // 'en' hoặc 'vi'

  double lineHeight = 1.6;
  double paragraphSpacing = 14.0;
  String textAlignment = 'left';
  double sideMargin = 20.0;
  String? customBackgroundColor;
  String? customTextColor;
  String? primaryColorHex;

  bool webDavEnabled = false;
  String webDavUrl = '';
  String webDavUsername = '';
  DateTime? webDavLastSync;

  String? deviceId;
  String? deviceName;

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

  // --- Background Music (BGM) Settings ---
  bool bgmEnabled = false;
  double bgmVolume = 0.15;
  int? currentBgmTrackId;
  String? currentBgmTrackUrl;
  String? currentBgmTrackName;
  String bgmLoopMode = 'all'; // 'none', 'one', 'all'
  String bgmProviderId = 'local'; // 'local', 'radio_browser', 'open_lofi'

  String? lastLocalTrackUrl;
  String? lastRadioTrackUrl;
  String? lastRadioTrackName;
  String? lastLofiTrackUrl;
  String? lastLofiTrackName;

  // Library Sorting Options: 'dateAdded', 'recentlyRead', 'title', 'author'
  String sortBy = 'dateAdded';

  // --- Assistive Button Settings ---
  bool showAssistiveButton = false;
  double assistiveButtonX = -1.0;
  double assistiveButtonY = -1.0;
  String assistiveSingleTapAction = 'nextParagraph';
  String assistiveDoubleTapAction = 'prevParagraph';
  String assistiveLongPressAction = 'playPause';

  // --- Developer Settings ---
  bool developerMode = false;
  bool enableDebugLogs = false;
  bool enableWebDavDebug = false;
}
