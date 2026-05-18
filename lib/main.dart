import 'package:flutter/material.dart';
import 'views/library/library_screen.dart';
import 'services/tts_service.dart';

void main() async {
  // Đảm bảo bindings được khởi tạo hoàn chỉnh trước khi chạy các service chạy nền
  WidgetsFlutterBinding.ensureInitialized();
  
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
