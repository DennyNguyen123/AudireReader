import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:audire_reader/services/offline_tts_service.dart';
import 'package:audire_reader/src/rust/api/models.dart';
import 'package:audire_reader/models/chapter.dart';
import 'package:audire_reader/models/settings.dart';
import 'package:audire_reader/core/database/database_helper.dart';

// Giao diá»‡n mÃ´ phá»ng TtsDownloadManagerSheet Ä‘á»ƒ báº¯t lá»—i AXTree
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
    // Tá»± Ä‘á»™ng báº¥m táº£i táº¥t cáº£ khi má»Ÿ
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
    setState(() {}); // GÃ¢y ra lá»—i AXTree náº¿u gá»i quÃ¡ nhanh
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
              final progress =
                  _offlineService.chapterProgress[chapter.chapterIndex] ?? 0.0;
              return ListTile(
                title: Text(chapter.title),
                subtitle: LinearProgressIndicator(value: progress),
              );
            },
          ),
        ],
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kiá»ƒm thá»­ chá»‘ng trÃ n AXTree UI khi táº£i hÃ ng loáº¡t Ä‘oáº¡n vÄƒn rá»—ng', (
    WidgetTester tester,
  ) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.ttsDownloadConcurrency = 10;

    final book = Book()
      ..title = 'Stress Test Book'
      ..uuid = 'stress_uuid';

    // Táº¡o 200 chÆ°Æ¡ng, má»—i chÆ°Æ¡ng 10 Ä‘oáº¡n vÄƒn rá»—ng (Triggers the rapid state update bug)
    final emptyGzip = gzip.encode(
      utf8.encode(List.generate(10, (i) => '').join('\n')),
    );
    final chapters = List.generate(200, (i) {
      return Chapter()
        ..bookUuid = book.uuid
        ..chapterIndex = i
        ..title = 'Chapter $i'
        ..paragraphsBytes = emptyGzip;
    });

    await tester.pumpWidget(
      MaterialApp(home: MockTtsSheet(chapters, book, settings)),
    );

    final offlineService = OfflineTtsService.getInstance();

    // Äá»£i quÃ¡ trÃ¬nh táº£i ná»n cháº¡y xong (Timeout 30s)
    int waitCount = 0;
    while (offlineService.isDownloading && waitCount < 60) {
      await tester.pump(const Duration(seconds: 1));
      waitCount++;
    }

    expect(offlineService.isDownloading, false);
    debugPrint(
      "=== BÃ€I TEST HOÃ€N Táº¤T. Náº¾U KHÃ”NG CÃ“ LOG 'AXTree' BÃŠN TRÃŠN THÃŒ Lá»–I ÄÃƒ ÄÆ¯á»¢C DIá»†T TRá»ª! ===",
    );
  });
}
