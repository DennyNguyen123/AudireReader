import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import 'epub_parser.dart'; // Để dùng ParsedBookData
import 'text_book_segmenter.dart';

class PdfParser {
  static Future<ParsedBookData> parsePdfFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("File not found: $filePath");
    }

    final bytes = await file.readAsBytes();
    
    // Khởi tạo tài liệu PDF từ bytes
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    String rawText = "";

    try {
      // Khởi tạo bộ trích xuất văn bản và lấy toàn bộ nội dung text
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      rawText = extractor.extractText();
    } finally {
      // Đảm bảo đóng tài liệu PDF để giải phóng tài nguyên
      document.dispose();
    }

    // Lấy thông tin cơ bản của sách
    final filename = path.basenameWithoutExtension(filePath);
    final String title = filename.replaceAll('_', ' ').trim();
    final String author = "Unknown Author";
    final String uuid = "${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.abs()}";

    // Phân tách chương và đoạn văn bằng Segmenter dùng chung
    final List<Chapter> chapters = TextBookSegmenter.segment(rawText, uuid);

    final book = Book()
      ..uuid = uuid
      ..title = title
      ..author = author
      ..coverPath = null
      ..totalChapters = chapters.length
      ..dateAdded = DateTime.now();

    return ParsedBookData(book: book, chapters: chapters);
  }
}
