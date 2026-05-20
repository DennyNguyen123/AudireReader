// ignore_for_file: avoid_print
import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../models/book.dart';
import '../models/chapter.dart';

class EpubParser {
  static Future<ParsedBookData> parseEpubFile(String filePath, String documentsDirPath) async {
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
    
    // Cách 1: Đọc ảnh bìa chuẩn qua metadata (CoverImage)
    try {
      print("Total files in EPUB: ${epubBook.Content?.AllFiles?.length}");
      print("Total images in EPUB: ${epubBook.Content?.Images?.length}");
      
      final coverImage = epubBook.CoverImage;
      if (coverImage != null) {
        final docDir = Directory(documentsDirPath);
        final coverDir = Directory(path.join(docDir.path, 'covers'));
        if (!await coverDir.exists()) {
          await coverDir.create(recursive: true);
        }
        final savedCoverFile = File(path.join(coverDir.path, '$uuid.png'));
        final pngBytes = img.encodePng(coverImage);
        await savedCoverFile.writeAsBytes(pngBytes);
        coverPath = savedCoverFile.path;
        print("Method 1 (CoverImage) succeeded!");
      }
    } catch (e) {
      print("Method 1 (epubBook.CoverImage) failed: $e");
    }

    // Cách 2: Quét file raw trong Content.Images nếu Cách 1 trống hoặc lỗi
    if (coverPath == null) {
      try {
        if (epubBook.Content?.Images != null && epubBook.Content!.Images!.isNotEmpty) {
          final images = epubBook.Content!.Images!;
          String coverKey = images.keys.firstWhere(
            (k) => k.toLowerCase().contains('cover'),
            orElse: () => '',
          );
          
          if (coverKey.isEmpty) {
            coverKey = images.keys.firstWhere(
              (k) => k.toLowerCase().contains('thumb') || k.toLowerCase().contains('image'),
              orElse: () => images.keys.first,
            );
          }

          final coverFile = images[coverKey];
          if (coverFile != null) {
            final contentBytes = coverFile.Content;
            if (contentBytes != null && contentBytes.isNotEmpty) {
              final docDir = Directory(documentsDirPath);
              final coverDir = Directory(path.join(docDir.path, 'covers'));
              if (!await coverDir.exists()) {
                await coverDir.create(recursive: true);
              }
              
              final ext = path.extension(coverKey).toLowerCase();
              final fileExt = ext.isNotEmpty ? ext : '.png';
              final savedCoverFile = File(path.join(coverDir.path, '$uuid$fileExt'));
              await savedCoverFile.writeAsBytes(contentBytes);
              coverPath = savedCoverFile.path;
              print("Method 2 (Images scanning) succeeded with: $coverKey");
            }
          }
        }
      } catch (e) {
        print("Method 2 (Images scanning) failed: $e");
      }
    }

    // Cách 3 (Siêu dự phòng): Quét toàn bộ tệp tin trong EPUB (AllFiles) tìm tệp ảnh
    if (coverPath == null) {
      try {
        if (epubBook.Content?.AllFiles != null && epubBook.Content!.AllFiles!.isNotEmpty) {
          final allFiles = epubBook.Content!.AllFiles!;
          
          String coverKey = allFiles.keys.firstWhere(
            (k) {
              final lowerK = k.toLowerCase();
              final isImage = lowerK.endsWith('.jpg') || 
                              lowerK.endsWith('.jpeg') || 
                              lowerK.endsWith('.png') || 
                              lowerK.endsWith('.webp') ||
                              lowerK.endsWith('.gif');
              return isImage && lowerK.contains('cover');
            },
            orElse: () => '',
          );
          
          if (coverKey.isEmpty) {
            coverKey = allFiles.keys.firstWhere(
              (k) {
                final lowerK = k.toLowerCase();
                final isImage = lowerK.endsWith('.jpg') || 
                                lowerK.endsWith('.jpeg') || 
                                lowerK.endsWith('.png') || 
                                lowerK.endsWith('.webp') ||
                                lowerK.endsWith('.gif');
                return isImage && (lowerK.contains('thumb') || lowerK.contains('image') || lowerK.contains('avatar'));
              },
              orElse: () => '',
            );
          }
          
          if (coverKey.isEmpty) {
            coverKey = allFiles.keys.firstWhere(
              (k) {
                final lowerK = k.toLowerCase();
                return lowerK.endsWith('.jpg') || 
                       lowerK.endsWith('.jpeg') || 
                       lowerK.endsWith('.png') || 
                       lowerK.endsWith('.webp') ||
                       lowerK.endsWith('.gif');
              },
              orElse: () => '',
            );
          }

          if (coverKey.isNotEmpty) {
            final coverFile = allFiles[coverKey];
            if (coverFile is EpubByteContentFile) {
              final contentBytes = coverFile.Content;
              if (contentBytes != null && contentBytes.isNotEmpty) {
                final docDir = Directory(documentsDirPath);
                final coverDir = Directory(path.join(docDir.path, 'covers'));
                if (!await coverDir.exists()) {
                  await coverDir.create(recursive: true);
                }
                final ext = path.extension(coverKey).toLowerCase();
                final fileExt = ext.isNotEmpty ? ext : '.png';
                final savedCoverFile = File(path.join(coverDir.path, '$uuid$fileExt'));
                await savedCoverFile.writeAsBytes(contentBytes);
                coverPath = savedCoverFile.path;
                print("Method 3 (AllFiles scanning) succeeded with: $coverKey");
              }
            }
          }
        }
      } catch (e) {
        print("Method 3 (AllFiles scanning) failed: $e");
      }
    }

    // 2. Parse Chapters
    final List<Chapter> chapters = [];
    int chapterIndex = 0;

    void extractChaptersRecursive(List<EpubChapter> epubChapters) {
      for (final epubChapter in epubChapters) {
        final String chapterTitle = epubChapter.Title ?? "Chapter ${chapterIndex + 1}";
        final String htmlContent = epubChapter.HtmlContent ?? "";

        // Parse HTML to clean plain text paragraphs
        final paragraphs = parseHtmlToParagraphs(htmlContent);

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

  @visibleForTesting
  static List<String> parseHtmlToParagraphs(String htmlContent) {
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
