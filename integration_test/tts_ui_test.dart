import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:audire_reader/services/offline_tts_service.dart';
import 'package:audire_reader/models/book.dart';
import 'package:audire_reader/models/chapter.dart';
import 'package:audire_reader/models/settings.dart';
import 'package:audire_reader/core/database/database_helper.dart';

// Giao diện mô phỏng TtsDownloadManagerSheet để bắt lỗi AXTree
class MockTtsSheet extends StatefulWidget {
  final List<Chapter> chapters;
  final Book book;
  final AppSettings settings;

  const MockTtsSheet(this.chapters, this.book, this.settings, {super.key});

  @override
  State<MockTtsSheet> createState() => _MockTtsSheetState();
}

class _MockTtsSheetState extends State<MockTtsSheet> {
  final OfflineTtsService _offlineService = OfflineTtsService.getInstance();

  @override
  void initState() {
    super.initState();
    _offlineService.addListener(_onServiceUpdate);
    // Tự động bấm tải tất cả khi mở
    Future.microtask(() {
      _offlineService.startDownload(
        book: widget.book,
        chapters: widget.chapters,
        settings: widget.settings,
      );
    });
  }

  @override
  void dispose() {
    _offlineService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    setState(() {}); // Gây ra lỗi AXTree nếu gọi quá nhanh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: widget.chapters.length,
            itemBuilder: (context, index) {
              final chapter = widget.chapters[index];
              final progress = _offlineService.chapterProgress[chapter.chapterIndex] ?? 0.0;
              return ListTile(
                title: Text(chapter.title),
                subtitle: LinearProgressIndicator(value: progress),
              );
            },
          )
        ],
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kiểm thử chống tràn AXTree UI khi tải hàng loạt đoạn văn rỗng', (WidgetTester tester) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.ttsDownloadConcurrency = 10; 
    
    final book = Book()..title = 'Stress Test Book'..uuid = 'stress_uuid';
    
    // Tạo 200 chương, mỗi chương 10 đoạn văn rỗng (Triggers the rapid state update bug)
    final emptyGzip = gzip.encode(utf8.encode(List.generate(10, (i) => '').join('\n')));
    final chapters = List.generate(200, (i) {
      return Chapter()
        ..bookUuid = book.uuid
        ..chapterIndex = i
        ..title = 'Chapter $i'
        ..paragraphsBytes = emptyGzip;
    });

    await tester.pumpWidget(MaterialApp(
      home: MockTtsSheet(chapters, book, settings),
    ));

    final offlineService = OfflineTtsService.getInstance();
    
    // Đợi quá trình tải nền chạy xong (Timeout 30s)
    int waitCount = 0;
    while (offlineService.isDownloading && waitCount < 60) {
      await tester.pump(const Duration(seconds: 1));
      waitCount++;
    }

    expect(offlineService.isDownloading, false);
    debugPrint("=== BÀI TEST HOÀN TẤT. NẾU KHÔNG CÓ LOG 'AXTree' BÊN TRÊN THÌ LỖI ĐÃ ĐƯỢC DIỆT TRỪ! ===");
  });
}
