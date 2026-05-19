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

  /// Thực hiện đồng bộ hóa toàn diện thư viện đám mây
  Future<SyncResult> sync() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress.');
    }
    _isSyncing = true;
    print('[Sync] Starting synchronization process...');

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

      // 3. Tải tệp chỉ mục sync_data.json từ đám mây
      Map<String, dynamic> cloudSyncData = {
        'version': 1,
        'lastSyncTime': '',
        'books': [],
        'progress': [],
        'deleted': []
      };

      final hasSyncFile = await _webdav.fileExists('/NovelReader/sync_data.json');
      if (hasSyncFile) {
        final bytes = await _webdav.downloadBytes('/NovelReader/sync_data.json');
        if (bytes != null && bytes.isNotEmpty) {
          try {
            final jsonStr = utf8.decode(bytes);
            cloudSyncData = json.decode(jsonStr) as Map<String, dynamic>;
            print('[Sync] Loaded cloud index sync data.');
          } catch (e) {
            print('[Sync] Error decoding sync_data.json (creating new index): $e');
          }
        }
      }

      // Lấy danh sách sách ban đầu dưới Local
      var localBooks = await db.getAllBooks();
      final List<Map<String, dynamic>> cloudBooksList = List<Map<String, dynamic>>.from(cloudSyncData['books'] ?? []);
      final List<Map<String, dynamic>> cloudProgressList = List<Map<String, dynamic>>.from(cloudSyncData['progress'] ?? []);
      final List<String> cloudDeletedList = List<String>.from(cloudSyncData['deleted'] ?? []);

      bool localDatabaseChanged = false;
      bool cloudDatabaseChanged = false;

      // 3.5. XỬ LÝ ĐỒNG BỘ XÓA SÁCH (CLOUD -> LOCAL DELETION)
      // Nếu mây báo cuốn sách này đã bị xóa ở thiết bị khác, tự động xóa ở local
      for (final deletedUuid in cloudDeletedList) {
        final hasLocalBook = localBooks.any((b) => b.uuid == deletedUuid);
        if (hasLocalBook) {
          print('[Sync] Deleting book UUID "$deletedUuid" locally as it was deleted on another device.');
          await db.deleteBook(deletedUuid);
          localDatabaseChanged = true;
        }
      }

      // Load lại danh sách sách local nếu có thay đổi từ việc xóa đồng bộ
      if (localDatabaseChanged) {
        localBooks = await db.getAllBooks();
      }

      // 4. ĐỒNG BỘ SÁCH: LOCAL -> CLOUD (Tải sách mới lên mây)
      for (final localBook in localBooks) {
        // Không upload sách nếu sách này đang nằm trong danh sách đã xóa trên mây
        if (cloudDeletedList.contains(localBook.uuid)) {
          continue;
        }
        // Tìm xem sách đã có trên mây chưa (bằng uuid hoặc bằng title + author)
        final bool existsOnCloud = cloudBooksList.any((b) =>
            b['uuid'] == localBook.uuid ||
            (b['title'] == localBook.title && b['author'] == localBook.author));

        if (!existsOnCloud) {
          print('[Sync] Uploading new local book to cloud: "${localBook.title}"');
          try {
            // A. Upload Ảnh bìa (nếu có)
            bool hasCover = false;
            if (localBook.coverPath != null) {
              final coverFile = File(localBook.coverPath!);
              if (await coverFile.exists()) {
                final ext = p.extension(localBook.coverPath!);
                // Đồng bộ tên ảnh bìa chuẩn theo UUID để dễ tải về sau này
                final remoteCoverPath = '/NovelReader/covers/${localBook.uuid}$ext';
                final uploadCoverOk = await _webdav.uploadLocalFile(localBook.coverPath!, remoteCoverPath);
                hasCover = uploadCoverOk;
              }
            }

            // B. Đóng gói và Upload nội dung chương truyện
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
              // C. Thêm vào danh mục sách mây
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
              print('[Sync] Successfully uploaded book: "${localBook.title}"');
            }
          } catch (e) {
            print('[Sync] Error uploading book "${localBook.title}": $e');
          }
        }
      }

      // 5. ĐỒNG BỘ SÁCH: CLOUD -> LOCAL (Tải sách từ mây về máy mới)
      final docDir = await getApplicationDocumentsDirectory();
      for (final cloudBook in cloudBooksList) {
        if (cloudDeletedList.contains(cloudBook['uuid'])) {
          continue;
        }

        // Tìm xem sách đã có ở local chưa (bằng uuid hoặc bằng title + author)
        final bool existsLocally = localBooks.any((b) =>
            b.uuid == cloudBook['uuid'] ||
            (b.title == cloudBook['title'] && b.author == cloudBook['author']));

        if (!existsLocally) {
          print('[Sync] Downloading book content from cloud: "${cloudBook['title']}"');
          try {
            final bookUuid = cloudBook['uuid'];
            final bytes = await _webdav.downloadBytes('/NovelReader/books/$bookUuid.json');
            if (bytes != null && bytes.isNotEmpty) {
              final jsonStr = utf8.decode(bytes);
              final bookContent = json.decode(jsonStr) as Map<String, dynamic>;

              // A. Tải ảnh bìa (nếu có)
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

              // B. Lưu Book vào DB local
              final newBook = Book()
                ..uuid = bookUuid
                ..title = cloudBook['title']
                ..author = cloudBook['author']
                ..coverPath = localCoverPath
                ..totalChapters = cloudBook['totalChapters']
                ..dateAdded = DateTime.tryParse(cloudBook['dateAdded'] ?? '') ?? DateTime.now();

              // C. Lưu các Chapter vào DB local
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
              print('[Sync] Successfully restored book locally: "${newBook.title}"');
            }
          } catch (e) {
            print('[Sync] Error downloading book "${cloudBook['title']}": $e');
          }
        }
      }

      // Load lại danh sách sách local sau khi đã phục hồi/download thêm sách mới
      final updatedLocalBooks = await db.getAllBooks();

      // 6. ĐỒNG BỘ TIẾN TRÌNH ĐỌC (Merge Reading Progress)
      // A. Duyệt tiến trình từ CLOUD cập nhật vào LOCAL
      for (final cloudProg in cloudProgressList) {
        final cloudBookUuid = cloudProg['bookUuid'];
        
        // Tìm sách cục bộ tương ứng (bằng uuid hoặc bằng tên + tác giả của sách trên mây)
        final cloudBookMetadata = cloudBooksList.firstWhere(
          (b) => b['uuid'] == cloudBookUuid,
          orElse: () => <String, dynamic>{},
        );

        String? localBookUuid;
        if (cloudBookMetadata.isNotEmpty) {
          final matchingLocalBook = updatedLocalBooks.firstWhere(
            (b) => b.uuid == cloudBookUuid || 
                   (b.title == cloudBookMetadata['title'] && b.author == cloudBookMetadata['author']),
            orElse: () => Book()..uuid = '',
          );
          if (matchingLocalBook.uuid.isNotEmpty) {
            localBookUuid = matchingLocalBook.uuid;
          }
        }

        // Nếu tìm thấy sách cục bộ tương ứng, xử lý đồng bộ tiến trình
        if (localBookUuid != null) {
          final localProg = await db.getProgress(localBookUuid);
          final DateTime cloudLastRead = DateTime.tryParse(cloudProg['lastRead'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

          if (localProg == null) {
            // Local chưa có tiến trình đọc cuốn này -> Tạo mới
            final newProg = ReadingProgress()
              ..bookUuid = localBookUuid
              ..currentChapterIndex = cloudProg['currentChapterIndex']
              ..currentParagraphIndex = cloudProg['currentParagraphIndex']
              ..currentCharacterOffset = cloudProg['currentCharacterOffset'] ?? 0
              ..lastRead = cloudLastRead;
            await db.saveProgress(newProg);
            localDatabaseChanged = true;
            print('[Sync] Created local progress for book UUID "$localBookUuid" from cloud (Chapter: ${newProg.currentChapterIndex})');
          } else {
            // Cả hai đều có tiến trình -> So sánh thời gian
            if (cloudLastRead.isAfter(localProg.lastRead)) {
              // Tiến trình mây mới hơn -> Ghi đè local
              localProg.currentChapterIndex = cloudProg['currentChapterIndex'];
              localProg.currentParagraphIndex = cloudProg['currentParagraphIndex'];
              localProg.currentCharacterOffset = cloudProg['currentCharacterOffset'] ?? 0;
              localProg.lastRead = cloudLastRead;
              await db.saveProgress(localProg);
              localDatabaseChanged = true;
              print('[Sync] Updated local progress for book UUID "$localBookUuid" (Cloud was newer: Chapter: ${localProg.currentChapterIndex})');
            } else if (localProg.lastRead.isAfter(cloudLastRead)) {
              // Tiến trình local mới hơn -> Sẽ cập nhật lên Cloud ở bước tiếp theo
              // Cập nhật thông tin trong memory để tải lên
              final idx = cloudProgressList.indexWhere((p) => p['bookUuid'] == cloudBookUuid);
              if (idx != -1) {
                cloudProgressList[idx] = {
                  'bookUuid': cloudBookUuid,
                  'currentChapterIndex': localProg.currentChapterIndex,
                  'currentParagraphIndex': localProg.currentParagraphIndex,
                  'currentCharacterOffset': localProg.currentCharacterOffset,
                  'lastRead': localProg.lastRead.toIso8601String(),
                };
                cloudDatabaseChanged = true;
                print('[Sync] Marked cloud progress for book UUID "$cloudBookUuid" to update (Local is newer: Chapter: ${localProg.currentChapterIndex})');
              }
            }
          }
        }
      }

      // B. Duyệt tiến trình từ LOCAL chưa có trên CLOUD cập nhật lên CLOUD
      for (final localBook in updatedLocalBooks) {
        final localProg = await db.getProgress(localBook.uuid);
        if (localProg != null) {
          // Kiểm tra xem mây đã có tiến trình của sách này chưa (bằng uuid hoặc đối khớp title + author)
          final bool existsOnCloudProg = cloudProgressList.any((p) {
            if (p['bookUuid'] == localBook.uuid) return true;
            
            final cloudB = cloudBooksList.firstWhere(
              (b) => b['uuid'] == p['bookUuid'],
              orElse: () => <String, dynamic>{},
            );
            return cloudB.isNotEmpty && cloudB['title'] == localBook.title && cloudB['author'] == localBook.author;
          });

          if (!existsOnCloudProg) {
            // Mây chưa có tiến trình của sách này -> Thêm vào list mây để tải lên
            cloudProgressList.add({
              'bookUuid': localBook.uuid,
              'currentChapterIndex': localProg.currentChapterIndex,
              'currentParagraphIndex': localProg.currentParagraphIndex,
              'currentCharacterOffset': localProg.currentCharacterOffset,
              'lastRead': localProg.lastRead.toIso8601String(),
            });
            cloudDatabaseChanged = true;
            print('[Sync] Uploading new progress for book "${localBook.title}" (Chapter: ${localProg.currentChapterIndex})');
          }
        }
      }

      // 7. GHI LẠI CHỈ MỤC MỚI LÊN ĐÁM MÂY (Nếu có thay đổi)
      if (cloudDatabaseChanged || !hasSyncFile) {
        cloudSyncData['books'] = cloudBooksList;
        cloudSyncData['progress'] = cloudProgressList;
        cloudSyncData['deleted'] = cloudDeletedList;
        cloudSyncData['lastSyncTime'] = DateTime.now().toIso8601String();

        final jsonBytes = utf8.encode(json.encode(cloudSyncData));
        final uploadOk = await _webdav.uploadBytes('/NovelReader/sync_data.json', jsonBytes);
        if (uploadOk) {
          print('[Sync] Successfully uploaded new sync_data.json to cloud.');
        } else {
          print('[Sync] Failed to upload updated sync_data.json to cloud.');
        }
      }

      // 8. CẬP NHẬT CẤU HÌNH CỤC BỘ (Last Sync Time)
      settings.webDavLastSync = DateTime.now();
      await db.saveSettings(settings);

      _isSyncing = false;
      return SyncResult(
        success: true,
        message: 'Sync completed successfully.',
        localChanged: localDatabaseChanged,
      );
    } catch (e) {
      _isSyncing = false;
      print('[Sync] Fatal error during sync: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
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
        'progress': [],
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
            print('[Sync] Error decoding sync_data.json during delete: $e');
          }
        }
      }

      final List<Map<String, dynamic>> cloudBooksList = List<Map<String, dynamic>>.from(cloudSyncData['books'] ?? []);
      final List<Map<String, dynamic>> cloudProgressList = List<Map<String, dynamic>>.from(cloudSyncData['progress'] ?? []);
      final List<String> cloudDeletedList = List<String>.from(cloudSyncData['deleted'] ?? []);

      // 3. Loại bỏ sách và tiến trình tương ứng khỏi chỉ mục
      bool indexChanged = false;
      
      final int initialBooksCount = cloudBooksList.length;
      cloudBooksList.removeWhere((b) => b['uuid'] == bookUuid);
      if (cloudBooksList.length < initialBooksCount) {
        indexChanged = true;
      }

      final int initialProgressCount = cloudProgressList.length;
      cloudProgressList.removeWhere((p) => p['bookUuid'] == bookUuid);
      if (cloudProgressList.length < initialProgressCount) {
        indexChanged = true;
      }

      // Thêm UUID vào danh sách đã xóa để đồng bộ cho các thiết bị khác
      if (!cloudDeletedList.contains(bookUuid)) {
        cloudDeletedList.add(bookUuid);
        indexChanged = true;
      }

      // 4. Nếu có thay đổi, lưu lại tệp chỉ mục sync_data.json mới
      if (indexChanged || !hasSyncFile) {
        cloudSyncData['books'] = cloudBooksList;
        cloudSyncData['progress'] = cloudProgressList;
        cloudSyncData['deleted'] = cloudDeletedList;
        cloudSyncData['lastSyncTime'] = DateTime.now().toIso8601String();

        final jsonBytes = utf8.encode(json.encode(cloudSyncData));
        await _webdav.uploadBytes('/NovelReader/sync_data.json', jsonBytes);
        print('[Sync] Updated sync_data.json to register book deletion.');
      }

      // 5. Xóa tệp nội dung vật lý /NovelReader/books/{bookUuid}.json
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
