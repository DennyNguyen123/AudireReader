import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PathHelper {
  static Directory? _appDir;
  static Directory? _cacheDir;

  /// Trả về thư mục chứa dữ liệu ứng dụng (Documents/AudireReader)
  static Future<Directory> getAppDirectory() async {
    if (_appDir != null) return _appDir!;

    final docDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(docDir.path, 'AudireReader'));
    
    // Bước 1: Nếu tồn tại thư mục NovelReader cũ, rename sang AudireReader
    final legacyNovelReaderDir = Directory(p.join(docDir.path, 'NovelReader'));
    if (await legacyNovelReaderDir.exists() && !await targetDir.exists()) {
      try {
        await legacyNovelReaderDir.rename(targetDir.path);
        // ignore: avoid_print
        print('[Migration] Renamed legacy NovelReader directory to AudireReader.');
      } catch (e) {
        // ignore: avoid_print
        print('[Migration] Failed to rename NovelReader directory: $e. Trying fallback copy...');
        try {
          await _copyDirectory(legacyNovelReaderDir, targetDir);
          await legacyNovelReaderDir.delete(recursive: true);
        } catch (copyErr) {
          // ignore: avoid_print
          print('[Migration] Fallback copy failed: $copyErr');
        }
      }
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // Bước 2: Thực hiện di chuyển dữ liệu từ thư mục gốc (nếu có dữ liệu của phiên bản rất cũ)
    await _migrateLegacyData(docDir.path, targetDir.path);

    _appDir = targetDir;
    return targetDir;
  }

  /// Trả về thư mục lưu cache audio TTS (Documents/AudireReader/cache)
  static Future<Directory> getAppCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;

    final appDir = await getAppDirectory();
    final targetCacheDir = Directory(p.join(appDir.path, 'cache'));
    
    if (!await targetCacheDir.exists()) {
      await targetCacheDir.create(recursive: true);
    }

    _cacheDir = targetCacheDir;
    return targetCacheDir;
  }

  /// Di chuyển các tập tin cơ sở dữ liệu và thư mục ảnh bìa cũ vào thư mục AudireReader mới
  static Future<void> _migrateLegacyData(String oldPath, String newPath) async {
    // 1. Di chuyển file database Isar (default.isar)
    final oldIsarFile = File(p.join(oldPath, 'default.isar'));
    final newIsarFile = File(p.join(newPath, 'default.isar'));
    if (await oldIsarFile.exists() && !await newIsarFile.exists()) {
      try {
        await oldIsarFile.copy(newIsarFile.path);
        await oldIsarFile.delete();
        // ignore: avoid_print
        print('[Migration] Migrated default.isar successfully to $newPath');
      } catch (e) {
        // ignore: avoid_print
        print('[Migration] Error migrating default.isar: $e');
      }
    }

    // 2. Di chuyển file lock database (default.isar.lock)
    final oldLockFile = File(p.join(oldPath, 'default.isar.lock'));
    final newLockFile = File(p.join(newPath, 'default.isar.lock'));
    if (await oldLockFile.exists() && !await newLockFile.exists()) {
      try {
        await oldLockFile.copy(newLockFile.path);
        await oldLockFile.delete();
        // ignore: avoid_print
        print('[Migration] Migrated default.isar.lock successfully.');
      } catch (e) {
        // ignore: avoid_print
        print('[Migration] Error migrating default.isar.lock: $e');
      }
    }

    // 3. Di chuyển thư mục ảnh bìa (covers)
    final oldCoversDir = Directory(p.join(oldPath, 'covers'));
    final newCoversDir = Directory(p.join(newPath, 'covers'));
    if (await oldCoversDir.exists() && !await newCoversDir.exists()) {
      try {
        await newCoversDir.create(recursive: true);
        await for (final entity in oldCoversDir.list()) {
          if (entity is File) {
            final fileName = p.basename(entity.path);
            await entity.copy(p.join(newCoversDir.path, fileName));
          }
        }
        await oldCoversDir.delete(recursive: true);
        // ignore: avoid_print
        print('[Migration] Migrated covers directory successfully.');
      } catch (e) {
        // ignore: avoid_print
        print('[Migration] Error migrating covers directory: $e');
      }
    }
  }

  /// Sao chép thư mục đệ quy
  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(p.join(destination.absolute.path, p.basename(entity.path)));
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File(p.join(destination.path, p.basename(entity.path)));
        await entity.copy(newFile.path);
      }
    }
  }
}
