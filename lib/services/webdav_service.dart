// ignore_for_file: avoid_print
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

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
    // Đảm bảo URL có định dạng hợp lệ
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    _client = webdav.newClient(
      formattedUrl,
      user: username.trim(),
      password: password,
      debug: false,
    );
    _isInitialized = true;
  }

  /// Kiểm tra kết nối tới máy chủ WebDAV
  Future<bool> testConnection() async {
    if (_client == null) return false;
    try {
      // Thử đọc thư mục gốc để xác thực tài khoản và kiểm tra kết nối
      await _client!.readDir('/');
      return true;
    } catch (e) {
      print('WebDAV connection test failed: $e');
      return false;
    }
  }

  /// Tạo thư mục trên máy chủ WebDAV nếu chưa tồn tại
  Future<bool> mkdir(String remotePath) async {
    if (_client == null) return false;
    try {
      await _client!.mkdir(remotePath);
      return true;
    } catch (e) {
      // Nếu thư mục đã tồn tại, WebDAV có thể trả về lỗi 405 hoặc tương tự, coi như thành công
      print('WebDAV mkdir info/error (might already exist): $e');
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

      await _client!.writeFromFile(tempFile.path, remotePath);
      return true;
    } catch (e) {
      print('WebDAV uploadBytes failed: $e');
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
        print('Local file does not exist: $localPath');
        return false;
      }
      await _client!.writeFromFile(localPath, remotePath);
      return true;
    } catch (e) {
      print('WebDAV uploadLocalFile failed: $e');
      return false;
    }
  }

  /// Tải tệp từ WebDAV về dưới dạng danh sách byte
  Future<List<int>?> downloadBytes(String remotePath) async {
    if (_client == null) return null;
    try {
      return await _client!.read(remotePath);
    } catch (e) {
      print('WebDAV downloadBytes failed (file might not exist): $e');
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
      await _client!.read2File(remotePath, localPath);
      return true;
    } catch (e) {
      print('WebDAV downloadToLocalFile failed: $e');
      return false;
    }
  }

  /// Kiểm tra xem tệp/thư mục có tồn tại trên WebDAV hay không
  Future<bool> fileExists(String remotePath) async {
    if (_client == null) return false;
    try {
      // Cách kiểm tra tốt nhất là thử đọc thông tin thư mục chứa nó hoặc chính nó
      final list = await _client!.readDir(p.dirname(remotePath));
      final fileName = p.basename(remotePath);
      for (final f in list) {
        // Tên file so khớp không phân biệt hoa thường hoặc khớp chính xác tên
        if (f.name == fileName || f.path?.endsWith(fileName) == true) {
          return true;
        }
      }
      return false;
    } catch (e) {
      // Nếu thư mục cha không tồn tại hoặc lỗi, coi như file không tồn tại
      print('WebDAV fileExists check failed (normal if folder/file not created yet): $e');
      return false;
    }
  }

  /// Xóa tệp hoặc thư mục trên máy chủ WebDAV
  Future<bool> remove(String remotePath) async {
    if (_client == null) return false;
    try {
      await _client!.remove(remotePath);
      print('WebDAV successfully deleted file: $remotePath');
      return true;
    } catch (e) {
      print('WebDAV remove failed for path $remotePath: $e');
      return false;
    }
  }
}
