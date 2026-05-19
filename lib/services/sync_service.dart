// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/database/database_helper.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/progress.dart';
import 'webdav_service.dart';
import 'logger_service.dart';

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

  SyncService._();

  static SyncService getInstance() {
    _instance ??= SyncService._();
    return _instance!;
  }

  bool get isSyncing => _isSyncing;

  /// Thực hiện đồng bộ hóa toàn diện (để tương thích ngược)
  Future<SyncResult> sync() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress.');
    }
    _isSyncing = true;
    print('[Sync] Starting overall synchronization...');

    try {
      // 1. Đồng bộ thư viện sách trước
      _isSyncing = false; // tạm thời nhả lock để syncLibrary có thể chạy
      final libResult = await syncLibrary();
      _isSyncing = true; // khóa lại
      
      if (!libResult.success) {
        _isSyncing = false;
        return libResult;
      }

      // 2. Đồng bộ tiến trình đọc cho tất cả sách cục bộ
      final db = await DatabaseHelper.getInstance();
      final localBooks = await db.getAllBooks();
      bool progressChanged = false;

      for (final book in localBooks) {
        final changed = await syncBookProgress(book.uuid);
        if (changed) {
          progressChanged = true;
        }
      }

      _isSyncing = false;
      return SyncResult(
        success: true,
        message: 'Sync completed successfully.',
        localChanged: libResult.localChanged || progressChanged,
      );
    } catch (e) {
      _isSyncing = false;
      print('[Sync] Fatal error during overall sync: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  /// 1. Đồng bộ Danh mục Sách và Trạng thái Xóa (sync_data.json)
  /// Có hỗ trợ cơ chế Optimistic Locking chống ghi đè dữ liệu
  Future<SyncResult> syncLibrary() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress.');
    }
    _isSyncing = true;
    print('[SyncLibrary] Starting library sync...');

    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          settings.webDavPassword.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'WebDAV sync is not configured or disabled.');
      }

      // 1. Khởi tạo WebDAV Client
      _webdav.init(settings.webDavUrl, settings.webDavUsername, settings.webDavPassword);
      final connected = await _webdav.testConnection();
      if (!connected) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Failed to connect to WebDAV server. Check settings.');
      }

      // 2. Đảm bảo các thư mục tồn tại trên WebDAV
      await _webdav.mkdir('/NovelReader');
      await _webdav.mkdir('/NovelReader/covers');
      await _webdav.mkdir('/NovelReader/books');
      await _webdav.mkdir('/NovelReader/progress');

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
        final fileMeta = await _webdav.getFileMetadata('/NovelReader/sync_data.json');
        
        Map<String, dynamic> cloudSyncData = {
          'version': 1,
          'lastSyncTime': '',
          'books': [],
          'deleted': []
        };

        final hasSyncFile = fileMeta != null;
        if (hasSyncFile) {
          final bytes = await _webdav.downloadBytes('/NovelReader/sync_data.json');
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
                await _webdav.uploadBytes('/NovelReader/progress/$bUuid.json', jsonBytes);
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
            try {
              // A. Upload Ảnh bìa
              bool hasCover = false;
              if (localBook.coverPath != null) {
                final coverFile = File(localBook.coverPath!);
                if (await coverFile.exists()) {
                  final ext = p.extension(localBook.coverPath!);
                  final remoteCoverPath = '/NovelReader/covers/${localBook.uuid}$ext';
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
              final uploadContentOk = await _webdav.uploadBytes('/NovelReader/books/${localBook.uuid}.json', jsonBytes);

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
              }
            } catch (e) {
              print('[SyncLibrary] Error uploading book "${localBook.title}": $e');
            }
          }
        }

        // 5. ĐỒNG BỘ SÁCH: CLOUD -> LOCAL (Tải sách từ mây về máy mới)
        final docDir = await getApplicationDocumentsDirectory();
        for (final cloudBook in cloudBooksList) {
          if (activeDeletedUuids.contains(cloudBook['uuid'])) {
            continue;
          }
          final bool existsLocally = localBooks.any((b) =>
              b.uuid == cloudBook['uuid'] ||
              (b.title == cloudBook['title'] && b.author == cloudBook['author']));

          if (!existsLocally) {
            print('[SyncLibrary] Downloading book from cloud: "${cloudBook['title']}"');
            try {
              final bookUuid = cloudBook['uuid'];
              final bytes = await _webdav.downloadBytes('/NovelReader/books/$bookUuid.json');
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
                  final remotePath = '/NovelReader/covers/$bookUuid$ext';
                  
                  final downloadCoverOk = await _webdav.downloadToLocalFile(remotePath, localPath);
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
              }
            } catch (e) {
              print('[SyncLibrary] Error downloading book "${cloudBook['title']}": $e');
            }
          }
        }

        // 6. GHI LẠI CHỈ MỤC MỚI (Optimistic Locking)
        if (cloudDatabaseChanged || !hasSyncFile) {
          // Kiểm tra xem trong thời gian ta sync, tệp trên server có bị thiết bị khác ghi đè hay chưa
          final currentFileMeta = await _webdav.getFileMetadata('/NovelReader/sync_data.json');
          String currentServerTime = '';
          
          if (currentFileMeta != null) {
            // Tải nhanh file chỉ mục để so sánh lastSyncTime chuẩn xác nhất
            final checkBytes = await _webdav.downloadBytes('/NovelReader/sync_data.json');
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
          final uploadOk = await _webdav.uploadBytes('/NovelReader/sync_data.json', jsonBytes);
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
        _isSyncing = false;
        return SyncResult(success: false, message: 'Sync failed: $lastSyncError');
      }

      // 7. CẬP NHẬT CẤU HÌNH CỤC BỘ
      settings.webDavLastSync = DateTime.now();
      await db.saveSettings(settings);

      _isSyncing = false;
      return SyncResult(
        success: true,
        message: 'Library sync completed successfully.',
        localChanged: localDatabaseChanged,
      );
    } catch (e) {
      _isSyncing = false;
      print('[SyncLibrary] Fatal error: $e');
      return SyncResult(success: false, message: 'Library sync failed: $e');
    }
  }

  /// 2. Đồng bộ Tiến trình đọc của riêng một cuốn sách
  /// Sử dụng tệp siêu nhẹ `/progress/{bookUuid}.json`
  /// Trả về true nếu Local database được cập nhật dữ liệu mới từ Cloud
  Future<bool> syncBookProgress(String bookUuid) async {
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          settings.webDavPassword.isEmpty) {
        return false;
      }

      // Đảm bảo client đã khởi tạo
      _webdav.init(settings.webDavUrl, settings.webDavUsername, settings.webDavPassword);

      final localProg = await db.getProgress(bookUuid);
      final String remotePath = '/NovelReader/progress/$bookUuid.json';

      // 1. Tải tiến trình trên mây về (nếu có)
      Map<String, dynamic>? cloudProg;
      final fileMeta = await _webdav.getFileMetadata(remotePath);
      
      if (fileMeta != null) {
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
        // So sánh tiến trình mây với local bằng thuật toán thông minh chống lệch giờ
        final bool cloudIsNewer = _isCloudProgressNewer(cloudProg, localProg);

        if (cloudIsNewer) {
          // Cloud mới hơn -> Ghi đè Local
          final DateTime cloudLastRead = DateTime.tryParse(cloudProg['lastRead'] ?? '') ?? DateTime.now();
          final targetProg = localProg ?? (ReadingProgress()..bookUuid = bookUuid);
          targetProg.currentChapterIndex = cloudProg['currentChapterIndex'] ?? 0;
          targetProg.currentParagraphIndex = cloudProg['currentParagraphIndex'] ?? 0;
          targetProg.currentCharacterOffset = cloudProg['currentCharacterOffset'] ?? 0;
          targetProg.lastRead = cloudLastRead;
          await db.saveProgress(targetProg);
          print('[SyncProgress] Updated local progress for book $bookUuid (Cloud was newer: Chapter: ${targetProg.currentChapterIndex})');
          return true;
        } else if (localProg != null) {
          // Local mới hơn hoặc bằng -> Upload Local lên Cloud (nếu local thực sự mới hơn vị trí hoặc giờ)
          final bool localIsNewer = !_isCloudProgressEqual(cloudProg, localProg);
          if (localIsNewer) {
            final localJson = {
              'bookUuid': bookUuid,
              'currentChapterIndex': localProg.currentChapterIndex,
              'currentParagraphIndex': localProg.currentParagraphIndex,
              'currentCharacterOffset': localProg.currentCharacterOffset,
              'lastRead': localProg.lastRead.toIso8601String(),
            };
            final jsonBytes = utf8.encode(json.encode(localJson));
            await _webdav.uploadBytes(remotePath, jsonBytes);
            print('[SyncProgress] Uploaded local progress for book $bookUuid (Local is newer: Chapter: ${localProg.currentChapterIndex})');
          }
        }
      } else {
        // Mây chưa có tiến trình của sách này -> Đẩy Local lên mây nếu Local có dữ liệu
        if (localProg != null) {
          final localJson = {
            'bookUuid': bookUuid,
            'currentChapterIndex': localProg.currentChapterIndex,
            'currentParagraphIndex': localProg.currentParagraphIndex,
            'currentCharacterOffset': localProg.currentCharacterOffset,
            'lastRead': localProg.lastRead.toIso8601String(),
          };
          final jsonBytes = utf8.encode(json.encode(localJson));
          await _webdav.uploadBytes(remotePath, jsonBytes);
          print('[SyncProgress] Created initial cloud progress for book $bookUuid');
        }
      }
    } catch (e) {
      print('[SyncProgress] Failed to sync progress for book $bookUuid: $e');
    }
    return false;
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

  /// Xóa thông tin sách trên đám mây WebDAV và ghi nhận trạng thái đã xóa
  Future<SyncResult> deleteBookFromCloud(String bookUuid) async {
    print('[Sync] Deleting book UUID "$bookUuid" from WebDAV cloud...');
    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();

      if (!settings.webDavEnabled ||
          settings.webDavUrl.isEmpty ||
          settings.webDavUsername.isEmpty ||
          settings.webDavPassword.isEmpty) {
        return SyncResult(success: false, message: 'WebDAV sync is not configured or disabled.');
      }

      // 1. Khởi tạo WebDAV Client
      _webdav.init(settings.webDavUrl, settings.webDavUsername, settings.webDavPassword);
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

      final hasSyncFile = await _webdav.fileExists('/NovelReader/sync_data.json');
      if (hasSyncFile) {
        final bytes = await _webdav.downloadBytes('/NovelReader/sync_data.json');
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
        await _webdav.uploadBytes('/NovelReader/sync_data.json', jsonBytes);
        print('[Sync] Updated sync_data.json to register book deletion.');
      }

      // 5. Xóa file nội dung vật lý /NovelReader/books/{bookUuid}.json
      final String bookJsonPath = '/NovelReader/books/$bookUuid.json';
      if (await _webdav.fileExists(bookJsonPath)) {
        await _webdav.remove(bookJsonPath);
      }

      // 6. Xóa các tệp ảnh bìa trong /covers
      for (final ext in ['.png', '.jpg', '.jpeg']) {
        final String coverPath = '/NovelReader/covers/$bookUuid$ext';
        if (await _webdav.fileExists(coverPath)) {
          await _webdav.remove(coverPath);
        }
      }

      // 7. Xóa file tiến trình đọc riêng lẻ /NovelReader/progress/{bookUuid}.json
      final String progressPath = '/NovelReader/progress/$bookUuid.json';
      if (await _webdav.fileExists(progressPath)) {
        await _webdav.remove(progressPath);
      }

      print('[Sync] Successfully cleaned up all cloud resources for deleted book UUID "$bookUuid"');
      return SyncResult(success: true, message: 'Book successfully deleted from cloud.');
    } catch (e) {
      print('[Sync] Failed to delete book from cloud: $e');
      return SyncResult(success: false, message: 'Failed to delete book from cloud: $e');
    }
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
