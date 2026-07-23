// ignore_for_file: avoid_print
import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:audire_reader/src/rust/api/models.dart';

class EpubParser {
  static Future<ParsedBookData> parseEpubFile(
    String filePath,
    String documentsDirPath,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("File not found: $filePath");
    }

    final bytes = await file.readAsBytes();
    final epubBook = await EpubReader.readBook(bytes);

    final String title = epubBook.Title ?? "Unknown Title";
    final String author = epubBook.Author ?? "Unknown Author";
    final String uuid =
        "${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.abs()}";

    // 1. Save Cover Image
    String? coverPath;

    // Cách 1: Đọc ảnh bìa chuẩn qua metadata (CoverImage)
    try {
      if (kDebugMode)
        debugPrint(
          "Total files in EPUB: ${epubBook.Content?.AllFiles?.length}",
        );
      if (kDebugMode)
        debugPrint("Total images in EPUB: ${epubBook.Content?.Images?.length}");

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
        if (kDebugMode) debugPrint("Method 1 (CoverImage) succeeded!");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Method 1 (epubBook.CoverImage) failed: $e");
    }

    // Cách 2: Quét file raw trong Content.Images nếu Cách 1 trống hoặc lỗi
    if (coverPath == null) {
      try {
        if (epubBook.Content?.Images != null &&
            epubBook.Content!.Images!.isNotEmpty) {
          final images = epubBook.Content!.Images!;
          String coverKey = images.keys.firstWhere(
            (k) => k.toLowerCase().contains('cover'),
            orElse: () => '',
          );

          if (coverKey.isEmpty) {
            coverKey = images.keys.firstWhere(
              (k) =>
                  k.toLowerCase().contains('thumb') ||
                  k.toLowerCase().contains('image'),
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
              final savedCoverFile = File(
                path.join(coverDir.path, '$uuid$fileExt'),
              );
              await savedCoverFile.writeAsBytes(contentBytes);
              coverPath = savedCoverFile.path;
              if (kDebugMode)
                debugPrint(
                  "Method 2 (Images scanning) succeeded with: $coverKey",
                );
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint("Method 2 (Images scanning) failed: $e");
      }
    }

    // Cách 3 (Siêu dự phòng): Quét toàn bộ tệp tin trong EPUB (AllFiles) tìm tệp ảnh
    if (coverPath == null) {
      try {
        if (epubBook.Content?.AllFiles != null &&
            epubBook.Content!.AllFiles!.isNotEmpty) {
          final allFiles = epubBook.Content!.AllFiles!;

          String coverKey = allFiles.keys.firstWhere((k) {
            final lowerK = k.toLowerCase();
            final isImage =
                lowerK.endsWith('.jpg') ||
                lowerK.endsWith('.jpeg') ||
                lowerK.endsWith('.png') ||
                lowerK.endsWith('.webp') ||
                lowerK.endsWith('.gif');
            return isImage && lowerK.contains('cover');
          }, orElse: () => '');

          if (coverKey.isEmpty) {
            coverKey = allFiles.keys.firstWhere((k) {
              final lowerK = k.toLowerCase();
              final isImage =
                  lowerK.endsWith('.jpg') ||
                  lowerK.endsWith('.jpeg') ||
                  lowerK.endsWith('.png') ||
                  lowerK.endsWith('.webp') ||
                  lowerK.endsWith('.gif');
              return isImage &&
                  (lowerK.contains('thumb') ||
                      lowerK.contains('image') ||
                      lowerK.contains('avatar'));
            }, orElse: () => '');
          }

          if (coverKey.isEmpty) {
            coverKey = allFiles.keys.firstWhere((k) {
              final lowerK = k.toLowerCase();
              return lowerK.endsWith('.jpg') ||
                  lowerK.endsWith('.jpeg') ||
                  lowerK.endsWith('.png') ||
                  lowerK.endsWith('.webp') ||
                  lowerK.endsWith('.gif');
            }, orElse: () => '');
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
                final savedCoverFile = File(
                  path.join(coverDir.path, '$uuid$fileExt'),
                );
                await savedCoverFile.writeAsBytes(contentBytes);
                coverPath = savedCoverFile.path;
                if (kDebugMode)
                  debugPrint(
                    "Method 3 (AllFiles scanning) succeeded with: $coverKey",
                  );
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint("Method 3 (AllFiles scanning) failed: $e");
      }
    }

    // 2. Parse Chapters
    final List<Chapter> chapters = [];
    int chapterIndex = 0;

    void extractChaptersRecursive(List<EpubChapter> epubChapters) {
      for (final epubChapter in epubChapters) {
        final String chapterTitle =
            epubChapter.Title ?? "Chapter ${chapterIndex + 1}";
        final String htmlContent = epubChapter.HtmlContent ?? "";

        // Parse HTML to clean plain text paragraphs
        final paragraphs = parseHtmlToParagraphs(htmlContent);

        if (paragraphs.isNotEmpty) {
          final chapter = Chapter(
            bookUuid: uuid,
            chapterIndex: chapterIndex,
            title: chapterTitle,
            paragraphs: paragraphs,
          );
          chapters.add(chapter);
          chapterIndex++;
        }

        if (epubChapter.SubChapters != null &&
            epubChapter.SubChapters!.isNotEmpty) {
          extractChaptersRecursive(epubChapter.SubChapters!);
        }
      }
    }

    if (epubBook.Chapters != null) {
      extractChaptersRecursive(epubBook.Chapters!);
    }

    // Many web novel EPUBs have chapters in arbitrary or alphabetical order.
    // Try to sort them naturally.
    if (chapters.isNotEmpty) {
      chapters.sort((a, b) => _naturalSortCompare(a.title, b.title));
      // Re-assign chapterIndex after sorting
      for (int i = 0; i < chapters.length; i++) {
        chapters[i] = chapters[i].copyWith(chapterIndex: i);
      }
    }

    final book = Book(
      uuid: uuid,
      title: title,
      author: author,
      coverPath: coverPath,
      totalChapters: chapters.length,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
      status: 'unread',
      tags: [],
    );

    return ParsedBookData(book: book, chapters: chapters);
  }

  static int _naturalSortCompare(String a, String b) {
    final regExp = RegExp(r'(\d+)|([^\d]+)');
    final matchesA = regExp.allMatches(a).map((m) => m.group(0)!).toList();
    final matchesB = regExp.allMatches(b).map((m) => m.group(0)!).toList();

    for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
      final partA = matchesA[i];
      final partB = matchesB[i];

      final intA = int.tryParse(partA);
      final intB = int.tryParse(partB);

      if (intA != null && intB != null) {
        final cmp = intA.compareTo(intB);
        if (cmp != 0) return cmp;
      } else {
        final cmp = partA.toLowerCase().compareTo(partB.toLowerCase());
        if (cmp != 0) return cmp;
      }
    }
    return matchesA.length.compareTo(matchesB.length);
  }

  @visibleForTesting
  static List<String> parseHtmlToParagraphs(String htmlContent) {
    if (htmlContent.isEmpty) return [];

    // Chuyển đổi các thẻ ngắt dòng tự động hoặc kết thúc thẻ thành ký tự xuống dòng
    // để tránh các dòng văn bản bị dính liền khi lấy text thô qua body.text
    final formattedHtml = htmlContent
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '</p>\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '</div>\n')
        .replaceAll(RegExp(r'</span>', caseSensitive: false), '</span>\n');

    final document = html_parser.parse(formattedHtml);
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

    final rawText = body.text.trim();
    final int totalCleanLength = cleanParas.fold<int>(
      0,
      (sum, p) => sum + p.length,
    );

    // Nếu không tìm thấy thẻ đoạn văn tiêu chuẩn nào,
    // HOẶC nếu tìm thấy nhưng tổng lượng văn bản trích xuất được quá nhỏ so với văn bản thô của body
    // (chênh lệch giữa văn bản thô và phần trích xuất > 40 ký tự, và phần trích xuất chiếm dưới 70% tổng văn bản thô),
    // chứng tỏ nội dung truyện đang nằm ở các thẻ khác như div, span, text tự do...
    // Chúng ta sẽ fallback sang phân tách toàn bộ văn bản thô theo dòng.
    final bool isMissingSignificantContent =
        (rawText.length - totalCleanLength > 40) &&
        (totalCleanLength < rawText.length * 0.7);

    if (cleanParas.isEmpty || isMissingSignificantContent) {
      return rawText
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
