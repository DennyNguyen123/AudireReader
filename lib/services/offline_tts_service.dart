import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/database/database_helper.dart';
import 'package:audire_reader/src/rust/api/models.dart';
import '../core/utils/path_helper.dart';
import 'package:audire_reader/src/rust/api/offline_downloader.dart'
    as rust_downloader;

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

  Set<int> _activeChapterIndices = {};
  Set<int> get activeChapterIndices =>
      UnmodifiableSetView(_activeChapterIndices);

  Set<int> _downloadedChapterIndices = {};
  Set<int> get downloadedChapterIndices => UnmodifiableSetView(_downloadedChapterIndices);

  Set<int> _failedChapterIndices = {};
  Set<int> get failedChapterIndices =>
      UnmodifiableSetView(_failedChapterIndices);

  int _storageSize = 0;
  int get storageSize => _storageSize;

  Map<int, int> _chapterSizes = {};
  Map<int, int> get chapterSizes => UnmodifiableMapView(_chapterSizes);

  Timer? _pollTimer;

  OfflineTtsService._();

  static OfflineTtsService getInstance() {
    _instance ??= OfflineTtsService._();
    return _instance!;
  }

  /// Get chapter directory path for offline storage
  static Future<Directory> getOfflineChapterDir(
    String bookUuid,
    int chapterIndex,
  ) async {
    final appDir = await PathHelper.getAppDirectory();
    final dir = Directory(
      p.join(appDir.path, 'tts_offline', bookUuid, chapterIndex.toString()),
    );
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Delete offline TTS audio and record for a specific chapter
  Future<void> deleteOfflineTtsForChapter(
    String bookUuid,
    int chapterIndex,
  ) async {
    try {
      final db = await DatabaseHelper.getInstance();
      await db.deleteOfflineTtsRecord(bookUuid, chapterIndex);

      final dir = await getOfflineChapterDir(bookUuid, chapterIndex);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }

      notifyListeners();
    } catch (e) {
      debugPrint(
        '[OfflineTtsService] Failed to delete offline TTS for chapter $chapterIndex: $e',
      );
    }
  }

  /// Delete offline TTS audio and records for multiple chapters
  Future<void> deleteOfflineTtsForChapters(
    String bookUuid,
    List<int> chapterIndices,
  ) async {
    try {
      final db = await DatabaseHelper.getInstance();
      for (final chIdx in chapterIndices) {
        await db.deleteOfflineTtsRecord(bookUuid, chIdx);
        final dir = await getOfflineChapterDir(bookUuid, chIdx);
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[OfflineTtsService] Failed to delete offline TTS for chapters: $e',
      );
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

      _currentBookUuid = null;
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[OfflineTtsService] Failed to delete offline TTS for book $bookUuid: $e',
      );
    }
  }

  /// Check if a chapter is downloaded (has valid wav audio files)
  Future<bool> isChapterDownloaded(String bookUuid, int chapterIndex) async {
    try {
      final dir = await getOfflineChapterDir(bookUuid, chapterIndex);
      if (!dir.existsSync()) return false;

      final audioFiles = dir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.wav') || f.path.endsWith('.mp3'),
      );
      return audioFiles.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Fast Rust Native scan for total storage usage and downloaded chapter indices in < 2ms
  Future<rust_downloader.BookStorageInfo?> getBookStorageInfo(
    String bookUuid,
  ) async {
    try {
      final appDir = await PathHelper.getAppDirectory();
      return rust_downloader.getBookStorageInfo(
        baseDir: appDir.path,
        bookUuid: bookUuid,
      );
    } catch (e) {
      debugPrint('[OfflineTtsService] Error scanning book storage info: $e');
      return null;
    }
  }

  /// Convenience wrapper to get downloaded chapter indices
  Future<List<int>> getDownloadedChapterIndices(String bookUuid) async {
    final info = await getBookStorageInfo(bookUuid);
    return info?.chapterIndices ?? [];
  }

  Map<int, String> get chapterStatus => {};
  Map<int, double> get chapterProgress => {};

  /// Start Pure Rust Offline Download Job with 1s Status Polling API
  Future<void> startDownload({
    required Book book,
    required List<Chapter> chapters,
    required AppSettings settings,
  }) async {
    if (_state == DownloadState.downloading) {
      debugPrint('[OfflineTtsService] Download already in progress');
      return;
    }

    _pollTimer?.cancel();
    _currentBookUuid = book.uuid;
    _totalChaptersToDownload = chapters.length;
    _completedChaptersCount = 0;
    _activeChapterIndices.clear();

    _state = DownloadState.downloading;
    WakelockPlus.enable();
    notifyListeners();

    final appDir = await PathHelper.getAppDirectory();
    final provider = settings.ttsProvider;
    final voiceName =
        settings.selectedVoiceName ??
        (provider == 'supertonic' ? 'M1' : 'vi-VN-HoaiMyNeural');
    final rate = settings.speechRate;

    try {
      await rust_downloader.startOfflineDownloadJob(
        bookUuid: book.uuid,
        chapterIndices: chapters.map((c) => c.chapterIndex).toList(),
        concurrency: BigInt.from(settings.ttsDownloadConcurrency.clamp(1, 100)),
        baseDir: appDir.path,
        provider: provider,
        voiceName: voiceName,
        speechRate: rate,
        openaiApiKey: settings.openAiTtsApiKey,
      );

      // Poll Rust Status API every 1 second (Zero Stream Overhead!)
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (_currentBookUuid == null) return;
        final appDir = await PathHelper.getAppDirectory();
        final status = await rust_downloader.getDownloadStatus(
          baseDir: appDir.path,
          bookUuid: _currentBookUuid!,
        );

        _activeChapterIndices = status.activeChapterIndices.toSet();
        _downloadedChapterIndices = status.downloadedChapterIndices.toSet();
        _failedChapterIndices = status.failedChapterIndices.toSet();
        _completedChaptersCount = status.completedChapters.toInt();
        _storageSize = status.totalBytes.toInt();
        _chapterSizes = {
          for (final item in status.chapterSizes)
            item.chapterIndex: item.bytes.toInt()
        };

        for (final log in status.recentLogs) {
          debugPrint('[Rust Status Log] $log');
        }

        if (!status.isRunning && _state == DownloadState.downloading) {
          _state = DownloadState.completed;
          _pollTimer?.cancel();
          WakelockPlus.disable();
        }

        notifyListeners();
      });
    } catch (e) {
      debugPrint('[OfflineTtsService] Failed to start Rust job: $e');
      _state = DownloadState.error;
      WakelockPlus.disable();
      notifyListeners();
    }
  }

  void pauseDownload() {
    if (_state == DownloadState.downloading) {
      _state = DownloadState.paused;
      rust_downloader.pauseOfflineDownload();
      WakelockPlus.disable();
      notifyListeners();
    }
  }

  void resumeDownload(Book book, AppSettings settings) {
    if (_state == DownloadState.paused) {
      _state = DownloadState.downloading;
      rust_downloader.resumeOfflineDownload();
      WakelockPlus.enable();
      notifyListeners();
    }
  }

  void cancelDownload() {
    _pollTimer?.cancel();
    _pollTimer = null;
    rust_downloader.cancelOfflineDownload();
    _state = DownloadState.idle;
    _activeChapterIndices.clear();
    WakelockPlus.disable();
    notifyListeners();
  }
}
