import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PathHelper {
  static Directory? _appDir;
  static Directory? _cacheDir;

  /// Trả về thư mục chứa dữ liệu ứng dụng (AppData/AudireReader)
  static Future<Directory> getAppDirectory() async {
    if (_appDir != null) return _appDir!;

    final supportDir = await getApplicationSupportDirectory();
    final targetDir = Directory(p.join(supportDir.path, 'AudireReader'));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    _appDir = targetDir;
    return targetDir;
  }

  /// Trả về thư mục lưu cache audio TTS (AppData/AudireReader/cache)
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

  /// Trả về thư mục chứa ảnh bìa (AppData/AudireReader/covers)
  static Future<Directory> getCoversDirectory() async {
    final appDir = await getAppDirectory();
    final coversDir = Directory(p.join(appDir.path, 'covers'));
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    return coversDir;
  }

  /// Trả về đường dẫn ảnh bìa thực tế tồn tại trên thiết bị (Fix triệt để lỗi đổi UUID Sandbox trên iOS)
  static Future<String?> resolveCoverPath(String? rawCoverPath, {String? uuid}) async {
    if ((rawCoverPath == null || rawCoverPath.isEmpty) && (uuid == null || uuid.isEmpty)) {
      return null;
    }

    // 1. URL online
    if (rawCoverPath != null &&
        (rawCoverPath.startsWith('http://') || rawCoverPath.startsWith('https://'))) {
      return rawCoverPath;
    }

    // 2. Direct path check
    if (rawCoverPath != null && rawCoverPath.isNotEmpty) {
      final directFile = File(rawCoverPath);
      if (directFile.existsSync()) {
        return directFile.path;
      }
    }

    // 3. Resolve trong thư mục covers/ của sandbox hiện tại
    final appDir = await getAppDirectory();
    final coversDirPath = p.join(appDir.path, 'covers');

    // 3.1. Tìm theo filename
    if (rawCoverPath != null && rawCoverPath.isNotEmpty) {
      final fileName = p.basename(rawCoverPath);
      final candidate = File(p.join(coversDirPath, fileName));
      if (candidate.existsSync()) {
        return candidate.path;
      }
    }

    // 3.2. Tìm theo UUID
    if (uuid != null && uuid.isNotEmpty) {
      final extensions = ['.png', '.jpg', '.jpeg', '.webp'];
      for (final ext in extensions) {
        final candidate = File(p.join(coversDirPath, '$uuid$ext'));
        if (candidate.existsSync()) {
          return candidate.path;
        }
      }
    }

    return null;
  }

  /// Phiên bản đồng bộ để dùng trong Widget UI (sử dụng _appDir đã cache)
  static String? resolveCoverPathSync(String? rawCoverPath, {String? uuid}) {
    if ((rawCoverPath == null || rawCoverPath.isEmpty) && (uuid == null || uuid.isEmpty)) {
      return null;
    }

    if (rawCoverPath != null &&
        (rawCoverPath.startsWith('http://') || rawCoverPath.startsWith('https://'))) {
      return rawCoverPath;
    }

    if (rawCoverPath != null && rawCoverPath.isNotEmpty) {
      final directFile = File(rawCoverPath);
      if (directFile.existsSync()) {
        return directFile.path;
      }
    }

    if (_appDir != null) {
      final coversDirPath = p.join(_appDir!.path, 'covers');

      if (rawCoverPath != null && rawCoverPath.isNotEmpty) {
        final fileName = p.basename(rawCoverPath);
        final candidate = File(p.join(coversDirPath, fileName));
        if (candidate.existsSync()) {
          return candidate.path;
        }
      }

      if (uuid != null && uuid.isNotEmpty) {
        final extensions = ['.png', '.jpg', '.jpeg', '.webp'];
        for (final ext in extensions) {
          final candidate = File(p.join(coversDirPath, '$uuid$ext'));
          if (candidate.existsSync()) {
            return candidate.path;
          }
        }
      }
    }

    return null;
  }
}
