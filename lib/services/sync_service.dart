import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:isar/isar.dart';
import '../core/database/database_helper.dart';
import '../core/utils/path_helper.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/progress.dart';
import 'webdav_service.dart';
import 'logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void print(Object? object) {
  final message = object?.toString() ?? '';
  LogLevel level = LogLevel.info;
  if (message.toLowerCase().contains('error') || 
      message.toLowerCase().contains('failed') || 
      message.toLowerCase().contains('fatal')) {
    level = LogLevel.error;
  } else if (message.toLowerCase().contains('warning') || 
             message.toLowerCase().contains('conflict')) {
    level = LogLevel.warning;
  }
  LoggerService().log(message, tag: 'SYNC', level: level);
}

class SyncService {
  static SyncService? _instance;
  final WebDavService _webdav = WebDavService.getInstance();
  bool _isSyncing = false;
  
  // Lưu trữ trạng thái đồng bộ của các sách (bookUuid -> status)
  final ValueNotifier<Map<String, String>> syncStateNotifier = ValueNotifier({});

  final ValueNotifier<List<Map<String, dynamic>>> cloudBooksNotifier = ValueNotifier([]);
  final ValueNotifier<Set<String>> cloudBookUuidsNotifier = ValueNotifier({});

  SyncService._() {
    _initCache();
  }

  static SyncService getInstance() {
    _instance ??= SyncService._();
    return _instance!;
  }

