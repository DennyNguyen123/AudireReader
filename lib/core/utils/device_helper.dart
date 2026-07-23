import 'dart:io';
import 'dart:math';

class DeviceHelper {
  static String generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    // Set version 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to RFC4122
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final chars = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .toList();
    return '${chars.sublist(0, 4).join()}-${chars.sublist(4, 6).join()}-${chars.sublist(6, 8).join()}-${chars.sublist(8, 10).join()}-${chars.sublist(10, 16).join()}';
  }

  static String getDefaultDeviceName() {
    try {
      final host = Platform.localHostname;
      final os = Platform.operatingSystem;
      // Trả về ví dụ: "Windows (My-PC)"
      if (host.isNotEmpty) {
        return '${os[0].toUpperCase()}${os.substring(1)} ($host)';
      }
      return '${os[0].toUpperCase()}${os.substring(1)} Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }
}
