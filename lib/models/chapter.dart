import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';

part 'chapter.g.dart';

@collection
class Chapter {
  Id id = Isar.autoIncrement;

  @Index()
  late String bookUuid;

  late int chapterIndex;
  late String title;
  
  // Lưu trữ dữ liệu danh sách đoạn văn đã nén dạng gzip bằng kiểu List<byte> của Isar để tối ưu hóa 8-bit dung lượng
  late List<byte> paragraphsBytes;

  @ignore
  List<String>? _cachedParagraphs;

  @ignore
  List<String> get paragraphs {
    if (_cachedParagraphs != null) return _cachedParagraphs!;
    try {
      final decodedJson = utf8.decode(gzip.decode(paragraphsBytes));
      _cachedParagraphs = List<String>.from(json.decode(decodedJson));
      print('[RAM Diagnostic] Chapter $chapterIndex decompressed gzip paragraphs (${_cachedParagraphs?.length} items). Current Process RSS: ${(ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(1)} MB');
    } catch (e) {
      _cachedParagraphs = [];
    }
    return _cachedParagraphs!;
  }

  set paragraphs(List<String> value) {
    _cachedParagraphs = value;
    final jsonStr = json.encode(value);
    paragraphsBytes = gzip.encode(utf8.encode(jsonStr));
  }

  void clearCache() {
    if (_cachedParagraphs != null) {
      _cachedParagraphs = null;
      print('[RAM Diagnostic] Chapter $chapterIndex cleared paragraph cache. Current Process RSS: ${(ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(1)} MB');
    }
  }
}

