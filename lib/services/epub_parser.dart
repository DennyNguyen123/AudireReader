import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../models/book.dart';
import '../models/chapter.dart';

class EpubParser {
  static Future<ParsedBookData> parseEpubFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("File not found: $filePath");
    }

    final bytes = await file.readAsBytes();
    final epubBook = await EpubReader.readBook(bytes);

    final String title = epubBook.Title ?? "Unknown Title";
    final String author = epubBook.Author ?? "Unknown Author";
    final String uuid = "${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.abs()}";

    // 1. Save Cover Image
    String? coverPath;
    try {
      final coverImage = epubBook.CoverImage;
      if (coverImage != null) {
        final docDir = await getApplicationDocumentsDirectory();
        final coverDir = Directory(path.join(docDir.path, 'covers'));
        if (!await coverDir.exists()) {
          await coverDir.create(recursive: true);
        }
        final savedCoverFile = File(path.join(coverDir.path, '$uuid.png'));
        final pngBytes = img.encodePng(coverImage);
        await savedCoverFile.writeAsBytes(pngBytes);
        coverPath = savedCoverFile.path;
      }
    } catch (e) {
      print("Failed to parse cover image: $e");
    }

    // 2. Parse Chapters
    final List<Chapter> chapters = [];
    int chapterIndex = 0;

    void extractChaptersRecursive(List<EpubChapter> epubChapters) {
      for (final epubChapter in epubChapters) {
        final String chapterTitle = epubChapter.Title ?? "Chapter ${chapterIndex + 1}";
        final String htmlContent = epubChapter.HtmlContent ?? "";

        // Parse HTML to clean plain text paragraphs
        final paragraphs = _parseHtmlToParagraphs(htmlContent);

        if (paragraphs.isNotEmpty) {
          final chapter = Chapter()
            ..bookUuid = uuid
            ..chapterIndex = chapterIndex
            ..title = chapterTitle
            ..paragraphs = paragraphs;
          chapters.add(chapter);
          chapterIndex++;
        }

        if (epubChapter.SubChapters != null && epubChapter.SubChapters!.isNotEmpty) {
          extractChaptersRecursive(epubChapter.SubChapters!);
        }
      }
    }

    if (epubBook.Chapters != null) {
      extractChaptersRecursive(epubBook.Chapters!);
    }

    final book = Book()
      ..uuid = uuid
      ..title = title
      ..author = author
      ..coverPath = coverPath
      ..totalChapters = chapters.length
      ..dateAdded = DateTime.now();

    return ParsedBookData(book: book, chapters: chapters);
  }

  static List<String> _parseHtmlToParagraphs(String htmlContent) {
    if (htmlContent.isEmpty) return [];

    final document = html_parser.parse(htmlContent);
    final body = document.body;
    if (body == null) return [];

    final List<String> cleanParas = [];
    // Quét qua các thẻ tiêu đề và thẻ đoạn văn phổ biến
    final tags = body.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li');
    
    for (final tag in tags) {
      final txt = tag.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (txt.isNotEmpty && txt.length > 2) {
        if (cleanParas.isEmpty || cleanParas.last != txt) {
          cleanParas.add(txt);
        }
      }
    }

    // Nếu không tìm thấy thẻ đoạn văn tiêu chuẩn nào, phân tách theo dòng
    if (cleanParas.isEmpty) {
      final txt = body.text.trim();
      return txt
          .split('\n')
          .map((e) => e.trim().replaceAll(RegExp(r'\s+'), ' '))
          .where((e) => e.length > 2)
          .toList();
    }

    return cleanParas;
  }
}

class ParsedBookData {
  final Book book;
  final List<Chapter> chapters;

  ParsedBookData({required this.book, required this.chapters});
}
