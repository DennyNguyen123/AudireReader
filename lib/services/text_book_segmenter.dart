import 'package:audire_reader/src/rust/api/models.dart';

class TextBookSegmenter {
  /// Phân tích một chuỗi văn bản thô lớn thành danh sách các [Chapter]
  static List<Chapter> segment(String rawText, String bookUuid) {
    if (rawText.trim().isEmpty) return [];

    // Tiền xử lý: sửa lỗi font và gộp các dòng bị gãy
    final sanitizedText = _sanitizeText(rawText);
    List<String> lines = sanitizedText.split(RegExp(r'\r?\n'));
    lines = _cleanAndMergeLines(lines);

    final List<Chapter> chapters = [];

    // Regex tìm tiêu đề chương phổ biến
    // Ví dụ: "Chương 1: Khởi đầu", "Chapter 12 - The end", "Quyển 1 - Chương 5", "Tiết 3: ..."
    final chapterRegex = RegExp(
      r'^\s*(chương|chapter|tập|quyển|phần|tiết|q|ch|lớp)\s+([0-9\-\.\s]+|[ivxlcdm\s]+|[一二三四五六七八九十百千万\s]+)(\s*[\:\-\.\_]|\s+|$)',
      caseSensitive: false,
    );

    List<String> currentParagraphs = [];
    String currentChapterTitle = "";
    int chapterIndex = 0;

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Kiểm tra xem dòng hiện tại có phải là tiêu đề chương mới không
      if (chapterRegex.hasMatch(trimmedLine) && trimmedLine.length < 150) {
        // Nếu đã có nội dung từ chương trước, lưu lại chương đó
        if (currentParagraphs.isNotEmpty || currentChapterTitle.isNotEmpty) {
          chapters.add(
            Chapter(bookUuid: bookUuid, chapterIndex: chapterIndex, title: currentChapterTitle.isEmpty
                  ? "Chương $chapterIndex"
                  : currentChapterTitle, paragraphs: List.from(currentParagraphs),
          ));
          chapterIndex++;
          currentParagraphs.clear();
        }
        currentChapterTitle = trimmedLine;
      } else {
        currentParagraphs.add(trimmedLine);
      }
    }

    // Thêm chương cuối cùng nếu còn nội dung sót lại
    if (currentParagraphs.isNotEmpty || currentChapterTitle.isNotEmpty) {
      chapters.add(
        Chapter(bookUuid: bookUuid, chapterIndex: chapterIndex, title: currentChapterTitle.isEmpty
              ? "Chương $chapterIndex"
              : currentChapterTitle, paragraphs: List.from(currentParagraphs),
      ));
      chapterIndex++;
    }

    // Nếu không phát hiện chương nào thông qua Regex, hoặc chỉ có 1 chương nhưng dung lượng quá lớn
    // Ta sẽ kích hoạt cơ chế fallback: tự động chia chương ảo theo số lượng từ/đoạn văn.
    final bool needsFallback =
        chapters.isEmpty ||
        (chapters.length == 1 && chapters[0].paragraphs.length > 300);

    if (needsFallback) {
      return _segmentFallback(rawText, bookUuid);
    }

