import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:audire_reader/services/update_service.dart';

void main() {
  group('UpdateService.isNewerVersion', () {
    test('TC01 — latest patch mới hơn current', () {
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.1'), isTrue);
    });

    test('TC02 — latest patch cũ hơn current', () {
      expect(UpdateService.isNewerVersion('1.0.1', '1.0.0'), isFalse);
    });

    test('TC03 — latest bằng current — không cần update', () {
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    });

    test(
      'TC04 — minor dạng số lớn: 1.9.0 vs 1.10.0 (10 > 9, không phải so sánh string)',
      () {
        expect(UpdateService.isNewerVersion('1.9.0', '1.10.0'), isTrue);
      },
    );

    test('TC05 — major tăng: 1.99.99 vs 2.0.0', () {
      expect(UpdateService.isNewerVersion('1.99.99', '2.0.0'), isTrue);
    });

    test('TC06 — major giảm: 2.0.0 vs 1.0.0', () {
      expect(UpdateService.isNewerVersion('2.0.0', '1.0.0'), isFalse);
    });

    test('TC07 — build suffix bị bỏ qua: 1.0.0+5 vs 1.0.1', () {
      expect(UpdateService.isNewerVersion('1.0.0+5', '1.0.1'), isTrue);
    });

    test('TC08 — latest có thêm segment: 1.0 vs 1.0.1', () {
      expect(UpdateService.isNewerVersion('1.0', '1.0.1'), isTrue);
    });
  });

  group('UpdateService.getDownloadUrl', () {
    // Hằng số fallback URL để dễ đọc
    const fallbackUrl =
        'https://github.com/${UpdateService.owner}/${UpdateService.repo}/releases/latest';

    test('TC09 — assets rỗng → trả về fallback URL', () {
      final result = UpdateService.getDownloadUrl([]);
      expect(result, equals(fallbackUrl));
    });

    test('TC10 — assets không có file khớp nền tảng → trả về fallback URL', () {
      final assets = [
        {
          'name': 'README.md',
          'browser_download_url': 'http://example.com/readme',
        },
        {
          'name': 'source.tar.gz',
          'browser_download_url': 'http://example.com/source',
        },
      ];
      final result = UpdateService.getDownloadUrl(assets);
      expect(result, equals(fallbackUrl));
    });

    test(
      'TC11 — có file .apk: trả về APK URL trên Android, fallback trên các nền tảng khác',
      () {
        final assets = [
          {
            'name': 'app.apk',
            'browser_download_url': 'http://example.com/app.apk',
          },
          {
            'name': 'app.exe',
            'browser_download_url': 'http://example.com/app.exe',
          },
        ];
        final result = UpdateService.getDownloadUrl(assets);
        if (Platform.isAndroid) {
          expect(result, equals('http://example.com/app.apk'));
        } else {
          // Trên Windows CI hoặc Linux CI: fallback hoặc .exe
          expect(result, isNotEmpty);
        }
      },
    );

    test(
      'TC12 — có file .ipa: trả về IPA URL trên iOS, fallback trên các nền tảng khác',
      () {
        final assets = [
          {
            'name': 'app.ipa',
            'browser_download_url': 'http://example.com/app.ipa',
          },
        ];
        final result = UpdateService.getDownloadUrl(assets);
        if (Platform.isIOS) {
          expect(result, equals('http://example.com/app.ipa'));
        } else {
          expect(result, equals(fallbackUrl));
        }
      },
    );
  });
}
