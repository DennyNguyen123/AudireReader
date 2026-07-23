import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:audire_reader/src/rust/api/models.dart';
import 'epub_parser.dart'; // Để dùng ParsedBookData
import 'text_book_segmenter.dart';

class TxtParser {
  static Future<ParsedBookData> parseTxtFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("File not found: $filePath");
    }

    // Đọc byte của file và decode dạng UTF-8 (cho phép ký tự malformed để tránh crash ứng dụng)
    final bytes = await file.readAsBytes();
    final rawText = utf8.decode(bytes, allowMalformed: true);

    // Lấy thông tin cơ bản của sách
    final filename = path.basenameWithoutExtension(filePath);
    final String title = filename.replaceAll('_', ' ').trim();
    final String author = "Unknown Author";
    final String uuid =
        "${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.abs()}";

    // Phân tách chương và đoạn văn bằng Segmenter dùng chung
    final List<Chapter> chapters = TextBookSegmenter.segment(rawText, uuid);

    final book = Book(
      uuid: uuid,
      title: title,
      author: author,
      coverPath: null,
      totalChapters: chapters.length,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
      status: 'unread',
      tags: [],
    );

    return ParsedBookData(book: book, chapters: chapters);
  }
}
