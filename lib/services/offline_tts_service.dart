import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:path/path.dart' as p;
import '../core/database/database_helper.dart';
import '../core/utils/path_helper.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/offline_tts_record.dart';
import '../models/settings.dart';
import 'edge_tts_service.dart';
import 'openai_tts_service.dart';
import 'supertonic_service.dart';
import 'tts_service.dart';

enum DownloadState { idle, downloading, paused, completed, error }

class OfflineTtsService extends ChangeNotifier {
  static OfflineTtsService? _instance;

  DownloadState _state = DownloadState.idle;
  DownloadState get state => _state;
  bool get isDownloading => _state == DownloadState.downloading;
  bool get isPaused => _state == DownloadState.paused;

  String? _currentBookUuid;
  String? get currentBookUuid => _currentBookUuid;

  int _totalChaptersToDownload = 0;
  int _completedChaptersCount = 0;
  int get totalChaptersToDownload => _totalChaptersToDownload;
  int get completedChaptersCount => _completedChaptersCount;

  // Chapter index -> progress (0.0 to 1.0)
  final Map<int, double> _chapterProgress = {};
  // Chapter index -> status string ('idle', 'downloading', 'completed', 'error')
  final Map<int, String> _chapterStatus = {};
  
  Map<int, double> get chapterProgress => Map.unmodifiable(_chapterProgress);
  Map<int, String> get chapterStatus => Map.unmodifiable(_chapterStatus);

  // Queue of chapters pending download
  final List<Chapter> _pendingQueue = [];
  final Set<int> _activeDownloadingIndices = {};

  bool _cancelRequested = false;
  Timer? _notifyDebounceTimer;

