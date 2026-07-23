// ignore_for_file: avoid_print
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:audire_reader/src/rust/api/sync.dart' as rust_sync;
import 'logger_service.dart';

class WebDavService {
  static WebDavService? _instance;
  bool _isInitialized = false;
  String? _lastUrl;
  String? _lastUsername;
  String? _lastPassword;

  WebDavService._();

  static WebDavService getInstance() {
    _instance ??= WebDavService._();
    return _instance!;
  }

  bool get isInitialized => _isInitialized;

  /// Khởi tạo kết nối WebDAV Client (gọi sang Rust)
  Future<void> init(String url, String username, String password) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    if (_isInitialized &&
        _lastUrl == formattedUrl &&
        _lastUsername == username.trim() &&
        _lastPassword == password) {
      // Cấu hình kết nối giữ nguyên, tái sử dụng client hiện tại
      return;
    }

    _lastUrl = formattedUrl;
    _lastUsername = username.trim();
    _lastPassword = password;

    final isDebugEnabled = LoggerService().enableWebDavDebug;
    LoggerService().log(
      'Initializing Rust WebDAV client with debug=$isDebugEnabled',
      tag: 'WEBDAV',
      level: LogLevel.info,
    );

    try {
      await rust_sync.webdavInit(
        url: formattedUrl,
        username: username.trim(),
        password: password,
      );
      _isInitialized = true;
    } catch (e) {
      LoggerService().log(
        'Failed to init Rust WebDAV client',
        tag: 'WEBDAV',
        level: LogLevel.error,
        error: e.toString(),
      );
      _isInitialized = false;
      rethrow;
    }
  }

  /// Kiểm tra kết nối tới máy chủ WebDAV
  Future<bool> testConnection() async {
    if (!_isInitialized) return false;
    LoggerService().log(
      'Testing connection to WebDAV server (Rust)...',
      tag: 'WEBDAV',
      level: LogLevel.info,
    );
    try {
      final success = await rust_sync.webdavTestConnection();
      if (success) {
        LoggerService().log(
          'WebDAV connection verified successfully.',
          tag: 'WEBDAV',
          level: LogLevel.info,
        );
      }
      return success;
    } catch (e) {
      LoggerService().log(
        'WebDAV connection test failed',
        tag: 'WEBDAV',
        level: LogLevel.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Tạo thư mục trên máy chủ WebDAV nếu chưa tồn tại
  Future<bool> mkdir(String remotePath) async {
    if (!_isInitialized) return false;
    try {
      final success = await rust_sync.webdavMkdir(remotePath: remotePath);
      LoggerService().log(
        'Created directory (or verified it exists): $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.info,
      );
      return success;
    } catch (e) {
      LoggerService().log(
        'Failed to create directory $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload nội dung chữ lên một file trên WebDAV (Overwrite nếu đã có)
  Future<bool> uploadText(String remotePath, String content) async {
    if (!_isInitialized) return false;
    try {
      final success = await rust_sync.webdavUploadBytes(
        remotePath: remotePath,
        bytes: content.codeUnits,
      );
      LoggerService().log(
        'Uploaded text to $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.info,
      );
      return success;
    } catch (e) {
      LoggerService().log(
        'Failed to upload text to $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Tải nội dung file từ WebDAV thành dạng chữ
  Future<String?> downloadText(String remotePath) async {
    if (!_isInitialized) return null;
    try {
      final bytes = await rust_sync.webdavDownloadBytes(remotePath: remotePath);
      LoggerService().log(
        'Downloaded text from $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.info,
      );
      return String.fromCharCodes(bytes);
    } catch (e) {
      LoggerService().log(
        'Failed to download text from $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.error,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Upload file cục bộ lên máy chủ WebDAV
  Future<bool> uploadFile(String remotePath, String localPath) async {
    if (!_isInitialized) return false;
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        throw Exception("Local file does not exist");
      }
      final bytes = await file.readAsBytes();
      final success = await rust_sync.webdavUploadBytes(
        remotePath: remotePath,
        bytes: bytes,
      );
      LoggerService().log(
        'Uploaded file from $localPath to $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.info,
      );
      return success;
    } catch (e) {
      LoggerService().log(
        'Failed to upload file to $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Download file từ máy chủ WebDAV về bộ nhớ cục bộ
  Future<bool> downloadFile(String remotePath, String localPath) async {
    if (!_isInitialized) return false;
    try {
      final bytes = await rust_sync.webdavDownloadBytes(remotePath: remotePath);
      final file = File(localPath);
      
      // Ensure the parent directory exists
      final dir = file.parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      
      await file.writeAsBytes(bytes);
      LoggerService().log(
        'Downloaded file from $remotePath to $localPath',
        tag: 'WEBDAV',
        level: LogLevel.info,
      );
      return true;
    } catch (e) {
      LoggerService().log(
        'Failed to download file from $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Xóa file hoặc thư mục trên WebDAV
  Future<bool> remove(String remotePath) async {
    if (!_isInitialized) return false;
    try {
      final success = await rust_sync.webdavRemove(remotePath: remotePath);
      LoggerService().log(
        'Removed file/folder: $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.info,
      );
      return success;
    } catch (e) {
      LoggerService().log(
        'Failed to remove $remotePath',
        tag: 'WEBDAV',
        level: LogLevel.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Ngắt kết nối
  void disconnect() {
    // Không cần ngắt kết nối thực sự vì client Rust được quản lý bằng static Mutex
    _isInitialized = false;
    _lastUrl = null;
    _lastUsername = null;
    _lastPassword = null;
    LoggerService().log(
      'Disconnected from WebDAV server',
      tag: 'WEBDAV',
      level: LogLevel.info,
    );
  }

  /// Tải tệp từ WebDAV về dưới dạng danh sách byte
  Future<List<int>?> downloadBytes(String remotePath) async {
    if (!_isInitialized) return null;
    try {
      final bytes = await rust_sync.webdavDownloadBytes(remotePath: remotePath);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Tải tệp lên máy chủ WebDAV từ danh sách byte
  Future<bool> uploadBytes(String remotePath, List<int> bytes) async {
    if (!_isInitialized) return false;
    try {
      return await rust_sync.webdavUploadBytes(
        remotePath: remotePath,
        bytes: bytes,
      );
    } catch (_) {
      return false;
    }
  }

  /// Tải tệp lên máy chủ WebDAV từ một tệp tin cục bộ
  Future<bool> uploadLocalFile(String localPath, String remotePath) async {
    return uploadFile(remotePath, localPath);
  }

  /// Tải tệp từ WebDAV về lưu vào một đường dẫn cục bộ
  Future<bool> downloadToLocalFile(String remotePath, String localPath) async {
    return downloadFile(remotePath, localPath);
  }

  /// Kiểm tra xem tệp/thư mục có tồn tại trên WebDAV hay không
  Future<bool> fileExists(String remotePath) async {
    if (!_isInitialized) return false;
    try {
      return await rust_sync.webdavFileExists(remotePath: remotePath);
    } catch (_) {
      return false;
    }
  }

  /// Lấy thông tin thuộc tính của một file trên WebDAV (dummy data for compatibility)
  Future<dynamic> getFileMetadata(String remotePath) async {
    if (!_isInitialized) return null;
    if (await fileExists(remotePath)) {
      return {}; // Returns empty map instead of null to indicate existence
    }
    return null;
  }
}