    return chapters;
  }

  /// Thuật toán chia chương ảo dự phòng khi không tìm thấy chương qua Regex
  static List<Chapter> _segmentFallback(String rawText, String bookUuid) {
    final List<String> lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final List<Chapter> chapters = [];
    List<String> chunk = [];
    int wordCount = 0;
    int chapterIndex = 0;

    // Mỗi chương ảo chứa khoảng 2000 từ để tối ưu cho việc render và đọc TTS
    const int maxWordsPerChapter = 2000;

    for (var line in lines) {
      chunk.add(line);
      // Đếm từ bằng cách tách theo khoảng trắng
      final wordsInLine = line.split(RegExp(r'\s+')).length;
      wordCount += wordsInLine;

      if (wordCount >= maxWordsPerChapter) {
        chapters.add(
          Chapter(bookUuid: bookUuid, chapterIndex: chapterIndex, title: "Phần ${chapterIndex + 1}", paragraphs: List.from(chunk),
        ));
        chapterIndex++;
        chunk.clear();
        wordCount = 0;
      }
    }

    // Thêm phần cuối cùng
    if (chunk.isNotEmpty) {
      chapters.add(
        Chapter(
          bookUuid: bookUuid,
          chapterIndex: chapterIndex,
          title: "Phần ${chapterIndex + 1}",
          paragraphs: List.from(chunk),
        ),
      );
    }

    return chapters;
  }

  /// Xử lý các lỗi font / ký tự đặc thù phổ biến từ việc bóc tách PDF
  static String _sanitizeText(String text) {
    // Xóa các ký tự ẩn (zero-width spaces) thường gặp trong PDF
    text = text.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // Loại bỏ chữ X viết hoa vô lý bị chèn vào giữa các chữ cái (ví dụ: sXách -> sách, ViXệt -> Việt)
    text = text.replaceAllMapped(
      RegExp(
        r'([a-zàáảãạâầấẩẫậăằắẳẵặeèéẻẽẹêềếểễệiìíỉĩịoòóỏõọôồốổỗộơờớởỡợuùúủũụưừứửữựyỳýỷỹỵđ])X([a-zàáảãạâầấẩẫậăằắẳẵặeèéẻẽẹêềếểễệiìíỉĩịoòóỏõọôồốổỗộơờớởỡợuùúủũụưừứửữựyỳýỷỹỵđ])',
      ),
      (match) => '${match[1]}${match[2]}',
    );

    // Sửa lỗi VV -> W (ví dụ: VVegener -> Wegener)
    text = text.replaceAll('VV', 'W');
    text = text.replaceAll('vv', 'w');
    // Sửa lỗi tinL -> tin.
    text = text.replaceAll('tinL.', 'tin.');
    text = text.replaceAll('tinL ', 'tin. ');
    return text;
  }

  /// Khắc phục lỗi rớt chữ (Drop cap) và gãy dòng khi bóc tách văn bản
  static List<String> _cleanAndMergeLines(List<String> rawLines) {
    List<String> merged = [];
    for (var line in rawLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (merged.isEmpty) {
        merged.add(trimmed);
        continue;
      }

      final last = merged.last;

      // Xử lý Drop cap: Dòng trước chỉ có 1 ký tự in hoa
      if (last.length == 1 &&
          RegExp(
            r'^[A-ZÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶEÈÉẺẼẸÊỀẾỂỄỆIÌÍỈĨỊOÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢUÙÚỦŨỤƯỪỨỬỮỰYỲÝỶỸỴĐ]$',
          ).hasMatch(last)) {
        merged[merged.length - 1] = last + trimmed; // Gộp không khoảng trắng
        continue;
      }

      // Nếu dòng trước kết thúc bằng dấu gạch ngang nối từ
      if (last.endsWith('-') && !last.endsWith(' - ')) {
        merged[merged.length - 1] =
            last.substring(0, last.length - 1) + trimmed;
        continue;
      }

      // Kiểm tra dòng hiện tại bắt đầu bằng chữ thường
      bool startsWithLowercase = RegExp(
        r'^[a-zàáảãạâầấẩẫậăằắẳẵặeèéẻẽẹêềếểễệiìíỉĩịoòóỏõọôồốổỗộơờớởỡợuùúủũụưừứửữựyỳýỷỹỵđ]',
      ).hasMatch(trimmed);

      // Kiểm tra dòng trước không kết thúc bằng dấu câu kết thúc
      bool endsWithPunctuation = RegExp(r'[.!?:;"\u0027\)\]]$').hasMatch(last);
      // Dòng trước đủ dài (có khả năng là văn bản bị ngắt dòng do hết giấy, không phải tiêu đề)
      bool isLongLine = last.length > 30;

      if (startsWithLowercase || (!endsWithPunctuation && isLongLine)) {
        merged[merged.length - 1] = '$last $trimmed';
      } else {
        merged.add(trimmed);
      }
    }
    return merged;
  }
}