  void _notifyListenersDebounced() {
    if (_notifyDebounceTimer?.isActive ?? false) return;
    _notifyDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
      notifyListeners();
    });
  }

  void _notifyListenersImmediate() {
    _notifyDebounceTimer?.cancel();
    notifyListeners();
  }

  OfflineTtsService._();


  static OfflineTtsService getInstance() {
    _instance ??= OfflineTtsService._();
    return _instance!;
  }

  /// Get the offline directory for a specific book and chapter
  Future<Directory> getOfflineChapterDir(String bookUuid, int chapterIndex) async {
    final appDir = await PathHelper.getAppDirectory();
    final dir = Directory(p.join(appDir.path, 'tts_offline', bookUuid, 'ch_$chapterIndex'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get total offline storage size in bytes for a specific book or all books
  Future<int> getStorageUsage([String? bookUuid]) async {
    try {
      final appDir = await PathHelper.getAppDirectory();
      final targetPath = bookUuid != null 
          ? p.join(appDir.path, 'tts_offline', bookUuid)
          : p.join(appDir.path, 'tts_offline');
      
      final dir = Directory(targetPath);
      if (!dir.existsSync()) return 0;

      int totalSize = 0;
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('[OfflineTtsService] Error calculating storage usage: $e');
      return 0;
    }
  }

  /// Get storage size in bytes for each chapter of a book
  Future<Map<int, int>> getChapterStorageSizes(String bookUuid) async {
    final Map<int, int> sizes = {};
    try {
      final appDir = await PathHelper.getAppDirectory();
      final bookDir = Directory(p.join(appDir.path, 'tts_offline', bookUuid));
      if (!bookDir.existsSync()) return sizes;

      final entities = bookDir.listSync();
      for (final entity in entities) {
        if (entity is Directory) {
          final dirName = p.basename(entity.path);
          if (dirName.startsWith('ch_')) {
            final chIdx = int.tryParse(dirName.substring(3));
            if (chIdx != null) {
              int chSize = 0;
              for (final file in entity.listSync(recursive: true)) {
                if (file is File) {
                  chSize += file.lengthSync();
                }
              }
              sizes[chIdx] = chSize;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[OfflineTtsService] Error calculating chapter storage sizes: $e');
    }
    return sizes;
  }


  /// Check if a chapter has valid offline TTS files matching current settings
  Future<bool> isChapterDownloaded(String bookUuid, int chapterIndex, AppSettings settings) async {
    try {
      final db = await DatabaseHelper.getInstance();
      final record = await db.getOfflineTtsRecord(bookUuid, chapterIndex);
      if (record == null || !record.isCompleted) return false;

      // Ensure voice & provider match current settings
      final provider = settings.ttsProvider;
      final voice = settings.selectedVoiceName ?? '';
      final rate = settings.speechRate;

      if (record.ttsProvider != provider || record.voiceName != voice) {
        return false;
      }
      // Allow minor speechRate floating point difference
      if ((record.speechRate - rate).abs() > 0.05) {
        return false;
      }

      // Check if physical directory exists and contains audio files
      final dir = await getOfflineChapterDir(bookUuid, chapterIndex);
      if (!dir.existsSync()) return false;

      final audioFiles = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.wav') || f.path.endsWith('.mp3'));
      return audioFiles.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Start batch download for chapters of a book
  Future<void> startDownload({
    required Book book,
    required List<Chapter> chapters,
    required AppSettings settings,
  }) async {
    if (_state == DownloadState.downloading) {
      debugPrint('[OfflineTtsService] Download already in progress');
      return;
    }

    _cancelRequested = false;
    _currentBookUuid = book.uuid;
    _pendingQueue.clear();
    _pendingQueue.addAll(chapters);
    _totalChaptersToDownload = chapters.length;
    _completedChaptersCount = 0;
    _chapterProgress.clear();
    _chapterStatus.clear();

    for (final ch in chapters) {
      _chapterProgress[ch.chapterIndex] = 0.0;
      _chapterStatus[ch.chapterIndex] = 'idle';
    }

    _state = DownloadState.downloading;
    notifyListeners();

    _processQueue(book, settings);
  }

  void pauseDownload() {
    if (_state == DownloadState.downloading) {
      _state = DownloadState.paused;
      notifyListeners();
    }
  }

  void resumeDownload(Book book, AppSettings settings) {
    if (_state == DownloadState.paused) {
      _state = DownloadState.downloading;
      notifyListeners();
      _processQueue(book, settings);
    }
  }

  void cancelDownload() {
    _cancelRequested = true;
    _pendingQueue.clear();
    _activeDownloadingIndices.clear();
    _state = DownloadState.idle;
    notifyListeners();
  }

  /// Process download queue with configured concurrency
  Future<void> _processQueue(Book book, AppSettings settings) async {
    final concurrency = settings.ttsDownloadConcurrency.clamp(1, 10);
    final List<Future<void>> workers = [];

    for (int i = 0; i < concurrency; i++) {
      workers.add(_workerLoop(book, settings));
    }

    await Future.wait(workers);

    if (_pendingQueue.isEmpty && _activeDownloadingIndices.isEmpty && _state == DownloadState.downloading) {
      _state = DownloadState.completed;
      _notifyListenersImmediate();
    }
  }

  Future<void> _workerLoop(Book book, AppSettings settings) async {
    while (_pendingQueue.isNotEmpty && _state == DownloadState.downloading && !_cancelRequested) {
      final chapter = _pendingQueue.removeAt(0);
      _activeDownloadingIndices.add(chapter.chapterIndex);
      _chapterStatus[chapter.chapterIndex] = 'downloading';
      _notifyListenersDebounced();

      await _downloadChapterWorker(book, chapter, settings);

      _activeDownloadingIndices.remove(chapter.chapterIndex);
      if (_chapterStatus[chapter.chapterIndex] == 'completed') {
        _completedChaptersCount++;
      }
      _notifyListenersDebounced();
    }
  }

  /// Worker to download a single chapter
  Future<void> _downloadChapterWorker(Book book, Chapter chapter, AppSettings settings) async {
    final chIdx = chapter.chapterIndex;
    final paragraphs = chapter.paragraphs;

    if (paragraphs.isEmpty) {
      _chapterProgress[chIdx] = 1.0;
      _chapterStatus[chIdx] = 'completed';
      return;
    }

    final db = await DatabaseHelper.getInstance();
    final ttsService = await TtsService.getInstance();

    final provider = settings.ttsProvider;
    final voiceName = settings.selectedVoiceName ?? (provider == 'supertonic' ? 'M1' : 'vi-VN-HoaiMyNeural');
    final rate = settings.speechRate;

    final dir = await getOfflineChapterDir(book.uuid, chIdx);
    int totalBytes = 0;
    int downloadedCount = 0;

    for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      if (_cancelRequested || _state == DownloadState.paused) {
        break;
      }

      final rawText = paragraphs[pIdx].trim();
      if (rawText.isEmpty) {
        downloadedCount++;
        _chapterProgress[chIdx] = downloadedCount / paragraphs.length;
        _notifyListenersDebounced();
        continue;
      }

      // Apply pronunciation dictionary rules
      final processedText = ttsService.applyPronunciationRules(rawText);

      final audioPath = p.join(dir.path, 'p_$pIdx.wav');
      final audioFile = File(audioPath);


      if (!audioFile.existsSync() || audioFile.lengthSync() == 0) {
        try {
          if (provider == 'microsoft_edge') {
            final bytesWritten = await EdgeTtsService.synthesizeToFile(
              text: processedText,
              voice: voiceName,
              targetFile: audioFile,
              rate: rate,
            );
            if (bytesWritten > 0) {
              totalBytes += bytesWritten;
              debugPrint('[RAM Trace] Ch $chIdx P $pIdx/${paragraphs.length} streamed (${(bytesWritten / 1024).toStringAsFixed(1)} KB). Process RSS RAM: ${(ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(1)} MB');
            }
          } else if (provider == 'openai') {

            final path = await OpenAiTtsService.synthesizeToWav(processedText, voiceName, rate);
            final generatedFile = File(path);
            if (generatedFile.existsSync()) {
              await generatedFile.copy(audioPath);
              totalBytes += await audioFile.length();
            }
          } else if (provider == 'supertonic') {
            final supertonic = SupertonicService.getInstance();
            await supertonic.initializeEngine(voiceStyle: voiceName);
            final detectedLang = supertonic.detectLanguage(processedText);
            final path = await supertonic.synthesizeToWav(processedText, speed: rate * 2.0, lang: detectedLang);
            if (path != null) {
              final generatedFile = File(path);
              if (generatedFile.existsSync()) {
                await generatedFile.copy(audioPath);
                totalBytes += await audioFile.length();
              }
            }
          }
        } catch (e) {
          debugPrint('[OfflineTtsService] Error downloading paragraph $pIdx of chapter $chIdx: $e');
        }
      } else {
        totalBytes += audioFile.lengthSync();
      }

      downloadedCount++;
      _chapterProgress[chIdx] = downloadedCount / paragraphs.length;
      _notifyListenersDebounced();

      // Nhường Event Loop để Dart VM Garbage Collector có thời gian thu hồi bộ nhớ RAM nhị phân Uint8List
      await Future.microtask(() {});
    }

    if (downloadedCount >= paragraphs.length && !_cancelRequested) {
      _chapterStatus[chIdx] = 'completed';
      _chapterProgress[chIdx] = 1.0;

      // Save OfflineTtsRecord to Isar
      final record = OfflineTtsRecord()
        ..bookUuid = book.uuid
        ..chapterIndex = chIdx
        ..ttsProvider = provider
        ..voiceName = voiceName
        ..speechRate = rate
        ..isCompleted = true
        ..totalParagraphs = paragraphs.length
        ..downloadedParagraphs = downloadedCount
        ..totalSizeBytes = totalBytes
        ..downloadedAt = DateTime.now();

      await db.saveOfflineTtsRecord(record);
    } else if (_chapterStatus[chIdx] != 'completed') {
      _chapterStatus[chIdx] = 'error';
    }

    // Xoá cache văn bản giải nén của chương để nhả RAM lập tức
    chapter.clearCache();
    debugPrint('[RAM Diagnostic] Finished Chapter $chIdx. Process RSS RAM: ${(ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(1)} MB');
  }


  /// Delete offline TTS audio and record for a specific chapter
  Future<void> deleteOfflineTtsForChapter(String bookUuid, int chapterIndex) async {
    try {
      final db = await DatabaseHelper.getInstance();
      await db.deleteOfflineTtsRecord(bookUuid, chapterIndex);

      final dir = await getOfflineChapterDir(bookUuid, chapterIndex);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }

      _chapterStatus.remove(chapterIndex);
      _chapterProgress.remove(chapterIndex);
      notifyListeners();
    } catch (e) {
      debugPrint('[OfflineTtsService] Failed to delete offline TTS for chapter $chapterIndex: $e');
    }
  }

  /// Delete offline TTS audio and records for multiple chapters
  Future<void> deleteOfflineTtsForChapters(String bookUuid, List<int> chapterIndices) async {
    try {
      final db = await DatabaseHelper.getInstance();
      for (final chIdx in chapterIndices) {
        await db.deleteOfflineTtsRecord(bookUuid, chIdx);
        final dir = await getOfflineChapterDir(bookUuid, chIdx);
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
        _chapterStatus.remove(chIdx);
        _chapterProgress.remove(chIdx);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[OfflineTtsService] Failed to delete offline TTS for chapters: $e');
    }
  }

  /// Delete offline TTS audio and records for an entire book

  Future<void> deleteOfflineTtsForBook(String bookUuid) async {
    try {
      final db = await DatabaseHelper.getInstance();
      await db.deleteOfflineTtsRecordsForBook(bookUuid);

      final appDir = await PathHelper.getAppDirectory();
      final dir = Directory(p.join(appDir.path, 'tts_offline', bookUuid));
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }

      _chapterStatus.clear();
      _chapterProgress.clear();
      _currentBookUuid = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[OfflineTtsService] Failed to delete offline TTS for book $bookUuid: $e');
    }
  }
}
