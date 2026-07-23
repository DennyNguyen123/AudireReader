import 'dart:io';
import 'package:audire_reader/services/edge_tts_service.dart';

void main() async {
  print('============================================');
  print('BẮT ĐẦU BÀI TEST CHỊU TẢI API EDGE TTS KHÔNG QUA GIAO DIỆN (UI)');
  print('============================================');
  
  final initialRam = ProcessInfo.currentRss / (1024 * 1024);
  print('RAM ban đầu: ${initialRam.toStringAsFixed(2)} MB');

  final tempDir = Directory.systemTemp.createTempSync('tts_test_');
  print('Thư mục tạm: ${tempDir.path}');

  const concurrency = 10;
  const chaptersToSimulate = 10;
  const paragraphsPerChapter = 50;
  
  print('Giả lập tải $chaptersToSimulate chương, mỗi chương $paragraphsPerChapter đoạn.');
  print('Tổng cộng: ${chaptersToSimulate * paragraphsPerChapter} API requests, $concurrency luồng song song.');

  final chapters = List.generate(chaptersToSimulate, (i) => i);
  
  Future<void> workerLoop(List<int> queue, int workerId) async {
    while (queue.isNotEmpty) {
      final chIdx = queue.removeAt(0);
      for (int pIdx = 0; pIdx < paragraphsPerChapter; pIdx++) {
        final file = File('${tempDir.path}/ch${chIdx}_p$pIdx.mp3');
        try {
          await EdgeTtsService.synthesizeToFile(
            text: 'Đây là đoạn văn bản giả lập số $pIdx của chương $chIdx để kiểm tra rò rỉ bộ nhớ mạng.',
            voice: 'vi-VN-HoaiMyNeural',
            targetFile: file,
          );
        } catch (e) {
          print('Lỗi Worker $workerId - Ch $chIdx P $pIdx: $e');
        }
      }
      final currentRam = ProcessInfo.currentRss / (1024 * 1024);
      print('Worker $workerId tải xong Chương $chIdx - RAM hiện tại: ${currentRam.toStringAsFixed(2)} MB');
    }
  }

  final workers = <Future<void>>[];
  final queue = List<int>.from(chapters);
  
  for (int i = 0; i < concurrency; i++) {
    workers.add(workerLoop(queue, i));
  }

  await Future.wait(workers);

  final finalRam = ProcessInfo.currentRss / (1024 * 1024);
  print('============================================');
  print('HOÀN THÀNH BÀI TEST!');
  print('RAM ban đầu: ${initialRam.toStringAsFixed(2)} MB');
  print('RAM lúc kết thúc: ${finalRam.toStringAsFixed(2)} MB');
  print('Chênh lệch (Dart Heap Tăng Thêm): ${(finalRam - initialRam).toStringAsFixed(2)} MB');
  print('============================================');

  // Dọn rác
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}
