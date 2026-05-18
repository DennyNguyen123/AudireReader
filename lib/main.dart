import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'core/system_tray_manager.dart';
import 'core/global_hotkey_manager.dart';
import 'views/library/library_screen.dart';
import 'services/tts_service.dart';

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

  runApp(const NovelReaderApp());
}

class NovelReaderApp extends StatelessWidget {
  const NovelReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novel Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.amber,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Tự động đồng bộ Dark Mode với Windows/iPhone
      home: const LibraryScreen(),
    );
  }
}
