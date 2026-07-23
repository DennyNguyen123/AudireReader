import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/system_tray_manager.dart';
import 'core/global_hotkey_manager.dart';
import 'core/theme_notifier.dart';
import 'core/locale_notifier.dart';
import 'core/database/database_helper.dart';
import 'views/library/library_screen.dart';
import 'services/tts_service.dart';
import 'services/logger_service.dart';
import 'package:audire_reader/src/rust/frb_generated.dart';
import 'package:audire_reader/src/rust/api/database.dart' as rust_db;
import 'core/utils/path_helper.dart';

void main() async {
  // Đảm bảo bindings được khởi tạo hoàn chỉnh trước khi chạy các service chạy nền
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // Khởi tạo Database SQLite từ Rust
  final appDir = await PathHelper.getAppDirectory();
  try {
    rust_db.initDatabase(dbPath: appDir.path);
  } catch (e) {
    print('Error initializing Rust SQLite DB: $e');
  }

  // Khởi tạo Window Manager cho Desktop để quản lý cửa sổ (như ẩn/hiện/thu nhỏ cho Boss Key)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    await AppTrayManager.init();
    await GlobalHotkeyManager.init();
  }

  // Khởi tạo dịch vụ Audio Service & TTS toàn cục trước khi ứng dụng chạy
  await TtsService.getInstance();

  // Khởi tạo trạng thái themeMode từ Database
  final db = await DatabaseHelper.getInstance();
  final settings = await db.getSettings();
  ThemeNotifier.instance.init(
    settings.themeMode,
    primaryColorHex: settings.primaryColorHex,
  );
  LocaleNotifier.instance.init(settings.appLocale);
  LoggerService().init(
    enableDebugLogs: settings.enableDebugLogs,
    enableWebDavDebug: settings.enableWebDavDebug,
  );

  runApp(const AudireReaderApp());
}

Color _parseColor(String? hexString, Color defaultColor) {
  if (hexString == null || hexString.trim().isEmpty) return defaultColor;
  try {
    final hexCode = hexString.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    } else if (hexCode.length == 8) {
      return Color(int.parse(hexCode, radix: 16));
    }
  } catch (e) {
    // Ignore and fallback
  }
  return defaultColor;
}

class AudireReaderApp extends StatelessWidget {
  const AudireReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) {
        final themeModeStr = ThemeNotifier.instance.themeMode;
        final primaryColor = _parseColor(
          ThemeNotifier.instance.primaryColorHex,
          Colors.amber,
        );

        ThemeMode appThemeMode;
        ThemeData? customTheme;

        if (themeModeStr == 'Dark') {
          appThemeMode = ThemeMode.dark;
        } else if (themeModeStr == 'Light') {
          appThemeMode = ThemeMode.light;
        } else if (themeModeStr == 'Sepia') {
          appThemeMode = ThemeMode.light;
          customTheme = ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4ECD8),
            cardColor: const Color(0xFFEAD8B1),
            dividerColor: const Color(0xFF5B4636).withValues(alpha: 0.15),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.light,
              surface: const Color(0xFFF4ECD8),
              onSurface: const Color(0xFF5B4636),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF5B4636),
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF5B4636)),
              titleTextStyle: TextStyle(
                color: Color(0xFF5B4636),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF5B4636)),
              bodyMedium: TextStyle(color: Color(0xFF5B4636)),
              bodySmall: TextStyle(color: Color(0xFF5B4636)),
              titleLarge: TextStyle(
                color: Color(0xFF5B4636),
                fontWeight: FontWeight.bold,
              ),
              titleMedium: TextStyle(color: Color(0xFF5B4636)),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF5B4636)),
            listTileTheme: const ListTileThemeData(
              iconColor: Color(0xFF5B4636),
              textColor: Color(0xFF5B4636),
            ),
          );
        } else {
          appThemeMode = ThemeMode.system;
        }

        return ListenableBuilder(
          listenable: LocaleNotifier.instance,
          builder: (context, _) {
            return MaterialApp(
              title: 'Audire Reader',
              debugShowCheckedModeBanner: false,
              theme:
                  customTheme ??
                  ThemeData(
                    brightness: Brightness.light,
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: primaryColor,
                      brightness: Brightness.light,
                    ),
                    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
                    cardColor: Colors.white,
                    dividerColor: Colors.black.withValues(alpha: 0.06),
                    useMaterial3: true,
                    pageTransitionsTheme: const PageTransitionsTheme(
                      builders: <TargetPlatform, PageTransitionsBuilder>{
                        TargetPlatform.android:
                            FadeUpwardsPageTransitionsBuilder(),
                        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                        TargetPlatform.windows:
                            FadeUpwardsPageTransitionsBuilder(),
                        TargetPlatform.linux:
                            FadeUpwardsPageTransitionsBuilder(),
                        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                      },
                    ),
                  ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: primaryColor,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF121212),
                cardColor: const Color(0xFF1E1E1E),
                dividerColor: Colors.white.withValues(alpha: 0.1),
                useMaterial3: true,
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  },
                ),
              ),
              themeAnimationDuration: const Duration(milliseconds: 500),
              themeAnimationCurve: Curves.easeInOutCubic,
              themeMode: appThemeMode,
              locale: LocaleNotifier.instance.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('vi')],
              home: const LibraryScreen(),
            );
          },
        );
      },
    );
  }
}
