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
}
