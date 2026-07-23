import 'dart:io';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:path/path.dart' as path;
import 'package:audire_reader/src/rust/api/models.dart';
import 'epub_parser.dart'; // Để dùng ParsedBookData
import 'text_book_segmenter.dart';

class DocxParser {
  static Future<ParsedBookData> parseDocxFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("File not found: $filePath");
    }

    final bytes = await file.readAsBytes();

    // Trích xuất văn bản từ bytes của file .docx
    final String rawText = docxToText(bytes);

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
