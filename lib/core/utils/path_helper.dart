import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PathHelper {
  static Directory? _appDir;
  static Directory? _cacheDir;

  /// Trả về thư mục chứa dữ liệu ứng dụng (Documents/NovelReader)
  static Future<Directory> getAppDirectory() async {
    if (_appDir != null) return _appDir!;

    final docDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(docDir.path, 'NovelReader'));
    
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // Thực hiện di chuyển dữ liệu cũ nếu phát hiện
    await _migrateLegacyData(docDir.path, targetDir.path);

    _appDir = targetDir;
    return targetDir;
  }

  /// Trả về thư mục lưu cache audio TTS (Documents/NovelReader/cache)
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

  /// Di chuyển các tập tin cơ sở dữ liệu và thư mục ảnh bìa cũ vào thư mục NovelReader mới
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
}
