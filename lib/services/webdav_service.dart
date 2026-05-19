// ignore_for_file: avoid_print
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'logger_service.dart';

class WebDavService {
  static WebDavService? _instance;
  webdav.Client? _client;
  bool _isInitialized = false;

  WebDavService._();

  static WebDavService getInstance() {
    _instance ??= WebDavService._();
    return _instance!;
  }

  bool get isInitialized => _isInitialized && _client != null;

  /// Khởi tạo kết nối WebDAV Client
  void init(String url, String username, String password) {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    final isDebugEnabled = LoggerService().enableWebDavDebug;
    LoggerService().log('Initializing WebDAV client with debug=$isDebugEnabled', tag: 'WEBDAV', level: LogLevel.info);

    _client = webdav.newClient(
      formattedUrl,
      user: username.trim(),
      password: password,
      debug: isDebugEnabled,
    );
    _isInitialized = true;
  }

  /// Kiểm tra kết nối tới máy chủ WebDAV
  Future<bool> testConnection() async {
    if (_client == null) return false;
    LoggerService().log('Testing connection to WebDAV server...', tag: 'WEBDAV', level: LogLevel.info);
    try {
      // Thử đọc thư mục gốc để xác thực tài khoản và kiểm tra kết nối
      await _client!.readDir('/');
      LoggerService().log('WebDAV connection verified successfully.', tag: 'WEBDAV', level: LogLevel.info);
      return true;
    } catch (e) {
      LoggerService().log('WebDAV connection test failed', tag: 'WEBDAV', level: LogLevel.error, error: e.toString());
      return false;
    }
  }

  /// Tạo thư mục trên máy chủ WebDAV nếu chưa tồn tại
  Future<bool> mkdir(String remotePath) async {
    if (_client == null) return false;
    try {
      await _client!.mkdir(remotePath);
      LoggerService().log('Created directory (or verified it exists): $remotePath', tag: 'WEBDAV', level: LogLevel.info);
      return true;
    } catch (e) {
      LoggerService().log('WebDAV mkdir info/error (might already exist): $remotePath', tag: 'WEBDAV', level: LogLevel.warning, error: e.toString());
      return true;
    }
  }

  /// Tải tệp lên máy chủ WebDAV từ danh sách byte dữ liệu
  Future<bool> uploadBytes(String remotePath, List<int> bytes) async {
    if (_client == null) return false;
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = p.basename(remotePath);
      tempFile = File(p.join(tempDir.path, 'upload_$fileName'));
      await tempFile.writeAsBytes(bytes);

      LoggerService().log('Uploading bytes (${bytes.length} bytes) to: $remotePath', tag: 'WEBDAV', level: LogLevel.info);
      await _client!.writeFromFile(tempFile.path, remotePath);
      return true;
    } catch (e) {
      LoggerService().log('WebDAV uploadBytes failed for $remotePath', tag: 'WEBDAV', level: LogLevel.error, error: e.toString());
      return false;
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Tải tệp lên máy chủ WebDAV từ một tệp tin cục bộ
  Future<bool> uploadLocalFile(String localPath, String remotePath) async {
    if (_client == null) return false;
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        LoggerService().log('Local file does not exist for upload: $localPath', tag: 'WEBDAV', level: LogLevel.warning);
        return false;
      }
      LoggerService().log('Uploading local file ($localPath) to remote: $remotePath', tag: 'WEBDAV', level: LogLevel.info);
      await _client!.writeFromFile(localPath, remotePath);
      return true;
    } catch (e) {
      LoggerService().log('WebDAV uploadLocalFile failed to $remotePath', tag: 'WEBDAV', level: LogLevel.error, error: e.toString());
      return false;
    }
  }

  /// Tải tệp từ WebDAV về dưới dạng danh sách byte
  Future<List<int>?> downloadBytes(String remotePath) async {
    if (_client == null) return null;
    try {
      LoggerService().log('Downloading bytes from remote: $remotePath', tag: 'WEBDAV', level: LogLevel.info);
      return await _client!.read(remotePath);
    } catch (e) {
      LoggerService().log('WebDAV downloadBytes failed (file might not exist): $remotePath', tag: 'WEBDAV', level: LogLevel.warning, error: e.toString());
      return null;
    }
  }

  /// Tải tệp từ WebDAV về lưu vào một đường dẫn cục bộ
  Future<bool> downloadToLocalFile(String remotePath, String localPath) async {
    if (_client == null) return false;
    try {
      final localFile = File(localPath);
      final dir = localFile.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      LoggerService().log('Downloading remote file ($remotePath) to local: $localPath', tag: 'WEBDAV', level: LogLevel.info);
      await _client!.read2File(remotePath, localPath);
      return true;
    } catch (e) {
      LoggerService().log('WebDAV downloadToLocalFile failed for $remotePath', tag: 'WEBDAV', level: LogLevel.error, error: e.toString());
      return false;
    }
  }

  /// Kiểm tra xem tệp/thư mục có tồn tại trên WebDAV hay không
  Future<bool> fileExists(String remotePath) async {
    if (_client == null) return false;
    try {
      final list = await _client!.readDir(p.dirname(remotePath));
      final fileName = p.basename(remotePath);
      for (final f in list) {
        if (f.name == fileName || f.path?.endsWith(fileName) == true) {
          return true;
        }
      }
      return false;
    } catch (e) {
      LoggerService().log('WebDAV fileExists check failed for $remotePath (normal if path does not exist yet)', tag: 'WEBDAV', level: LogLevel.warning, error: e.toString());
      return false;
    }
  }

  /// Xóa tệp hoặc thư mục trên máy chủ WebDAV
  Future<bool> remove(String remotePath) async {
    if (_client == null) return false;
    try {
      await _client!.remove(remotePath);
      LoggerService().log('WebDAV successfully deleted file: $remotePath', tag: 'WEBDAV', level: LogLevel.info);
      return true;
    } catch (e) {
      LoggerService().log('WebDAV remove failed for path $remotePath', tag: 'WEBDAV', level: LogLevel.error, error: e.toString());
      return false;
    }
  }

  /// Lấy thông tin thuộc tính (mTime, eTag, size, ...) của một file trên WebDAV
  Future<webdav.File?> getFileMetadata(String remotePath) async {
    if (_client == null) return null;
    try {
      return await _client!.readProps(remotePath);
    } catch (e) {
      LoggerService().log('WebDAV getFileMetadata info/error (file might not exist yet): $remotePath', tag: 'WEBDAV', level: LogLevel.warning, error: e.toString());
      return null;
    }
  }
}
