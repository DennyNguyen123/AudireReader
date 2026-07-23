import 'package:flutter_test/flutter_test.dart';
import 'package:audire_reader/services/epub_parser.dart';

void main() {
  group('EpubParser.parseHtmlToParagraphs', () {
    test('TC13 — HTML rỗng → trả về danh sách rỗng', () {
      final result = EpubParser.parseHtmlToParagraphs('');
      expect(result, isEmpty);
    });

    test('TC14 — HTML có thẻ <p> cơ bản → trích xuất đúng nội dung', () {
      const html = '<html><body><p>Hello world</p></body></html>';
      final result = EpubParser.parseHtmlToParagraphs(html);
      expect(result, equals(['Hello world']));
    });

    test('TC15 — HTML có thẻ tiêu đề h1, h2 → trích xuất cả hai', () {
      const html = '<html><body><h1>Chương 1</h1><h2>Phần A</h2></body></html>';
      final result = EpubParser.parseHtmlToParagraphs(html);
      expect(result, equals(['Chương 1', 'Phần A']));
    });

    test('TC16 — Text ngắn hơn 3 ký tự bị loại bỏ', () {
      const html =
          '<html><body><p>Hi</p><p>Đây là đoạn dài đủ điều kiện</p></body></html>';
      final result = EpubParser.parseHtmlToParagraphs(html);
      expect(result, equals(['Đây là đoạn dài đủ điều kiện']));
      expect(result, isNot(contains('Hi')));
    });

    test('TC17 — Đoạn văn trùng lặp liên tiếp chỉ giữ lại một bản', () {
      const html =
          '<html><body><p>Same paragraph</p><p>Same paragraph</p></body></html>';
      final result = EpubParser.parseHtmlToParagraphs(html);
      expect(result, equals(['Same paragraph']));
      expect(result.length, equals(1));
    });

    test('TC18 — Fallback: không có thẻ chuẩn → phân tách theo dòng', () {
      // Nội dung body text không có thẻ p/h1..h6/li
      const html =
          '<html><body>Line Alpha\nLine Beta\nLine Gamma</body></html>';
      final result = EpubParser.parseHtmlToParagraphs(html);
      expect(result, containsAll(['Line Alpha', 'Line Beta', 'Line Gamma']));
    });

    test(
      'TC19 — Fallback: có thẻ h2 (tiêu đề) nhưng nội dung chính nằm trong div không chuẩn kèm br',
      () {
        const html = '''
        <html>
          <body>
            <h2>Chương 26: Liễu Thanh Nhi lải nhải (1)</h2>
            <div class="content">
              Đoạn văn thứ nhất của truyện.<br/>
              Đoạn văn thứ hai của truyện.<br/>
              Đoạn văn thứ ba dài hơn của truyện.
            </div>
          </body>
        </html>
      ''';
        final result = EpubParser.parseHtmlToParagraphs(html);
        expect(result, contains('Chương 26: Liễu Thanh Nhi lải nhải (1)'));
        expect(result, contains('Đoạn văn thứ nhất của truyện.'));
        expect(result, contains('Đoạn văn thứ hai của truyện.'));
        expect(result, contains('Đoạn văn thứ ba dài hơn của truyện.'));
        expect(result.length, equals(4));
      },
    );

    test(
      'TC20 — Có thẻ p nhưng nội dung chiếm đa số nằm ngoài thẻ p (thẻ span lồng nhau)',
      () {
        const html = '''
        <html>
          <body>
            <p class="title">Chương 26</p>
            <span class="text">Đoạn 1 của truyện</span>
            <span class="text">Đoạn 2 của truyện</span>
            <span class="text">Đoạn 3 của truyện</span>
          </body>
        </html>
      ''';
        final result = EpubParser.parseHtmlToParagraphs(html);
        expect(result, contains('Chương 26'));
        expect(result, contains('Đoạn 1 của truyện'));
        expect(result, contains('Đoạn 2 của truyện'));
        expect(result, contains('Đoạn 3 của truyện'));
        expect(result.length, equals(4));
      },
    );
  });
}