  Future<void> _initCache() async {
    try {
      const storage = FlutterSecureStorage();
      final cachedJson = await storage.read(key: 'webdav_cached_cloud_books');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> list = json.decode(cachedJson);
        final parsed = list.map((item) => Map<String, dynamic>.from(item)).toList();
        cloudBooksNotifier.value = parsed;
        cloudBookUuidsNotifier.value = parsed.map((item) => item['uuid'] as String).toSet();
      }
    } catch (e) {
      print('[Sync] Error loading cloud books cache: $e');
    }
  }

  Future<void> fetchCloudBooks() async {
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();
      const storage = FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          webDavPassword.isEmpty) {
        cloudBooksNotifier.value = [];
        cloudBookUuidsNotifier.value = {};
        return;
      }

      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);
      final connected = await _webdav.testConnection();
      if (!connected) return;

      final hasIndex = await _webdav.fileExists('/AudireReader/sync_data.json');
      if (hasIndex) {
        final bytes = await _webdav.downloadBytes('/AudireReader/sync_data.json');
        if (bytes != null && bytes.isNotEmpty) {
          final jsonStr = utf8.decode(bytes);
          final cloudSyncData = json.decode(jsonStr) as Map<String, dynamic>;
          final List<dynamic> cloudBooks = cloudSyncData['books'] ?? [];
          final List<Map<String, dynamic>> parsed = cloudBooks
              .map((b) => b is Map<String, dynamic> ? Map<String, dynamic>.from(b) : null)
              .whereType<Map<String, dynamic>>()
              .toList();

          cloudBooksNotifier.value = parsed;
          cloudBookUuidsNotifier.value = parsed.map((b) => b['uuid'] as String).toSet();

          // Save to cache
          await storage.write(key: 'webdav_cached_cloud_books', value: json.encode(parsed));
          print('[Sync] Fetched ${parsed.length} cloud books.');

          // Tải ngầm ảnh bìa của các sách ảo chưa có ở local
          _downloadMissingCoversInBackground(parsed);
        }
      } else {
        cloudBooksNotifier.value = [];
        cloudBookUuidsNotifier.value = {};
        await storage.delete(key: 'webdav_cached_cloud_books');
      }
    } catch (e) {
      print('[Sync] Failed to fetch cloud books: $e');
    }
  }

  Future<void> _downloadMissingCoversInBackground(List<Map<String, dynamic>> cloudBooks) async {
    try {
      final docDir = await PathHelper.getAppDirectory();
      
      for (final cb in cloudBooks) {
        final uuid = cb['uuid'] as String;
        if (cb['hasCover'] == true) {
          final ext = cb['coverExtension'] ?? '.png';
          final localPath = p.join(docDir.path, 'covers', '$uuid$ext');
          final localFile = File(localPath);
          if (!await localFile.exists()) {
            final remotePath = '/AudireReader/covers/$uuid$ext';
            print('[Sync] Downloading missing cover in background for $uuid');
            
            // Create covers dir if not exists
            final coverDir = Directory(p.join(docDir.path, 'covers'));
            if (!await coverDir.exists()) {
              await coverDir.create(recursive: true);
            }
            
            await _webdav.downloadToLocalFile(remotePath, localPath);
          }
        }
      }
    } catch (e) {
      print('[Sync] Background cover download failed: $e');
    }
  }

  bool get isSyncing => _isSyncing;

  void _updateBookSyncStatus(String bookUuid, String status) {
    final newMap = Map<String, String>.from(syncStateNotifier.value);
    if (status == 'success' || status == 'error') {
      // Có thể clear trạng thái sau một thời gian ngắn nếu muốn, hoặc cứ để đó
      // Nếu không muốn nó stuck ở loading, ta cập nhật trạng thái
      newMap[bookUuid] = status;
    } else {
      newMap[bookUuid] = status;
    }
    syncStateNotifier.value = newMap;
    
    // Tự động clear trạng thái sau 3 giây nếu success/error
    if (status == 'success' || status == 'error') {
      Future.delayed(const Duration(seconds: 3), () {
        final currentMap = Map<String, String>.from(syncStateNotifier.value);
        if (currentMap[bookUuid] == status) {
           currentMap.remove(bookUuid);
           syncStateNotifier.value = currentMap;
        }
      });
    }
  }

  /// Thực hiện đồng bộ hóa toàn diện (chỉ đồng bộ tiến trình đọc và chỉ mục sách đám mây)
  Future<SyncResult> sync() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress.');
    }
    _isSyncing = true;
    print('[Sync] Starting progress-only synchronization...');

    try {
      // 1. Chỉ tải danh sách chỉ mục sách mây về (để cập nhật sách ảo trên UI)
      await fetchCloudBooks();
      
      // 2. Đồng bộ tiến trình đọc cho tất cả sách cục bộ thông qua hàm internal
      final db = await DatabaseHelper.getInstance();
      final localBooks = await db.getAllBooks();
      bool progressChanged = false;

      for (final book in localBooks) {
        final res = await _syncBookProgressInternal(book.uuid);
        if (res.status == ProgressSyncStatus.updatedLocal) progressChanged = true;
      }

      _isSyncing = false;
      return SyncResult(
        success: true,
        message: 'Sync completed successfully.',
        localChanged: progressChanged,
      );
    } catch (e) {
      _isSyncing = false;
      print('[Sync] Fatal error during sync: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  /// 1. Đồng bộ Danh mục Sách và Trạng thái Xóa (sync_data.json) công khai (có check lock)
  Future<SyncResult> syncLibrary() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress.');
    }
    _isSyncing = true;
    print('[SyncLibrary] Starting library sync...');
    try {
      final result = await _syncLibraryInternal();
      _isSyncing = false;
      return result;
    } catch (e) {
      _isSyncing = false;
      print('[SyncLibrary] Fatal error: $e');
      return SyncResult(success: false, message: 'Library sync failed: $e');
    }
  }

  /// Hàm nội bộ thực hiện đồng bộ Danh mục Sách (không kiểm tra biến _isSyncing)
  Future<SyncResult> _syncLibraryInternal() async {
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      final storage = const FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          webDavPassword.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'WebDAV sync is not configured or disabled.');
      }

      // 1. Khởi tạo WebDAV Client
      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);
      final connected = await _webdav.testConnection();
      if (!connected) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Failed to connect to WebDAV server. Check settings.');
      }

      // 2. Tự động di chuyển chỉ mục cũ trên WebDAV nếu có
      final hasOldSyncFile = await _webdav.fileExists('/NovelReader/sync_data.json');
      final hasNewSyncFile = await _webdav.fileExists('/AudireReader/sync_data.json');
      if (hasOldSyncFile && !hasNewSyncFile) {
        print('[SyncLibrary] Migrating legacy sync_data.json on WebDAV to AudireReader...');
        final oldBytes = await _webdav.downloadBytes('/NovelReader/sync_data.json');
        if (oldBytes != null && oldBytes.isNotEmpty) {
          await _webdav.mkdir('/AudireReader');
          await _webdav.uploadBytes('/AudireReader/sync_data.json', oldBytes);
        }
      }

      // 3. Đảm bảo các thư mục tồn tại trên WebDAV
      await _webdav.mkdir('/AudireReader');
      await _webdav.mkdir('/AudireReader/covers');
      await _webdav.mkdir('/AudireReader/books');
      await _webdav.mkdir('/AudireReader/progress');

      // Tải và xử lý chỉ mục sách (có hỗ trợ Optimistic Locking retry tối đa 3 lần)
      int retryCount = 0;
      bool syncSuccess = false;
      bool localDatabaseChanged = false;
      String lastSyncError = '';

      while (retryCount < 3 && !syncSuccess) {
        retryCount++;
        print('[SyncLibrary] Attempt $retryCount to sync library index...');

        // Lấy thông tin metadata của file sync_data.json trên server trước để làm base
        String baseLastSyncTime = '';
        final fileMeta = await _webdav.getFileMetadata('/AudireReader/sync_data.json');
        
        Map<String, dynamic> cloudSyncData = {
          'version': 1,
          'lastSyncTime': '',
          'books': [],
          'deleted': []
        };

        final hasSyncFile = fileMeta != null;
        if (hasSyncFile) {
          final bytes = await _webdav.downloadBytes('/AudireReader/sync_data.json');
          if (bytes != null && bytes.isNotEmpty) {
            try {
              final jsonStr = utf8.decode(bytes);
              cloudSyncData = json.decode(jsonStr) as Map<String, dynamic>;
              baseLastSyncTime = cloudSyncData['lastSyncTime'] ?? '';
              print('[SyncLibrary] Loaded cloud index sync data. Base time: $baseLastSyncTime');
            } catch (e) {
              print('[SyncLibrary] Error decoding sync_data.json: $e');
            }
          }
        }

        // Tương thích ngược: Nếu file trên mây cũ có chứa 'progress' cũ, ta sẽ migrate chúng sang các file progress riêng lẻ
        if (cloudSyncData.containsKey('progress')) {
          print('[SyncLibrary] Migrating legacy progress list from sync_data.json to single files...');
          final List<dynamic> legacyProgress = cloudSyncData['progress'] ?? [];
          for (final prog in legacyProgress) {
            if (prog is Map<String, dynamic>) {
              final String bUuid = prog['bookUuid'] ?? '';
              if (bUuid.isNotEmpty) {
                // Tạo file progress riêng trên mây cho sách này
                final jsonBytes = utf8.encode(json.encode(prog));
                await _webdav.uploadBytes('/AudireReader/progress/$bUuid.json', jsonBytes);
              }
            }
          }
          // Xóa mảng progress cũ khỏi bộ nhớ chỉ mục
          cloudSyncData.remove('progress');
        }

        // Lấy danh sách sách ban đầu dưới Local
        var localBooks = await db.getAllBooks();
        final List<Map<String, dynamic>> cloudBooksList = List<Map<String, dynamic>>.from(cloudSyncData['books'] ?? []);
        final List<dynamic> cloudDeletedList = List<dynamic>.from(cloudSyncData['deleted'] ?? []);

        // Dọn dẹp Tombstone (xóa các UUID đã xóa cũ hơn 30 ngày)
        bool tombstoneCleaned = false;
        final DateTime now = DateTime.now();
        final List<Map<String, dynamic>> updatedDeletedList = [];
        
        // Cấu trúc lại deleted list thành dạng object nếu là danh sách String cũ
        for (final item in cloudDeletedList) {
          if (item is String) {
            updatedDeletedList.add({
              'uuid': item,
              'deletedAt': now.toIso8601String()
            });
            tombstoneCleaned = true;
          } else if (item is Map<String, dynamic>) {
            final String deletedAtStr = item['deletedAt'] ?? '';
            final DateTime deletedAt = DateTime.tryParse(deletedAtStr) ?? now;
            if (now.difference(deletedAt).inDays < 30) {
              updatedDeletedList.add(item);
            } else {
              tombstoneCleaned = true;
              print('[SyncLibrary] Cleaned up expired tombstone UUID "${item['uuid']}"');
            }
          }
        }
        
        final List<String> activeDeletedUuids = updatedDeletedList.map((e) => e['uuid'] as String).toList();

        // 3. XỬ LÝ ĐỒNG BỘ XÓA SÁCH (CLOUD -> LOCAL DELETION)
        for (final deletedUuid in activeDeletedUuids) {
          final hasLocalBook = localBooks.any((b) => b.uuid == deletedUuid);
          if (hasLocalBook) {
            print('[SyncLibrary] Deleting book UUID "$deletedUuid" locally (deleted on another device).');
            await db.deleteBook(deletedUuid);
            localDatabaseChanged = true;
          }
        }

        if (localDatabaseChanged) {
          localBooks = await db.getAllBooks();
        }

        bool cloudDatabaseChanged = tombstoneCleaned;

        // 4. ĐỒNG BỘ SÁCH: LOCAL -> CLOUD (Tải sách mới lên mây)
        for (final localBook in localBooks) {
          if (activeDeletedUuids.contains(localBook.uuid)) {
            continue;
          }
          final bool existsOnCloud = cloudBooksList.any((b) =>
              b['uuid'] == localBook.uuid ||
              (b['title'] == localBook.title && b['author'] == localBook.author));

          if (!existsOnCloud) {
            print('[SyncLibrary] Uploading new local book to cloud: "${localBook.title}"');
            _updateBookSyncStatus(localBook.uuid, 'syncing');
            try {
              // A. Upload Ảnh bìa
              bool hasCover = false;
              if (localBook.coverPath != null) {
                final coverFile = File(localBook.coverPath!);
                if (await coverFile.exists()) {
                  final ext = p.extension(localBook.coverPath!);
                  final remoteCoverPath = '/AudireReader/covers/${localBook.uuid}$ext';
                  final uploadCoverOk = await _webdav.uploadLocalFile(localBook.coverPath!, remoteCoverPath);
                  hasCover = uploadCoverOk;
                }
              }

              // B. Upload Nội dung chương truyện
              final chapters = await db.getChaptersForBook(localBook.uuid);
              final bookContent = {
                'uuid': localBook.uuid,
                'title': localBook.title,
                'author': localBook.author,
                'totalChapters': localBook.totalChapters,
                'coverExtension': localBook.coverPath != null ? p.extension(localBook.coverPath!) : null,
                'dateAdded': localBook.dateAdded.toIso8601String(),
                'chapters': chapters.map((c) => {
                  'chapterIndex': c.chapterIndex,
                  'title': c.title,
                  'paragraphs': c.paragraphs
                }).toList()
              };

              final jsonBytes = utf8.encode(json.encode(bookContent));
              final uploadContentOk = await _webdav.uploadBytes('/AudireReader/books/${localBook.uuid}.json', jsonBytes);

              if (uploadContentOk) {
                cloudBooksList.add({
                  'uuid': localBook.uuid,
                  'title': localBook.title,
                  'author': localBook.author,
                  'totalChapters': localBook.totalChapters,
                  'dateAdded': localBook.dateAdded.toIso8601String(),
                  'hasCover': hasCover,
                  'coverExtension': localBook.coverPath != null ? p.extension(localBook.coverPath!) : null,
                });
                cloudDatabaseChanged = true;
                print('[SyncLibrary] Successfully uploaded book: "${localBook.title}"');
                _updateBookSyncStatus(localBook.uuid, 'success');
              } else {
                _updateBookSyncStatus(localBook.uuid, 'error');
              }
            } catch (e) {
              print('[SyncLibrary] Error uploading book "${localBook.title}": $e');
              _updateBookSyncStatus(localBook.uuid, 'error');
            }
          }
        }

        // 5. ĐỒNG BỘ SÁCH: CLOUD -> LOCAL (Tải sách từ mây về máy mới)
        final docDir = await PathHelper.getAppDirectory();
        for (final cloudBook in cloudBooksList) {
          if (activeDeletedUuids.contains(cloudBook['uuid'])) {
            continue;
          }
          final bool existsLocally = localBooks.any((b) =>
              b.uuid == cloudBook['uuid'] ||
              (b.title == cloudBook['title'] && b.author == cloudBook['author']));

          if (!existsLocally) {
            print('[SyncLibrary] Downloading book from cloud: "${cloudBook['title']}"');
            final bookUuid = cloudBook['uuid'];
            _updateBookSyncStatus(bookUuid, 'syncing');
            try {
              var bytes = await _webdav.downloadBytes('/AudireReader/books/$bookUuid.json');
              if (bytes == null || bytes.isEmpty) {
                // Fallback sang NovelReader cũ trên WebDAV
                bytes = await _webdav.downloadBytes('/NovelReader/books/$bookUuid.json');
                if (bytes != null && bytes.isNotEmpty) {
                  // Upload sang AudireReader mới để lưu trữ lại
                  await _webdav.uploadBytes('/AudireReader/books/$bookUuid.json', bytes);
                }
              }

              if (bytes != null && bytes.isNotEmpty) {
                final jsonStr = utf8.decode(bytes);
                final bookContent = json.decode(jsonStr) as Map<String, dynamic>;

                // Tải ảnh bìa
                String? localCoverPath;
                if (cloudBook['hasCover'] == true) {
                  final ext = cloudBook['coverExtension'] ?? '.png';
                  final coverDir = Directory(p.join(docDir.path, 'covers'));
                  if (!await coverDir.exists()) {
                    await coverDir.create(recursive: true);
                  }
                  final localPath = p.join(coverDir.path, '$bookUuid$ext');
                  final remotePath = '/AudireReader/covers/$bookUuid$ext';
                  
                  var downloadCoverOk = await _webdav.downloadToLocalFile(remotePath, localPath);
                  if (!downloadCoverOk) {
                    // Fallback sang NovelReader cũ
                    final oldRemotePath = '/NovelReader/covers/$bookUuid$ext';
                    downloadCoverOk = await _webdav.downloadToLocalFile(oldRemotePath, localPath);
                    if (downloadCoverOk) {
                      await _webdav.uploadLocalFile(localPath, remotePath);
                    }
                  }
                  if (downloadCoverOk) {
                    localCoverPath = localPath;
                  }
                }

                // Lưu Book
                final newBook = Book()
                  ..uuid = bookUuid
                  ..title = cloudBook['title']
                  ..author = cloudBook['author']
                  ..coverPath = localCoverPath
                  ..totalChapters = cloudBook['totalChapters']
                  ..dateAdded = DateTime.tryParse(cloudBook['dateAdded'] ?? '') ?? DateTime.now();

                // Lưu Chapters
                final List<Chapter> newChapters = [];
                final parsedChapters = bookContent['chapters'] as List<dynamic>;
                for (final c in parsedChapters) {
                  final chMap = c as Map<String, dynamic>;
                  final newCh = Chapter()
                    ..bookUuid = bookUuid
                    ..chapterIndex = chMap['chapterIndex']
                    ..title = chMap['title']
                    ..paragraphs = List<String>.from(chMap['paragraphs'] ?? []);
                  newChapters.add(newCh);
                }

                await db.saveBook(newBook);
                await db.saveChapters(newChapters);
                localDatabaseChanged = true;
                print('[SyncLibrary] Restored book locally: "${newBook.title}"');
                _updateBookSyncStatus(bookUuid, 'success');
              } else {
                _updateBookSyncStatus(bookUuid, 'error');
              }
            } catch (e) {
              print('[SyncLibrary] Error downloading book "${cloudBook['title']}": $e');
              _updateBookSyncStatus(cloudBook['uuid'], 'error');
            }
          }
        }

        // 6. GHI LẠI CHỈ MỤC MỚI (Optimistic Locking)
        if (cloudDatabaseChanged || !hasSyncFile) {
          // Kiểm tra xem trong thời gian ta sync, tệp trên server có bị thiết bị khác ghi đè hay chưa
          final currentFileMeta = await _webdav.getFileMetadata('/AudireReader/sync_data.json');
          String currentServerTime = '';
          
          if (currentFileMeta != null) {
            // Tải nhanh file chỉ mục để so sánh lastSyncTime chuẩn xác nhất
            final checkBytes = await _webdav.downloadBytes('/AudireReader/sync_data.json');
            if (checkBytes != null && checkBytes.isNotEmpty) {
              try {
                final checkJson = json.decode(utf8.decode(checkBytes)) as Map<String, dynamic>;
                currentServerTime = checkJson['lastSyncTime'] ?? '';
              } catch (_) {}
            }
          }

          if (currentServerTime != baseLastSyncTime) {
            // Có xung đột ghi đè đồng thời!
            print('[SyncLibrary] Conflict detected! Server index was updated (Server: $currentServerTime, Local Base: $baseLastSyncTime). Retrying merge...');
            lastSyncError = 'Conflict detected. Retrying...';
            // Tiếp tục vòng lặp while để tải dữ liệu mới nhất từ server và merge lại
            continue;
          }

          // Không có xung đột, tiến hành upload ghi đè an toàn
          cloudSyncData['books'] = cloudBooksList;
          cloudSyncData['deleted'] = updatedDeletedList;
          cloudSyncData['lastSyncTime'] = DateTime.now().toIso8601String();

          final jsonBytes = utf8.encode(json.encode(cloudSyncData));
          final uploadOk = await _webdav.uploadBytes('/AudireReader/sync_data.json', jsonBytes);
          if (uploadOk) {
            print('[SyncLibrary] Successfully uploaded sync_data.json to cloud.');
            syncSuccess = true;
          } else {
            lastSyncError = 'Failed to upload sync_data.json to cloud.';
          }
        } else {
          // Không có thay đổi gì trên mây
          syncSuccess = true;
        }
      }

      if (!syncSuccess) {
        return SyncResult(success: false, message: 'Sync failed: $lastSyncError');
      }

      // 7. CẬP NHẬT CẤU HÌNH CỤC BỘ
      settings.webDavLastSync = DateTime.now();
      await db.saveSettings(settings);

      return SyncResult(
        success: true,
        message: 'Library sync completed successfully.',
        localChanged: localDatabaseChanged,
      );
    } catch (e) {
      print('[SyncLibrary] Fatal error: $e');
      return SyncResult(success: false, message: 'Library sync failed: $e');
    }
  }

  /// 2. Đồng bộ Tiến trình đọc của riêng một cuốn sách
  /// Sử dụng tệp siêu nhẹ `/progress/{bookUuid}.json`
  /// Trả về ProgressSyncStatus
  Future<ProgressSyncResult> syncBookProgress(String bookUuid) async {
    return await _syncBookProgressInternal(bookUuid);
  }

  /// Hàm nội bộ thực hiện đồng bộ Tiến trình đọc (không check lock)
  Future<ProgressSyncResult> _syncBookProgressInternal(String bookUuid) async {
    _updateBookSyncStatus(bookUuid, 'syncing');
    try {
      final res = await __syncBookProgressInternal(bookUuid);
      _updateBookSyncStatus(bookUuid, 'success');
      return res;
    } catch (e) {
      _updateBookSyncStatus(bookUuid, 'error');
      print('[SyncProgressWrapper] Error: $e');
      return ProgressSyncResult(status: ProgressSyncStatus.error);
    }
  }

  Future<ProgressSyncResult> __syncBookProgressInternal(String bookUuid) async {
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      final storage = const FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          webDavPassword.isEmpty) {
        return ProgressSyncResult(status: ProgressSyncStatus.error);
      }

      final deviceId = settings.deviceId ?? '';
      final deviceName = settings.deviceName ?? 'Unknown Device';

      // Đảm bảo client đã khởi tạo
      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);

      final localProg = await db.getProgress(bookUuid);
      final String remotePath = '/AudireReader/progress/$bookUuid.json';
      final String oldRemotePath = '/NovelReader/progress/$bookUuid.json';

      // 1. Tải tiến trình trên mây về (nếu có)
      Map<String, dynamic>? cloudProg;
      var fileMeta = await _webdav.getFileMetadata(remotePath);
      
      if (fileMeta == null) {
        // Fallback NovelReader
        final oldMeta = await _webdav.getFileMetadata(oldRemotePath);
        if (oldMeta != null) {
          final bytes = await _webdav.downloadBytes(oldRemotePath);
          if (bytes != null && bytes.isNotEmpty) {
            try {
              cloudProg = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
              await _webdav.uploadBytes(remotePath, bytes);
            } catch (_) {}
          }
        }
      } else {
        final bytes = await _webdav.downloadBytes(remotePath);
        if (bytes != null && bytes.isNotEmpty) {
          try {
            cloudProg = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
          } catch (e) {
            print('[SyncProgress] Error decoding progress for book $bookUuid: $e');
          }
        }
      }

      // 2. So sánh và xử lý đồng bộ
      if (cloudProg != null) {
        final cloudDeviceId = cloudProg['deviceId'] as String?;
        
        final localCh = localProg?.currentChapterIndex ?? 0;
        final localPara = localProg?.currentParagraphIndex ?? 0;

        final cloudCh = cloudProg['currentChapterIndex'] ?? 0;
        final cloudPara = cloudProg['currentParagraphIndex'] ?? 0;

        // Nếu cloud do chính máy này update lần cuối, ta coi như an toàn, auto ghi đè (nếu local mới hơn thì đẩy lên)
        if (cloudDeviceId == deviceId) {
          if (_isCloudProgressNewer(cloudProg, localProg)) {
             // Dữ liệu trên mây (do chính máy này đẩy lên trước đó hoặc sync nhầm?) mới hơn -> đè local
             _updateLocalFromCloud(bookUuid, cloudProg, localProg, db);
             return ProgressSyncResult(status: ProgressSyncStatus.updatedLocal, cloudProgress: cloudProg);
          } else if (!_isCloudProgressEqual(cloudProg, localProg!)) {
             // Local mới hơn -> đẩy lên mây
             await _uploadLocalToCloud(remotePath, bookUuid, localProg, deviceId, deviceName);
             return ProgressSyncResult(status: ProgressSyncStatus.uploadedToCloud);
          }
          return ProgressSyncResult(status: ProgressSyncStatus.upToDate);
        } else {
          // Cloud do máy KHÁC update
          final bool isCloudNewer = _isCloudProgressNewer(cloudProg, localProg);
          final bool isLocalNewer = _isLocalProgressNewer(cloudProg, localProg);

          if (isCloudNewer && !isLocalNewer) {
            // Máy kia đọc xa hơn và local không xa hơn -> an toàn để đè local
            _updateLocalFromCloud(bookUuid, cloudProg, localProg, db);
            return ProgressSyncResult(status: ProgressSyncStatus.updatedLocal, cloudProgress: cloudProg);
          } else if (isLocalNewer && !isCloudNewer) {
            // Máy này đọc xa hơn máy kia -> an toàn để đè mây
            await _uploadLocalToCloud(remotePath, bookUuid, localProg!, deviceId, deviceName);
            return ProgressSyncResult(status: ProgressSyncStatus.uploadedToCloud);
          } else if (isCloudNewer && isLocalNewer || (cloudCh != localCh || cloudPara != localPara)) {
            // CONFLICT! Ví dụ: Máy A chương 8, Máy B chương 10. Nhưng thời gian lộn xộn, hoặc rẽ nhánh.
            // Báo conflict ra ngoài
            return ProgressSyncResult(status: ProgressSyncStatus.conflict, cloudProgress: cloudProg);
          } else {
            // Bằng nhau
            return ProgressSyncResult(status: ProgressSyncStatus.upToDate);
          }
        }
      } else {
        // Mây chưa có tiến trình -> Đẩy Local lên
        if (localProg != null) {
          await _uploadLocalToCloud(remotePath, bookUuid, localProg, deviceId, deviceName);
          return ProgressSyncResult(status: ProgressSyncStatus.uploadedToCloud);
        }
      }
    } catch (e) {
      print('[SyncProgress] Failed to sync progress for book $bookUuid: $e');
    }
    return ProgressSyncResult(status: ProgressSyncStatus.error);
  }

  Future<void> _uploadLocalToCloud(String remotePath, String bookUuid, ReadingProgress localProg, String deviceId, String deviceName) async {
    final localJson = {
      'bookUuid': bookUuid,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'currentChapterIndex': localProg.currentChapterIndex,
      'currentParagraphIndex': localProg.currentParagraphIndex,
      'currentCharacterOffset': localProg.currentCharacterOffset,
      'lastRead': localProg.lastRead.toIso8601String(),
    };
    final jsonBytes = utf8.encode(json.encode(localJson));
    await _webdav.uploadBytes(remotePath, jsonBytes);

    await _addSyncHistoryEntry(
      bookUuid: bookUuid,
      action: 'push',
      chapterIndex: localProg.currentChapterIndex,
      paragraphIndex: localProg.currentParagraphIndex,
      deviceIdOverride: deviceId,
      deviceNameOverride: deviceName,
    );
  }

  Future<void> forceUploadLocalProgress(String bookUuid, ReadingProgress localProg, String deviceId, String deviceName) async {
    final String remotePath = '/AudireReader/progress/$bookUuid.json';
    await _uploadLocalToCloud(remotePath, bookUuid, localProg, deviceId, deviceName);
  }

  Future<void> forceUpdateLocalFromCloud(String bookUuid, Map<String, dynamic> cloudProg, ReadingProgress? localProg, DatabaseHelper db) async {
    await _updateLocalFromCloud(bookUuid, cloudProg, localProg, db);
  }

  Future<void> _updateLocalFromCloud(String bookUuid, Map<String, dynamic> cloudProg, ReadingProgress? localProg, DatabaseHelper db) async {
    final DateTime cloudLastRead = DateTime.tryParse(cloudProg['lastRead'] ?? '') ?? DateTime.now();
    final targetProg = localProg ?? (ReadingProgress()..bookUuid = bookUuid);
    targetProg.currentChapterIndex = cloudProg['currentChapterIndex'] ?? 0;
    targetProg.currentParagraphIndex = cloudProg['currentParagraphIndex'] ?? 0;
    targetProg.currentCharacterOffset = cloudProg['currentCharacterOffset'] ?? 0;
    targetProg.lastRead = cloudLastRead;
    await db.saveProgress(targetProg);

    await _addSyncHistoryEntry(
      bookUuid: bookUuid,
      action: 'pull',
      chapterIndex: targetProg.currentChapterIndex,
      paragraphIndex: targetProg.currentParagraphIndex,
      deviceIdOverride: cloudProg['deviceId'] as String?,
      deviceNameOverride: cloudProg['deviceName'] as String?,
    );
  }

  bool _isLocalProgressNewer(Map<String, dynamic> cloudProg, ReadingProgress? localProg) {
    if (localProg == null) return false;
    final int cloudCh = cloudProg['currentChapterIndex'] ?? 0;
    final int cloudPara = cloudProg['currentParagraphIndex'] ?? 0;
    final DateTime cloudTime = DateTime.tryParse(cloudProg['lastRead'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    final int localCh = localProg.currentChapterIndex;
    final int localPara = localProg.currentParagraphIndex;
    final DateTime localTime = localProg.lastRead;

    if (localCh > cloudCh) return true;
    if (localCh < cloudCh) return false;
    if (localPara > cloudPara) return true;
    if (localPara < cloudPara) return false;
    return localTime.isAfter(cloudTime);
  }


  /// Thuật toán so sánh tiến trình đọc thông minh chống lệch giờ hệ thống
  /// Ưu tiên vị trí chương/đoạn lớn hơn trước, nếu bằng nhau mới so timestamp
  bool _isCloudProgressNewer(Map<String, dynamic> cloudProg, ReadingProgress? localProg) {
    if (localProg == null) return true;

    final int cloudCh = cloudProg['currentChapterIndex'] ?? 0;
    final int cloudPara = cloudProg['currentParagraphIndex'] ?? 0;
    final DateTime cloudTime = DateTime.tryParse(cloudProg['lastRead'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    final int localCh = localProg.currentChapterIndex;
    final int localPara = localProg.currentParagraphIndex;
    final DateTime localTime = localProg.lastRead;

    // 1. So sánh vị trí đọc (Chương)
    if (cloudCh > localCh) return true;
    if (cloudCh < localCh) return false;

    // 2. So sánh vị trí đọc (Đoạn)
    if (cloudPara > localPara) return true;
    if (cloudPara < localPara) return false;

    // 3. Nếu vị trí giống hệt nhau, so sánh timestamp lastRead
    return cloudTime.isAfter(localTime);
  }

  /// Kiểm tra xem tiến trình mây và local có hoàn toàn giống hệt nhau không
  bool _isCloudProgressEqual(Map<String, dynamic> cloudProg, ReadingProgress localProg) {
    final int cloudCh = cloudProg['currentChapterIndex'] ?? 0;
    final int cloudPara = cloudProg['currentParagraphIndex'] ?? 0;
    final int cloudOffset = cloudProg['currentCharacterOffset'] ?? 0;

    return cloudCh == localProg.currentChapterIndex &&
        cloudPara == localProg.currentParagraphIndex &&
        cloudOffset == localProg.currentCharacterOffset;
  }

  /// Lực đẩy Local lên Cloud (Ghi đè Cloud bằng dữ liệu máy này)
  Future<SyncResult> forcePush({bool progressOnly = true}) async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress.');
    }
    _isSyncing = true;
    print('[Sync] Force pushing local library to cloud (progressOnly: $progressOnly)...');

    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      final storage = const FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          webDavPassword.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'WebDAV sync is not configured or disabled.');
      }

      // 1. Init WebDAV client
      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);
      final connected = await _webdav.testConnection();
      if (!connected) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Failed to connect to WebDAV server. Check settings.');
      }

      // 2. Ensure directories exist on WebDAV
      await _webdav.mkdir('/AudireReader');
      await _webdav.mkdir('/AudireReader/covers');
      await _webdav.mkdir('/AudireReader/books');
      await _webdav.mkdir('/AudireReader/progress');

      // Get local books
      final localBooks = await db.getAllBooks();
      final String deviceId = settings.deviceId ?? '';
      final String deviceName = settings.deviceName ?? 'Unknown Device';

      if (progressOnly) {
        // PROGRESS ONLY SYNC FLOW
        for (final localBook in localBooks) {
          print('[Sync] Force Push Progress: "${localBook.title}"');
          _updateBookSyncStatus(localBook.uuid, 'syncing');
          try {
            final localProg = await db.getProgress(localBook.uuid);
            if (localProg != null) {
              final String remoteProgressPath = '/AudireReader/progress/${localBook.uuid}.json';
              await _uploadLocalToCloud(remoteProgressPath, localBook.uuid, localProg, deviceId, deviceName);
            }
            _updateBookSyncStatus(localBook.uuid, 'success');
          } catch (e) {
            print('[Sync] Error force pushing progress for "${localBook.title}": $e');
            _updateBookSyncStatus(localBook.uuid, 'error');
          }
        }
      } else {
        // FULL SYNC FLOW (WITH OPTIMIZATION)
        // A. Read old index to find orphaned cloud books
        List<String> cloudUuidsToDelete = [];
        final fileMeta = await _webdav.getFileMetadata('/AudireReader/sync_data.json');
        if (fileMeta != null) {
          final bytes = await _webdav.downloadBytes('/AudireReader/sync_data.json');
          if (bytes != null && bytes.isNotEmpty) {
            try {
              final jsonStr = utf8.decode(bytes);
              final oldCloudData = json.decode(jsonStr) as Map<String, dynamic>;
              final List<dynamic> oldCloudBooks = oldCloudData['books'] ?? [];
              for (final b in oldCloudBooks) {
                if (b is Map<String, dynamic> && b['uuid'] != null) {
                  cloudUuidsToDelete.add(b['uuid'] as String);
                }
              }
            } catch (_) {}
          }
        }

        // Exclude local books from deletion
        for (final localBook in localBooks) {
          cloudUuidsToDelete.remove(localBook.uuid);
        }

        // B. Delete orphaned books on cloud
        for (final deleteUuid in cloudUuidsToDelete) {
          print('[Sync] Force Push: Deleting orphan book "$deleteUuid" from cloud');
          await _webdav.remove('/AudireReader/books/$deleteUuid.json');
          await _webdav.remove('/AudireReader/progress/$deleteUuid.json');
          for (final ext in ['.png', '.jpg', '.jpeg']) {
            await _webdav.remove('/AudireReader/covers/$deleteUuid$ext');
          }
        }

        // C. Upload local books and progress
        final List<Map<String, dynamic>> newCloudBooksList = [];
        for (final localBook in localBooks) {
          print('[Sync] Force Push: Syncing book "${localBook.title}"');
          _updateBookSyncStatus(localBook.uuid, 'syncing');

          try {
            // Optimization: Only upload book and cover if they do not exist on cloud
            final String remoteBookPath = '/AudireReader/books/${localBook.uuid}.json';
            final hasRemoteBook = await _webdav.fileExists(remoteBookPath);

            bool hasCover = false;
            if (localBook.coverPath != null) {
              final ext = p.extension(localBook.coverPath!);
              final remoteCoverPath = '/AudireReader/covers/${localBook.uuid}$ext';
              final hasRemoteCover = await _webdav.fileExists(remoteCoverPath);

              if (!hasRemoteCover) {
                final coverFile = File(localBook.coverPath!);
                if (await coverFile.exists()) {
                  final uploadCoverOk = await _webdav.uploadLocalFile(localBook.coverPath!, remoteCoverPath);
                  hasCover = uploadCoverOk;
                }
              } else {
                hasCover = true;
              }
            }

            bool uploadContentOk = true;
            if (!hasRemoteBook) {
              final chapters = await db.getChaptersForBook(localBook.uuid);
              final bookContent = {
                'uuid': localBook.uuid,
                'title': localBook.title,
                'author': localBook.author,
                'totalChapters': localBook.totalChapters,
                'coverExtension': localBook.coverPath != null ? p.extension(localBook.coverPath!) : null,
                'dateAdded': localBook.dateAdded.toIso8601String(),
                'chapters': chapters.map((c) => {
                  'chapterIndex': c.chapterIndex,
                  'title': c.title,
                  'paragraphs': c.paragraphs
                }).toList()
              };

              final jsonBytes = utf8.encode(json.encode(bookContent));
              uploadContentOk = await _webdav.uploadBytes(remoteBookPath, jsonBytes);
            }

            if (uploadContentOk) {
              newCloudBooksList.add({
                'uuid': localBook.uuid,
                'title': localBook.title,
                'author': localBook.author,
                'totalChapters': localBook.totalChapters,
                'dateAdded': localBook.dateAdded.toIso8601String(),
                'hasCover': hasCover,
                'coverExtension': localBook.coverPath != null ? p.extension(localBook.coverPath!) : null,
              });

              // Always upload progress
              final localProg = await db.getProgress(localBook.uuid);
              if (localProg != null) {
                final String remoteProgressPath = '/AudireReader/progress/${localBook.uuid}.json';
                await _uploadLocalToCloud(remoteProgressPath, localBook.uuid, localProg, deviceId, deviceName);
              }

              _updateBookSyncStatus(localBook.uuid, 'success');
            } else {
              _updateBookSyncStatus(localBook.uuid, 'error');
            }
          } catch (e) {
            print('[Sync] Error force uploading book "${localBook.title}": $e');
            _updateBookSyncStatus(localBook.uuid, 'error');
          }
        }

        // D. Overwrite sync_data.json
        final Map<String, dynamic> newCloudSyncData = {
          'version': 1,
          'lastSyncTime': DateTime.now().toIso8601String(),
          'books': newCloudBooksList,
          'deleted': []
        };

        final jsonBytes = utf8.encode(json.encode(newCloudSyncData));
        await _webdav.uploadBytes('/AudireReader/sync_data.json', jsonBytes);
      }

      // 3. Update local settings
      settings.webDavLastSync = DateTime.now();
      await db.saveSettings(settings);

      _isSyncing = false;
      return SyncResult(success: true, message: 'Force push completed successfully.');
    } catch (e) {
      _isSyncing = false;
      print('[Sync] Force push fatal error: $e');
      return SyncResult(success: false, message: 'Force push failed: $e');
    }
  }

  /// Lực kéo Cloud về Local (Ghi đè Local bằng dữ liệu trên Cloud)
  Future<SyncResult> forcePull({bool progressOnly = true}) async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress.');
    }
    _isSyncing = true;
    print('[Sync] Force pulling cloud library to local (progressOnly: $progressOnly)...');

    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      final storage = const FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          webDavPassword.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'WebDAV sync is not configured or disabled.');
      }

      // 1. Init WebDAV client
      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);
      final connected = await _webdav.testConnection();
      if (!connected) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Failed to connect to WebDAV server. Check settings.');
      }

      // 2. Download sync_data.json
      final fileMeta = await _webdav.getFileMetadata('/AudireReader/sync_data.json');
      if (fileMeta == null) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'No sync data found on cloud server to pull.');
      }

      final bytes = await _webdav.downloadBytes('/AudireReader/sync_data.json');
      if (bytes == null || bytes.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Cloud sync index file is empty.');
      }

      final jsonStr = utf8.decode(bytes);
      final cloudSyncData = json.decode(jsonStr) as Map<String, dynamic>;
      final List<Map<String, dynamic>> cloudBooksList = List<Map<String, dynamic>>.from(cloudSyncData['books'] ?? []);

      // Get local books
      var localBooks = await db.getAllBooks();
      bool localDatabaseChanged = false;

      if (progressOnly) {
        // PROGRESS ONLY SYNC FLOW
        for (final localBook in localBooks) {
          print('[Sync] Force Pull Progress: "${localBook.title}"');
          _updateBookSyncStatus(localBook.uuid, 'syncing');
          try {
            final String remoteProgressPath = '/AudireReader/progress/${localBook.uuid}.json';
            final progressBytes = await _webdav.downloadBytes(remoteProgressPath);
            if (progressBytes != null && progressBytes.isNotEmpty) {
              final progressJson = json.decode(utf8.decode(progressBytes)) as Map<String, dynamic>;
              final localProg = await db.getProgress(localBook.uuid);
              await _updateLocalFromCloud(localBook.uuid, progressJson, localProg, db);
              localDatabaseChanged = true;
            }
            _updateBookSyncStatus(localBook.uuid, 'success');
          } catch (e) {
            print('[Sync] Error force pulling progress for "${localBook.title}": $e');
            _updateBookSyncStatus(localBook.uuid, 'error');
          }
        }
      } else {
        // FULL SYNC FLOW (WITH OPTIMIZATION)
        // A. Delete local books not on cloud
        final List<String> cloudUuids = cloudBooksList.map((b) => b['uuid'] as String).toList();
        for (final localBook in localBooks) {
          if (!cloudUuids.contains(localBook.uuid)) {
            print('[Sync] Force Pull: Deleting local book "${localBook.title}" (not in cloud)');
            await db.deleteBook(localBook.uuid);
            localDatabaseChanged = true;
          }
        }

        if (localDatabaseChanged) {
          localBooks = await db.getAllBooks();
        }

        // B. Download books and progress
        final docDir = await PathHelper.getAppDirectory();
        for (final cloudBook in cloudBooksList) {
          final bookUuid = cloudBook['uuid'];
          print('[Sync] Force Pull: Restoring/updating book "${cloudBook['title']}"');
          _updateBookSyncStatus(bookUuid, 'syncing');

          try {
            final existingBook = await db.getBookByUuid(bookUuid);

            // Optimization: Only download book content if not present locally
            bool downloadSuccess = true;
            if (existingBook == null) {
              final bookBytes = await _webdav.downloadBytes('/AudireReader/books/$bookUuid.json');
              if (bookBytes != null && bookBytes.isNotEmpty) {
                final bookJsonStr = utf8.decode(bookBytes);
                final bookContent = json.decode(bookJsonStr) as Map<String, dynamic>;

                // Download cover
                String? localCoverPath;
                if (cloudBook['hasCover'] == true) {
                  final ext = cloudBook['coverExtension'] ?? '.png';
                  final coverDir = Directory(p.join(docDir.path, 'covers'));
                  if (!await coverDir.exists()) {
                    await coverDir.create(recursive: true);
                  }
                  final localPath = p.join(coverDir.path, '$bookUuid$ext');
                  final remotePath = '/AudireReader/covers/$bookUuid$ext';
                  
                  final downloadCoverOk = await _webdav.downloadToLocalFile(remotePath, localPath);
                  if (downloadCoverOk) {
                    localCoverPath = localPath;
                  }
                }

                // Save Book
                final newBook = Book()
                  ..uuid = bookUuid
                  ..title = cloudBook['title']
                  ..author = cloudBook['author']
                  ..coverPath = localCoverPath
                  ..totalChapters = cloudBook['totalChapters']
                  ..dateAdded = DateTime.tryParse(cloudBook['dateAdded'] ?? '') ?? DateTime.now();

                // Save Chapters
                final List<Chapter> newChapters = [];
                final parsedChapters = bookContent['chapters'] as List<dynamic>;
                for (final c in parsedChapters) {
                  final chMap = c as Map<String, dynamic>;
                  final newCh = Chapter()
                    ..bookUuid = bookUuid
                    ..chapterIndex = chMap['chapterIndex']
                    ..title = chMap['title']
                    ..paragraphs = List<String>.from(chMap['paragraphs'] ?? []);
                  newChapters.add(newCh);
                }

                await db.saveBook(newBook);
                await db.saveChapters(newChapters);
                localDatabaseChanged = true;
              } else {
                downloadSuccess = false;
              }
            } else {
              // Overwrite book content to align with cloud
              final bookBytes = await _webdav.downloadBytes('/AudireReader/books/$bookUuid.json');
              if (bookBytes != null && bookBytes.isNotEmpty) {
                final bookJsonStr = utf8.decode(bookBytes);
                final bookContent = json.decode(bookJsonStr) as Map<String, dynamic>;

                // Save Book (overwrite using existingBook.id)
                final newBook = Book()
                  ..id = existingBook.id
                  ..uuid = bookUuid
                  ..title = cloudBook['title']
                  ..author = cloudBook['author']
                  ..coverPath = existingBook.coverPath
                  ..totalChapters = cloudBook['totalChapters']
                  ..dateAdded = DateTime.tryParse(cloudBook['dateAdded'] ?? '') ?? DateTime.now();

                // Clear old chapters
                await db.isar.writeTxn(() async {
                  await db.isar.chapters.filter().bookUuidEqualTo(bookUuid).deleteAll();
                });

                // Save new Chapters
                final List<Chapter> newChapters = [];
                final parsedChapters = bookContent['chapters'] as List<dynamic>;
                for (final c in parsedChapters) {
                  final chMap = c as Map<String, dynamic>;
                  final newCh = Chapter()
                    ..bookUuid = bookUuid
                    ..chapterIndex = chMap['chapterIndex']
                    ..title = chMap['title']
                    ..paragraphs = List<String>.from(chMap['paragraphs'] ?? []);
                  newChapters.add(newCh);
                }

                await db.saveBook(newBook);
                await db.saveChapters(newChapters);
                localDatabaseChanged = true;
              }
            }

            if (downloadSuccess) {
              // Always download progress
              final String remoteProgressPath = '/AudireReader/progress/$bookUuid.json';
              final progressBytes = await _webdav.downloadBytes(remoteProgressPath);
              if (progressBytes != null && progressBytes.isNotEmpty) {
                try {
                  final progressJson = json.decode(utf8.decode(progressBytes)) as Map<String, dynamic>;
                  final localProg = await db.getProgress(bookUuid);
                  await _updateLocalFromCloud(bookUuid, progressJson, localProg, db);
                  localDatabaseChanged = true;
                } catch (e) {
                  print('[Sync] Error loading progress for $bookUuid during force pull: $e');
                }
              }
              _updateBookSyncStatus(bookUuid, 'success');
            } else {
              _updateBookSyncStatus(bookUuid, 'error');
            }
          } catch (e) {
            print('[Sync] Error force downloading book "${cloudBook['title']}": $e');
            _updateBookSyncStatus(bookUuid, 'error');
          }
        }
      }

      // Update local settings
      settings.webDavLastSync = DateTime.now();
      await db.saveSettings(settings);

      _isSyncing = false;
      return SyncResult(
        success: true,
        message: 'Force pull completed successfully.',
        localChanged: localDatabaseChanged,
      );
    } catch (e) {
      _isSyncing = false;
      print('[Sync] Force pull fatal error: $e');
      return SyncResult(success: false, message: 'Force pull failed: $e');
    }
  }

  /// Force push local book and progress to cloud
  Future<SyncResult> forcePushBook(String bookUuid, {bool progressOnly = true}) async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress.');
    }
    _isSyncing = true;
    print('[Sync] Force pushing book $bookUuid to cloud (progressOnly: $progressOnly)...');

    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      final storage = const FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          webDavPassword.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'WebDAV sync is not configured or disabled.');
      }

      // 1. Init WebDAV client
      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);
      final connected = await _webdav.testConnection();
      if (!connected) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Failed to connect to WebDAV server. Check settings.');
      }

      // 2. Ensure directories exist on WebDAV
      await _webdav.mkdir('/AudireReader');
      await _webdav.mkdir('/AudireReader/covers');
      await _webdav.mkdir('/AudireReader/books');
      await _webdav.mkdir('/AudireReader/progress');

      final localBook = await db.getBookByUuid(bookUuid);
      if (localBook == null) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Book not found locally.');
      }

      final String deviceId = settings.deviceId ?? '';
      final String deviceName = settings.deviceName ?? 'Unknown Device';

      _updateBookSyncStatus(bookUuid, 'syncing');

      if (progressOnly) {
        // PROGRESS ONLY SYNC FLOW
        final localProg = await db.getProgress(bookUuid);
        if (localProg != null) {
          final String remoteProgressPath = '/AudireReader/progress/$bookUuid.json';
          await _uploadLocalToCloud(remoteProgressPath, bookUuid, localProg, deviceId, deviceName);
        }
        _updateBookSyncStatus(bookUuid, 'success');
      } else {
        // FULL SYNC FLOW
        // A. Upload book and cover
        final String remoteBookPath = '/AudireReader/books/$bookUuid.json';
        final hasRemoteBook = await _webdav.fileExists(remoteBookPath);

        bool hasCover = false;
        if (localBook.coverPath != null) {
          final ext = p.extension(localBook.coverPath!);
          final remoteCoverPath = '/AudireReader/covers/$bookUuid$ext';
          final hasRemoteCover = await _webdav.fileExists(remoteCoverPath);

          if (!hasRemoteCover) {
            final coverFile = File(localBook.coverPath!);
            if (await coverFile.exists()) {
              final uploadCoverOk = await _webdav.uploadLocalFile(localBook.coverPath!, remoteCoverPath);
              hasCover = uploadCoverOk;
            }
          } else {
            hasCover = true;
          }
        }

        bool uploadContentOk = true;
        if (!hasRemoteBook) {
          final chapters = await db.getChaptersForBook(bookUuid);
          final bookContent = {
            'uuid': bookUuid,
            'title': localBook.title,
            'author': localBook.author,
            'totalChapters': localBook.totalChapters,
            'coverExtension': localBook.coverPath != null ? p.extension(localBook.coverPath!) : null,
            'dateAdded': localBook.dateAdded.toIso8601String(),
            'chapters': chapters.map((c) => {
              'chapterIndex': c.chapterIndex,
              'title': c.title,
              'paragraphs': c.paragraphs
            }).toList()
          };

          final jsonBytes = utf8.encode(json.encode(bookContent));
          uploadContentOk = await _webdav.uploadBytes(remoteBookPath, jsonBytes);
        }

        if (uploadContentOk) {
          // B. Update sync_data.json
          List<Map<String, dynamic>> cloudBooksList = [];
          final fileMeta = await _webdav.getFileMetadata('/AudireReader/sync_data.json');
          if (fileMeta != null) {
            final bytes = await _webdav.downloadBytes('/AudireReader/sync_data.json');
            if (bytes != null && bytes.isNotEmpty) {
              try {
                final jsonStr = utf8.decode(bytes);
                final oldCloudData = json.decode(jsonStr) as Map<String, dynamic>;
                final List<dynamic> oldCloudBooks = oldCloudData['books'] ?? [];
                cloudBooksList = List<Map<String, dynamic>>.from(oldCloudBooks);
              } catch (_) {}
            }
          }

          // Remove old instance of this book from index
          cloudBooksList.removeWhere((b) => b['uuid'] == bookUuid);

          // Add this book
          cloudBooksList.add({
            'uuid': bookUuid,
            'title': localBook.title,
            'author': localBook.author,
            'totalChapters': localBook.totalChapters,
            'dateAdded': localBook.dateAdded.toIso8601String(),
            'hasCover': hasCover,
            'coverExtension': localBook.coverPath != null ? p.extension(localBook.coverPath!) : null,
          });

          final Map<String, dynamic> newCloudSyncData = {
            'version': 1,
            'lastSyncTime': DateTime.now().toIso8601String(),
            'books': cloudBooksList,
            'deleted': []
          };

          final jsonBytes = utf8.encode(json.encode(newCloudSyncData));
          await _webdav.uploadBytes('/AudireReader/sync_data.json', jsonBytes);

          // C. Upload progress
          final localProg = await db.getProgress(bookUuid);
          if (localProg != null) {
            final String remoteProgressPath = '/AudireReader/progress/$bookUuid.json';
            await _uploadLocalToCloud(remoteProgressPath, bookUuid, localProg, deviceId, deviceName);
          }

          _updateBookSyncStatus(bookUuid, 'success');
        } else {
          _updateBookSyncStatus(bookUuid, 'error');
          _isSyncing = false;
          return SyncResult(success: false, message: 'Failed to upload book content.');
        }
      }

      // Update local settings lastSync
      settings.webDavLastSync = DateTime.now();
      await db.saveSettings(settings);

      await fetchCloudBooks();
      _isSyncing = false;
      return SyncResult(success: true, message: 'Book force pushed successfully.');
    } catch (e) {
      _isSyncing = false;
      _updateBookSyncStatus(bookUuid, 'error');
      print('[Sync] Force push book fatal error: $e');
      return SyncResult(success: false, message: 'Force push book failed: $e');
    }
  }

  /// Force pull cloud book and progress to local
  Future<SyncResult> forcePullBook(String bookUuid, {bool progressOnly = true}) async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress.');
    }
    _isSyncing = true;
    print('[Sync] Force pulling book $bookUuid from cloud (progressOnly: $progressOnly)...');

    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      final storage = const FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          webDavPassword.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'WebDAV sync is not configured or disabled.');
      }

      // 1. Init WebDAV client
      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);
      final connected = await _webdav.testConnection();
      if (!connected) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Failed to connect to WebDAV server. Check settings.');
      }

      // 2. Download sync_data.json
      final fileMeta = await _webdav.getFileMetadata('/AudireReader/sync_data.json');
      if (fileMeta == null) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'No sync data found on cloud server.');
      }

      final bytes = await _webdav.downloadBytes('/AudireReader/sync_data.json');
      if (bytes == null || bytes.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Cloud sync index file is empty.');
      }

      final jsonStr = utf8.decode(bytes);
      final cloudSyncData = json.decode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> cloudBooks = cloudSyncData['books'] ?? [];
      
      final cloudBookMap = cloudBooks.firstWhere(
        (b) => b is Map<String, dynamic> && b['uuid'] == bookUuid,
        orElse: () => null,
      ) as Map<String, dynamic>?;

      if (cloudBookMap == null) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Book not found on cloud.');
      }

      _updateBookSyncStatus(bookUuid, 'syncing');
      bool localDatabaseChanged = false;

      if (progressOnly) {
        // PROGRESS ONLY SYNC FLOW
        final String remoteProgressPath = '/AudireReader/progress/$bookUuid.json';
        final progressBytes = await _webdav.downloadBytes(remoteProgressPath);
        if (progressBytes != null && progressBytes.isNotEmpty) {
          final progressJson = json.decode(utf8.decode(progressBytes)) as Map<String, dynamic>;
          final localProg = await db.getProgress(bookUuid);
          await _updateLocalFromCloud(bookUuid, progressJson, localProg, db);
          localDatabaseChanged = true;
          _updateBookSyncStatus(bookUuid, 'success');
        } else {
          _updateBookSyncStatus(bookUuid, 'error');
          _isSyncing = false;
          return SyncResult(success: false, message: 'No reading progress found on cloud for this book.');
        }
      } else {
        // FULL SYNC FLOW
        final docDir = await PathHelper.getAppDirectory();
        final existingBook = await db.getBookByUuid(bookUuid);

        bool downloadSuccess = true;
        if (existingBook == null) {
          // Download book content
          final bookBytes = await _webdav.downloadBytes('/AudireReader/books/$bookUuid.json');
          if (bookBytes != null && bookBytes.isNotEmpty) {
            final bookJsonStr = utf8.decode(bookBytes);
            final bookContent = json.decode(bookJsonStr) as Map<String, dynamic>;

            // Download cover
            String? localCoverPath;
            if (cloudBookMap['hasCover'] == true) {
              final ext = cloudBookMap['coverExtension'] ?? '.png';
              final coverDir = Directory(p.join(docDir.path, 'covers'));
              if (!await coverDir.exists()) {
                await coverDir.create(recursive: true);
              }
              final localPath = p.join(coverDir.path, '$bookUuid$ext');
              final remotePath = '/AudireReader/covers/$bookUuid$ext';
              
              final downloadCoverOk = await _webdav.downloadToLocalFile(remotePath, localPath);
              if (downloadCoverOk) {
                localCoverPath = localPath;
              }
            }

            // Save Book
            final newBook = Book()
              ..uuid = bookUuid
              ..title = cloudBookMap['title']
              ..author = cloudBookMap['author']
              ..coverPath = localCoverPath
              ..totalChapters = cloudBookMap['totalChapters']
              ..dateAdded = DateTime.tryParse(cloudBookMap['dateAdded'] ?? '') ?? DateTime.now();

            // Save Chapters
            final List<Chapter> newChapters = [];
            final parsedChapters = bookContent['chapters'] as List<dynamic>;
            for (final c in parsedChapters) {
              final chMap = c as Map<String, dynamic>;
              final newCh = Chapter()
                ..bookUuid = bookUuid
                ..chapterIndex = chMap['chapterIndex']
                ..title = chMap['title']
                ..paragraphs = List<String>.from(chMap['paragraphs'] ?? []);
              newChapters.add(newCh);
            }

            await db.saveBook(newBook);
            await db.saveChapters(newChapters);
            localDatabaseChanged = true;
          } else {
            downloadSuccess = false;
          }
        } else {
          // Overwrite existing book content
          final bookBytes = await _webdav.downloadBytes('/AudireReader/books/$bookUuid.json');
          if (bookBytes != null && bookBytes.isNotEmpty) {
            final bookJsonStr = utf8.decode(bookBytes);
            final bookContent = json.decode(bookJsonStr) as Map<String, dynamic>;

            final newBook = Book()
              ..id = existingBook.id
              ..uuid = bookUuid
              ..title = cloudBookMap['title']
              ..author = cloudBookMap['author']
              ..coverPath = existingBook.coverPath
              ..totalChapters = cloudBookMap['totalChapters']
              ..dateAdded = DateTime.tryParse(cloudBookMap['dateAdded'] ?? '') ?? DateTime.now();

            // Clear old chapters
            await db.isar.writeTxn(() async {
              await db.isar.chapters.filter().bookUuidEqualTo(bookUuid).deleteAll();
            });

            // Save new Chapters
            final List<Chapter> newChapters = [];
            final parsedChapters = bookContent['chapters'] as List<dynamic>;
            for (final c in parsedChapters) {
              final chMap = c as Map<String, dynamic>;
              final newCh = Chapter()
                ..bookUuid = bookUuid
                ..chapterIndex = chMap['chapterIndex']
                ..title = chMap['title']
                ..paragraphs = List<String>.from(chMap['paragraphs'] ?? []);
              newChapters.add(newCh);
            }

            await db.saveBook(newBook);
            await db.saveChapters(newChapters);
            localDatabaseChanged = true;
          } else {
            downloadSuccess = false;
          }
        }

        if (downloadSuccess) {
          // Download progress
          final String remoteProgressPath = '/AudireReader/progress/$bookUuid.json';
          final progressBytes = await _webdav.downloadBytes(remoteProgressPath);
          if (progressBytes != null && progressBytes.isNotEmpty) {
            try {
              final progressJson = json.decode(utf8.decode(progressBytes)) as Map<String, dynamic>;
              final localProg = await db.getProgress(bookUuid);
              await _updateLocalFromCloud(bookUuid, progressJson, localProg, db);
              localDatabaseChanged = true;
            } catch (e) {
              print('[Sync] Error loading progress for $bookUuid during book force pull: $e');
            }
          }
          _updateBookSyncStatus(bookUuid, 'success');
        } else {
          _updateBookSyncStatus(bookUuid, 'error');
          _isSyncing = false;
          return SyncResult(success: false, message: 'Failed to download book content.');
        }
      }

      // Update local settings lastSync
      settings.webDavLastSync = DateTime.now();
      await db.saveSettings(settings);

      await fetchCloudBooks();
      _isSyncing = false;
      return SyncResult(
        success: true,
        message: 'Book force pulled successfully.',
        localChanged: localDatabaseChanged,
      );
    } catch (e) {
      _isSyncing = false;
      _updateBookSyncStatus(bookUuid, 'error');
      print('[Sync] Force pull book fatal error: $e');
      return SyncResult(success: false, message: 'Force pull book failed: $e');
    }
  }

  /// Xóa thông tin sách trên đám mây WebDAV và ghi nhận trạng thái đã xóa
  Future<SyncResult> deleteBookFromCloud(String bookUuid) async {
    print('[Sync] Deleting book UUID "$bookUuid" from WebDAV cloud...');
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      final storage = const FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          webDavPassword.isEmpty) {
        return SyncResult(success: false, message: 'WebDAV sync is not configured or disabled.');
      }

      // 1. Khởi tạo WebDAV Client
      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);
      final connected = await _webdav.testConnection();
      if (!connected) {
        return SyncResult(success: false, message: 'Failed to connect to WebDAV server.');
      }

      // 2. Tải tệp chỉ mục sync_data.json
      Map<String, dynamic> cloudSyncData = {
        'version': 1,
        'lastSyncTime': '',
        'books': [],
        'deleted': []
      };

      final hasSyncFile = await _webdav.fileExists('/AudireReader/sync_data.json');
      if (hasSyncFile) {
        final bytes = await _webdav.downloadBytes('/AudireReader/sync_data.json');
        if (bytes != null && bytes.isNotEmpty) {
          try {
            final jsonStr = utf8.decode(bytes);
            cloudSyncData = json.decode(jsonStr) as Map<String, dynamic>;
          } catch (e) {
            print('[Sync] Error decoding sync_data.json: $e');
          }
        }
      }

      final List<Map<String, dynamic>> cloudBooksList = List<Map<String, dynamic>>.from(cloudSyncData['books'] ?? []);
      final List<dynamic> cloudDeletedList = List<dynamic>.from(cloudSyncData['deleted'] ?? []);

      // 3. Loại bỏ sách khỏi chỉ mục
      bool indexChanged = false;
      final int initialBooksCount = cloudBooksList.length;
      cloudBooksList.removeWhere((b) => b['uuid'] == bookUuid);
      if (cloudBooksList.length < initialBooksCount) {
        indexChanged = true;
      }

      // Thêm UUID vào danh sách đã xóa kèm theo thời gian để phục vụ dọn dẹp Tombstone sau này
      final bool alreadyDeleted = cloudDeletedList.any((e) {
        if (e is String) return e == bookUuid;
        if (e is Map<String, dynamic>) return e['uuid'] == bookUuid;
        return false;
      });

      if (!alreadyDeleted) {
        cloudDeletedList.add({
          'uuid': bookUuid,
          'deletedAt': DateTime.now().toIso8601String()
        });
        indexChanged = true;
      }

      // 4. Nếu có thay đổi, lưu lại tệp chỉ mục sync_data.json mới
      if (indexChanged || !hasSyncFile) {
        cloudSyncData['books'] = cloudBooksList;
        cloudSyncData['deleted'] = cloudDeletedList;
        cloudSyncData['lastSyncTime'] = DateTime.now().toIso8601String();

        final jsonBytes = utf8.encode(json.encode(cloudSyncData));
        await _webdav.uploadBytes('/AudireReader/sync_data.json', jsonBytes);
        print('[Sync] Updated sync_data.json to register book deletion.');
      }

      // 5. Xóa file nội dung vật lý /AudireReader/books/{bookUuid}.json
      final String bookJsonPath = '/AudireReader/books/$bookUuid.json';
      if (await _webdav.fileExists(bookJsonPath)) {
        await _webdav.remove(bookJsonPath);
      }

      // 6. Xóa các tệp ảnh bìa trong /covers
      for (final ext in ['.png', '.jpg', '.jpeg']) {
        final String coverPath = '/AudireReader/covers/$bookUuid$ext';
        if (await _webdav.fileExists(coverPath)) {
          await _webdav.remove(coverPath);
        }
      }

      // 7. Xóa file tiến trình đọc riêng lẻ /AudireReader/progress/{bookUuid}.json
      final String progressPath = '/AudireReader/progress/$bookUuid.json';
      if (await _webdav.fileExists(progressPath)) {
        await _webdav.remove(progressPath);
      }

      print('[Sync] Successfully cleaned up all cloud resources for deleted book UUID "$bookUuid"');
      await fetchCloudBooks();
      return SyncResult(success: true, message: 'Book successfully deleted from cloud.');
    } catch (e) {
      print('[Sync] Failed to delete book from cloud: $e');
      return SyncResult(success: false, message: 'Failed to delete book from cloud: $e');
    }
  }

  Future<void> _addSyncHistoryEntry({
    required String bookUuid,
    required String action,
    required int chapterIndex,
    required int paragraphIndex,
    String? deviceIdOverride,
    String? deviceNameOverride,
  }) async {
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();
      if (!settings.webDavEnabled) return;

      final deviceId = deviceIdOverride ?? settings.deviceId ?? '';
      final deviceName = deviceNameOverride ?? settings.deviceName ?? 'Unknown Device';

      // Lấy tên sách
      String bookTitle = 'Unknown Book';
      final book = await db.getBookByUuid(bookUuid);
      if (book != null) {
        bookTitle = book.title;
      } else {
        // Có thể sách là sách ảo, thử tìm trong cache metadata mây
        final cloudBooks = cloudBooksNotifier.value;
        final cloudBook = cloudBooks.firstWhere(
          (b) => b['uuid'] == bookUuid,
          orElse: () => <String, dynamic>{},
        );
        if (cloudBook.containsKey('title')) {
          bookTitle = cloudBook['title'] ?? 'Unknown Book';
        }
      }

      final String historyPath = '/AudireReader/sync_history.json';
      List<dynamic> historyList = [];

      final storage = const FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      // Đảm bảo client đã khởi tạo
      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);

      // 1. Tải lịch sử hiện tại về
      final bytes = await _webdav.downloadBytes(historyPath);
      if (bytes != null && bytes.isNotEmpty) {
        try {
          historyList = json.decode(utf8.decode(bytes)) as List<dynamic>;
        } catch (_) {}
      }

      // 2. Tạo entry mới
      final newEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': deviceId,
        'deviceName': deviceName,
        'bookUuid': bookUuid,
        'bookTitle': bookTitle,
        'chapterIndex': chapterIndex,
        'paragraphIndex': paragraphIndex,
        'action': action, // 'push', 'pull'
      };

      // 3. Insert lên đầu và giới hạn 50 phần tử
      historyList.insert(0, newEntry);
      if (historyList.length > 50) {
        historyList = historyList.sublist(0, 50);
      }

      // 4. Upload ngược lại
      final updatedBytes = utf8.encode(json.encode(historyList));
      await _webdav.uploadBytes(historyPath, updatedBytes);
    } catch (e) {
      print('[SyncHistory] Error updating history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSyncHistory() async {
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();
      if (!settings.webDavEnabled) return [];

      final storage = const FlutterSecureStorage();
      final webDavPassword = await storage.read(key: 'webdav_password') ?? '';

      // Đảm bảo client đã khởi tạo
      _webdav.init(settings.webDavUrl, settings.webDavUsername, webDavPassword);

      final String historyPath = '/AudireReader/sync_history.json';
      final bytes = await _webdav.downloadBytes(historyPath);
      if (bytes != null && bytes.isNotEmpty) {
        final decoded = json.decode(utf8.decode(bytes)) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}

class SyncResult {
  final bool success;
  final String message;
  final bool localChanged;

  SyncResult({
    required this.success,
    required this.message,
    this.localChanged = false,
  });
}

enum ProgressSyncStatus {
  upToDate,
  updatedLocal,
  uploadedToCloud,
  conflict,
  error,
}

class ProgressSyncResult {
  final ProgressSyncStatus status;
  final Map<String, dynamic>? cloudProgress;

  ProgressSyncResult({required this.status, this.cloudProgress});
}
