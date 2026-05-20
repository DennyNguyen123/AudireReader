import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'core/system_tray_manager.dart';
import 'core/global_hotkey_manager.dart';
import 'core/theme_notifier.dart';
import 'core/database/database_helper.dart';
import 'views/library/library_screen.dart';
import 'services/tts_service.dart';
import 'services/logger_service.dart';

void main() async {
  // Đảm bảo bindings được khởi tạo hoàn chỉnh trước khi chạy các service chạy nền
  WidgetsFlutterBinding.ensureInitialized();
  
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
  ThemeNotifier.instance.init(settings.themeMode);
  LoggerService().init(
    enableDebugLogs: settings.enableDebugLogs,
    enableWebDavDebug: settings.enableWebDavDebug,
  );

  runApp(const AudireReaderApp());
}

class AudireReaderApp extends StatelessWidget {
  const AudireReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) {
        final themeModeStr = ThemeNotifier.instance.themeMode;
        
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
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: const Color(0xFFF4ECD8),
            cardColor: const Color(0xFFEAD8B1),
            dividerColor: const Color(0xFF5B4636).withValues(alpha: 0.15),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.amber,
              brightness: Brightness.light,
              surface: const Color(0xFFF4ECD8),
              onSurface: const Color(0xFF5B4636),
              primary: const Color(0xFFB57C1E),
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
              titleLarge: TextStyle(color: Color(0xFF5B4636), fontWeight: FontWeight.bold),
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

        return MaterialApp(
          title: 'Audire Reader',
          debugShowCheckedModeBanner: false,
          theme: customTheme ?? ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            cardColor: Colors.white,
            dividerColor: Colors.black.withValues(alpha: 0.06),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.white.withValues(alpha: 0.1),
            useMaterial3: true,
          ),
          themeMode: appThemeMode,
          home: const LibraryScreen(),
        );
      },
    );
  }
}
