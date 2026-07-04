// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Audire Reader';

  @override
  String get library => 'Thư viện';

  @override
  String get settings => 'Cài đặt';

  @override
  String get searchBookHint => 'Tìm sách trên kệ...';

  @override
  String get sortBooks => 'Sắp xếp sách';

  @override
  String get sortByLastRead => 'Sắp xếp theo Lần đọc cuối';

  @override
  String get sortByTitle => 'Sắp xếp theo Tiêu đề';

  @override
  String get sortByDateAdded => 'Sắp xếp theo Ngày thêm';

  @override
  String get emptyShelf => 'Kệ sách của bạn đang trống';

  @override
  String get importBookHint =>
      'Chạm vào nút \"+\" để nhập sách (.epub, .txt, .pdf, .docx)';

  @override
  String get noBooksMatch => 'Không có sách nào khớp với tìm kiếm';

  @override
  String get syncCompleted => 'Đồng bộ hóa thành công!';

  @override
  String syncFailed(String message) {
    return 'Đồng bộ hóa thất bại: $message';
  }

  @override
  String syncError(String error) {
    return 'Lỗi đồng bộ: $error';
  }

  @override
  String get pleaseConfigureWebdav =>
      'Vui lòng bật và cấu hình WebDAV trong Cài đặt trước.';

  @override
  String get neverSynced => 'Chưa từng đồng bộ';

  @override
  String get justNow => 'Vừa xong';

  @override
  String minutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String todayAt(String time) {
    return 'Hôm nay lúc $time';
  }

  @override
  String deleteBookConfirm(String title) {
    return 'Đã xóa \"$title\"';
  }

  @override
  String successfullyImported(String title) {
    return 'Đã nhập thành công \"$title\"!';
  }

  @override
  String failedToImport(String error) {
    return 'Nhập sách thất bại: $error';
  }

  @override
  String get unread => 'Chưa đọc';

  @override
  String get reading => 'Đang đọc';

  @override
  String get completed => 'Đã đọc xong';

  @override
  String get all => 'Tất cả';

  @override
  String get aboutApp => 'Về ứng dụng';

  @override
  String version(String version) {
    return 'Phiên bản: $version';
  }

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get developerMode => 'Chế độ lập trình viên';

  @override
  String get debugLogs => 'Log Debug';

  @override
  String get webdavDebug => 'WebDAV Debug';

  @override
  String get databaseInspector => 'Kiểm tra cơ sở dữ liệu';

  @override
  String get clearCache => 'Xóa bộ nhớ đệm & Đặt lại đồng bộ';

  @override
  String get clearCacheSuccess =>
      'Đã xóa bộ nhớ đệm và đặt lại đồng bộ thành công.';

  @override
  String clearCacheFailed(String error) {
    return 'Xóa bộ nhớ đệm thất bại: $error';
  }

  @override
  String get hotkeys => 'Phím tắt & Phím nóng';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get reset => 'Đặt lại';

  @override
  String get generalPreferences => 'Tùy chọn chung';

  @override
  String get openLastReadOnLaunch => 'Mở sách đọc gần nhất khi khởi động';

  @override
  String get autoCheckUpdate => 'Tự động kiểm tra bản cập nhật';

  @override
  String get ttsSettings => 'Cài đặt TTS';

  @override
  String get ttsProvider => 'Nhà cung cấp TTS';

  @override
  String get voice => 'Giọng đọc';

  @override
  String get speed => 'Tốc độ';

  @override
  String get fontSize => 'Cỡ chữ';

  @override
  String get fontFamily => 'Phông chữ';

  @override
  String get themeMode => 'Chế độ giao diện';

  @override
  String get webdavSettings => 'Cài đặt đồng bộ WebDAV';

  @override
  String get enableWebdav => 'Bật đồng bộ WebDAV';

  @override
  String get webdavUrl => 'Đường dẫn WebDAV URL';

  @override
  String get webdavUsername => 'Tên đăng nhập WebDAV';

  @override
  String get webdavPassword => 'Mật khẩu WebDAV';

  @override
  String get testConnection => 'Kiểm tra kết nối';

  @override
  String get connectionSuccess => 'Kiểm tra kết nối thành công!';

  @override
  String connectionFailed(String error) {
    return 'Kiểm tra kết nối thất bại: $error';
  }

  @override
  String get dictionary => 'Từ điển phát âm';

  @override
  String get developerSettings => 'Cài đặt phát triển';

  @override
  String get checkUpdates => 'Kiểm tra cập nhật';

  @override
  String get system => 'Hệ thống';

  @override
  String get light => 'Sáng';

  @override
  String get dark => 'Tối';

  @override
  String get sepia => 'Ấm (Sepia)';

  @override
  String get deviceName => 'Tên Thiết Bị';

  @override
  String get enterDeviceName => 'Nhập tên thiết bị';

  @override
  String get syncConflictTitle => 'Phát hiện Xung đột';

  @override
  String syncConflictDesc(
    String deviceName,
    String cloudChapter,
    String localChapter,
  ) {
    return 'Tiến trình đọc hiện tại của bạn xung đột với dữ liệu từ máy \"$deviceName\".\n\nCloud: Chương $cloudChapter\nLocal: Chương $localChapter\n\nBạn muốn giữ lại tiến trình nào?';
  }

  @override
  String get keepLocal => 'Giữ Local';

  @override
  String get useCloud => 'Dùng Cloud';

  @override
  String get sortOptions => 'Tuỳ chọn sắp xếp';

  @override
  String get deleteBook => 'Xóa sách';

  @override
  String confirmDeleteBook(String title) {
    return 'Bạn có chắc chắn muốn xóa \"$title\" không?';
  }

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get readingAppearance => 'Giao diện đọc & Kiểu chữ';

  @override
  String get readingTheme => 'Chủ đề đọc';

  @override
  String get fontStyle => 'Kiểu phông chữ';

  @override
  String get readingSpeed => 'Tốc độ đọc';

  @override
  String get languageFilter => 'Bộ lọc ngôn ngữ';

  @override
  String get searchVoice => 'Tìm giọng đọc';

  @override
  String get selectVoice => 'Chọn giọng đọc';

  @override
  String get managePronunciation => 'Quản lý quy tắc phát âm';

  @override
  String get hotkeyConfigurations => 'Cấu hình phím nóng';

  @override
  String get customizeHotkeysDesc =>
      'Tùy chỉnh các phím tắt cho lệnh hệ thống và điều khiển đọc.';

  @override
  String get nextParagraph => 'Đoạn tiếp theo';

  @override
  String get prevParagraph => 'Đoạn trước';

  @override
  String get nextChapter => 'Chương tiếp theo';

  @override
  String get prevChapter => 'Chương trước';

  @override
  String get playPauseTts => 'Phát/Tạm dừng TTS';

  @override
  String get openChapterShelf => 'Mở danh sách chương';

  @override
  String get openReaderSetting => 'Mở cài đặt đọc';

  @override
  String get bossKey => 'Phím Boss';

  @override
  String get bossKeyActionLabel => 'Hành động phím Boss';

  @override
  String get minimizeWindow => 'Thu nhỏ cửa sổ';

  @override
  String get hideWindow => 'Ẩn cửa sổ (Hoàn toàn vô hình)';

  @override
  String get resetHotkeys => 'Đặt lại phím nóng mặc định';

  @override
  String get cloudLibrarySync => 'Đồng bộ thư viện đám mây';

  @override
  String get cloudSyncDesc =>
      'Đồng bộ kệ truyện, ảnh bìa, tiến trình đọc chính xác và nội dung sách giữa các thiết bị sử dụng máy chủ WebDAV cá nhân.';

  @override
  String get autoSyncDesc =>
      'Tự động đồng bộ tiến trình đọc của tất cả sách và cập nhật chỉ mục mây.';

  @override
  String get webdavServerConfig => 'Cấu hình máy chủ WebDAV';

  @override
  String get webdavServerUrl => 'Đường dẫn máy chủ WebDAV';

  @override
  String get username => 'Tên đăng nhập';

  @override
  String get passwordAppPassword => 'Mật khẩu / Mật khẩu ứng dụng';

  @override
  String get syncStatus => 'Trạng thái đồng bộ';

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String get developerModeDesc =>
      'Mở khóa các công cụ chẩn đoán nâng cao, trình kiểm tra cơ sở dữ liệu và nhật ký hệ thống.';

  @override
  String get enableDebugLogsLabel => 'Bật nhật ký gỡ lỗi';

  @override
  String get debugLogsDesc =>
      'Lưu lại lịch sử nhật ký ứng dụng để khắc phục sự cố.';

  @override
  String get webdavDebugConsole => 'Bảng điều khiển gỡ lỗi WebDAV';

  @override
  String get webdavDebugDesc =>
      'Ghi nhật ký yêu cầu và phản hồi HTTP WebDAV thô vào hệ thống.';

  @override
  String get openDebugConsole => 'Mở bảng điều khiển gỡ lỗi';

  @override
  String get forceSyncNow => 'Bắt buộc đồng bộ ngay';

  @override
  String get synchronizing => 'Đang đồng bộ...';

  @override
  String get processingSync => 'Đang xử lý sách, ảnh bìa và tiến trình đọc...';

  @override
  String get allLanguages => 'Tất cả ngôn ngữ';

  @override
  String get otherLanguages => 'Ngôn ngữ khác (Tiếng Nhật, Tiếng Pháp...)';

  @override
  String get searchVoiceHint => 'Nhập để tìm tên giọng đọc...';

  @override
  String get systemTtsOffline => 'Giọng đọc hệ thống (Ngoại tuyến)';

  @override
  String get edgeTtsOnline => 'Microsoft Edge TTS (Trực tuyến)';

  @override
  String get fillCredentialsHint =>
      'Vui lòng nhập đầy đủ thông tin đăng nhập trước.';

  @override
  String get connectionSuccessDesc =>
      'Kết nối thành công! Máy chủ WebDAV đang hoạt động.';

  @override
  String get connectionFailedDesc =>
      'Kết nối thất bại. Vui lòng xác minh URL, tên đăng nhập và mật khẩu.';

  @override
  String get syncSuccessful => 'Đồng bộ thành công';

  @override
  String get resetHotkeysSuccess =>
      'Tất cả phím nóng đã được đặt lại về giá trị mặc định.';

  @override
  String recordHotkey(String keyName) {
    return 'Ghi nhận phím tắt: $keyName';
  }

  @override
  String get pressHotkeyDesc =>
      'Nhấn tổ hợp phím trên bàn phím. Tránh các phím dành riêng của hệ thống.';

  @override
  String get pressKeys => 'Nhấn phím...';

  @override
  String get capturedSuccess => 'Đã ghi nhận thành công!';

  @override
  String get listeningKeystroke => 'Đang lắng nghe phím nhấn...';

  @override
  String get openLastReadDesc =>
      'Tự động tiếp tục đọc cuốn sách gần đây nhất khi khởi động.';

  @override
  String get autoCheckUpdateDesc =>
      'Tự động kiểm tra phiên bản mới từ GitHub khi ứng dụng khởi động.';

  @override
  String get enableWebdavFirst => 'Vui lòng bật đồng bộ WebDAV trước.';

  @override
  String lastSyncedAt(String time) {
    return 'Lần đồng bộ cuối: $time';
  }

  @override
  String get lastSyncedNever => 'Lần đồng bộ cuối: Chưa từng';

  @override
  String get enterWebdavUrl => 'Vui lòng nhập đường dẫn WebDAV URL';

  @override
  String get enterUsername => 'Vui lòng nhập tên đăng nhập';

  @override
  String get enterPassword => 'Vui lòng nhập mật khẩu';

  @override
  String get parsingBookContent => 'Đang xử lý nội dung sách...';

  @override
  String get importBook => 'Nhập sách';

  @override
  String get confirmDelete => 'Xác nhận xóa';

  @override
  String get delete => 'Xóa';

  @override
  String get close => 'Đóng';

  @override
  String chaptersCount(int count) {
    return '$count Chương';
  }

  @override
  String readPercent(String percent) {
    return 'Đã đọc $percent%';
  }

  @override
  String get bookmarkRemoved => 'Đã xóa dấu trang';

  @override
  String get bookmarkAdded => 'Đã thêm dấu trang';

  @override
  String get paragraphActions => 'Thao tác đoạn văn';

  @override
  String get editNote => 'Sửa ghi chú';

  @override
  String get addNote => 'Thêm ghi chú';

  @override
  String get copyText => 'Sao chép văn bản';

  @override
  String get copiedToClipboard => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String get removeHighlight => 'Xóa làm nổi bật';

  @override
  String get highlightRemoved => 'Đã xóa làm nổi bật';

  @override
  String get highlightSaved => 'Đã lưu làm nổi bật';

  @override
  String get typeNoteHint => 'Nhập ghi chú của bạn tại đây...';

  @override
  String get noteSaved => 'Đã lưu ghi chú';

  @override
  String get noBookActive => 'Không có sách nào đang hoạt động';

  @override
  String get readerSettings => 'Cài đặt trình đọc';

  @override
  String get displayTypography => 'HIỂN THỊ & KIỂU CHỮ';

  @override
  String get textToSpeechTts => 'CHUYỂN VĂN BẢN THÀNH GIỌNG NÓI (TTS)';

  @override
  String get sleepTimer => 'Hẹn giờ ngủ';

  @override
  String sleepTimerRemaining(String time) {
    return 'Hẹn giờ ngủ (còn $time)';
  }

  @override
  String get sleepTimerStopAtEnd => 'Hẹn giờ ngủ (Dừng ở cuối chương)';

  @override
  String get off => 'Tắt';

  @override
  String get endChapter => 'Cuối chương';

  @override
  String audioPanelProgress(
    int currentParagraph,
    int totalParagraphs,
    String percent,
    int currentChapter,
    int totalChapters,
    String chapterPercent,
  ) {
    return 'Đoạn $currentParagraph/$totalParagraphs ($percent%) • Chương $currentChapter/$totalChapters ($chapterPercent%)';
  }

  @override
  String get searchInsideBook => 'Tìm kiếm trong sách';

  @override
  String get typeKeyword => 'Nhập từ khóa...';

  @override
  String get enterKeywordToSearch => 'Nhập từ khóa để bắt đầu tìm kiếm';

  @override
  String get noResultsFound => 'Không tìm thấy kết quả';

  @override
  String get chaptersTab => 'Chương';

  @override
  String get bookmarksTab => 'Dấu trang';

  @override
  String get highlightsTab => 'Nổi bật';

  @override
  String get searchChaptersHint => 'Tìm kiếm chương...';

  @override
  String get noChaptersMatch => 'Không có chương nào khớp với tìm kiếm';

  @override
  String get noBookmarksSaved => 'Chưa có dấu trang nào được lưu';

  @override
  String paragraphIndexLabel(int index) {
    return 'Đoạn $index';
  }

  @override
  String get noHighlightsSaved => 'Chưa có phần nổi bật nào được lưu';

  @override
  String failedToLoadRules(String error) {
    return 'Tải quy tắc thất bại: $error';
  }

  @override
  String get ruleDeletedSuccessfully => 'Đã xóa quy tắc thành công';

  @override
  String failedToDeleteRule(String error) {
    return 'Xóa quy tắc thất bại: $error';
  }

  @override
  String failedToUpdateRule(String error) {
    return 'Cập nhật quy tắc thất bại: $error';
  }

  @override
  String get addPronunciationRule => 'Thêm quy tắc phát âm';

  @override
  String get editPronunciationRule => 'Sửa quy tắc phát âm';

  @override
  String get originalTextTarget => 'Văn bản gốc (Mục tiêu)';

  @override
  String get readAsReplacement => 'Đọc thành (Thay thế)';

  @override
  String get useRegularExpressionRegex => 'Sử dụng biểu thức chính quy (Regex)';

  @override
  String get advancedPatternMatching => 'Khớp mẫu nâng cao';

  @override
  String get pleaseFillBothFields => 'Vui lòng điền vào cả hai trường';

  @override
  String get ruleAddedSuccessfully => 'Thêm quy tắc thành công';

  @override
  String get ruleUpdatedSuccessfully => 'Cập nhật quy tắc thành công';

  @override
  String failedToSaveRule(String error) {
    return 'Lưu quy tắc thất bại: $error';
  }

  @override
  String confirmDeleteRuleTarget(String target) {
    return 'Bạn có chắc chắn muốn xóa quy tắc cho \"$target\" không?';
  }

  @override
  String get noCustomPronunciationRules =>
      'Không có quy tắc phát âm tùy chỉnh nào';

  @override
  String get tapToAddFirstRule =>
      'Chạm vào nút \"+\" để thêm quy tắc đầu tiên của bạn';

  @override
  String get regex => 'Regex';

  @override
  String get active => 'Hoạt động';

  @override
  String get inactive => 'Không hoạt động';

  @override
  String get debugConsole => 'Bảng điều khiển gỡ lỗi';

  @override
  String get copyAllLogs => 'Sao chép tất cả log';

  @override
  String get allLogsCopied => 'Đã sao chép tất cả log vào bộ nhớ tạm.';

  @override
  String get clearLogs => 'Xóa log';

  @override
  String get consoleLogsCleared => 'Đã xóa sạch log console.';

  @override
  String get searchLogsHint => 'Tìm kiếm log...';

  @override
  String get noMatchingLogs => 'Không tìm thấy log phù hợp';

  @override
  String get backgroundMusic => 'Nhạc nền (BGM)';

  @override
  String get enableBgm => 'Bật nhạc nền';

  @override
  String get bgmVolume => 'Âm lượng nhạc nền';

  @override
  String get bgmLoopMode => 'Chế độ lặp BGM';

  @override
  String get bgmSourceType => 'Loại nguồn';

  @override
  String get bgmSourceUrl => 'Liên kết / Mã Video BGM';

  @override
  String get bgmSourceUrlHint => 'Nhập link hoặc video ID...';

  @override
  String get addBgmTrack => 'Thêm bài BGM';

  @override
  String get trackName => 'Tên bài hát';

  @override
  String get selectLocalFile => 'Chọn file';

  @override
  String get addOnline => 'Thêm Online (Stream)';

  @override
  String get downloadOffline => 'Tải Offline';

  @override
  String get noLoop => 'Không lặp';

  @override
  String get loopOne => 'Lặp một bài';

  @override
  String get loopPlaylist => 'Lặp toàn danh sách';

  @override
  String get noBgmTracks => 'Chưa có bài nhạc nền nào được thêm';

  @override
  String downloading(String percent) {
    return 'Đang tải xuống... $percent%';
  }

  @override
  String get success => 'Thành công';

  @override
  String get error => 'Lỗi';

  @override
  String get forcePush => 'Đẩy lên mây (Ghi đè Cloud)';

  @override
  String get forcePull => 'Tải từ mây (Ghi đè Local)';

  @override
  String get forcePushConfirmTitle => 'Xác nhận Force Push';

  @override
  String get forcePushConfirmDesc =>
      'Hành động này sẽ ghi đè toàn bộ dữ liệu trên đám mây bằng dữ liệu trên thiết bị này. Bạn có chắc chắn muốn tiếp tục?';

  @override
  String get forcePullConfirmTitle => 'Xác nhận Force Pull';

  @override
  String get forcePullConfirmDesc =>
      'Hành động này sẽ ghi đè toàn bộ dữ liệu trên thiết bị này bằng dữ liệu từ đám mây. Sách và tiến trình cục bộ không có trên mây sẽ bị xóa. Bạn có chắc chắn muốn tiếp tục?';

  @override
  String get forcePushSuccess => 'Đẩy dữ liệu lên mây thành công!';

  @override
  String get forcePullSuccess => 'Tải dữ liệu từ mây về thành công!';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get onlySyncProgress => 'Chỉ ghi đè tiến trình đọc';

  @override
  String get onlySyncProgressDesc =>
      'Đồng bộ nhanh tiến trình đọc, giữ nguyên danh mục sách.';

  @override
  String get searchStation => 'Tìm kiếm đài phát...';

  @override
  String get addLink => 'Dán link URL';

  @override
  String get trackUrl => 'Đường dẫn Link (URL)';

  @override
  String get editTrack => 'Sửa thông tin nhạc';

  @override
  String get addSuccess => 'Đã thêm vào thư viện thành công!';

  @override
  String get updateSuccess => 'Cập nhật thành công!';

  @override
  String get deleteSuccess => 'Đã xóa thành công!';

  @override
  String get emptySearch => 'Không tìm thấy kết quả phù hợp';

  @override
  String get addFileOption => 'Chọn file cục bộ';

  @override
  String get addLinkOption => 'Dán link trực tiếp';

  @override
  String get importTrack => 'Thêm vào thư viện';

  @override
  String get forcePushBook => 'Đẩy đè lên đám mây (Force Push)';

  @override
  String get forcePullBook => 'Kéo đè về thiết bị (Force Pull)';

  @override
  String get forcePushBookConfirmTitle => 'Xác nhận Force Push Sách';

  @override
  String get forcePushBookConfirmDesc =>
      'Hành động này sẽ ghi đè cuốn sách này và tiến trình đọc của nó lên đám mây WebDAV. Bạn có chắc chắn muốn tiếp tục?';

  @override
  String get forcePullBookConfirmTitle => 'Xác nhận Force Pull Sách';

  @override
  String get forcePullBookConfirmDesc =>
      'Hành động này sẽ tải cuốn sách này và tiến trình đọc của nó từ đám mây WebDAV về để ghi đè lên máy này. Bạn có chắc chắn muốn tiếp tục?';

  @override
  String forcePushBookSuccess(String title) {
    return 'Đã đẩy sách \"$title\" lên đám mây thành công.';
  }

  @override
  String forcePullBookSuccess(String title) {
    return 'Đã kéo sách \"$title\" về máy thành công.';
  }

  @override
  String forcePushBookFailed(String error) {
    return 'Đẩy sách thất bại: $error';
  }

  @override
  String forcePullBookFailed(String error) {
    return 'Kéo sách thất bại: $error';
  }

  @override
  String get enableWebdavDesc => 'Đồng bộ thư viện qua máy chủ WebDAV cá nhân';

  @override
  String get autoSyncEnabled => 'Tự động đồng bộ WebDAV';

  @override
  String get autoSyncEnabledDesc =>
      'Tự động đồng bộ hóa thư viện khi khởi động ứng dụng và thoát màn hình đọc.';

  @override
  String get deleteDevice => 'Xóa trên thiết bị';

  @override
  String get deleteCloud => 'Xóa trên đám mây';

  @override
  String get uploadCloud => 'Tải lên đám mây';

  @override
  String get localSource => 'Thiết bị';

  @override
  String get cloudSource => 'Đám mây';

  @override
  String get syncProgress => 'Đồng bộ tiến trình';

  @override
  String get autoSyncTitle => 'Đồng bộ tự động (Sync Now)';

  @override
  String get forcePushDesc =>
      'Đẩy đè tất cả tệp sách cục bộ và tiến trình hiện tại lên WebDAV Cloud.';

  @override
  String get forcePullDesc =>
      'Tải toàn bộ tệp sách và tiến trình từ WebDAV Cloud về ghi đè lên máy này.';

  @override
  String syncBookProgressDesc(Object title) {
    return 'Đồng bộ hóa tiến trình đọc của truyện \"$title\"';
  }

  @override
  String get forcePushProgressDesc =>
      'Ghi đè tiến trình đọc hiện tại của máy này lên Cloud WebDAV.';

  @override
  String get forcePullProgressDesc =>
      'Kéo tiến trình đọc trên Cloud WebDAV về máy này.';

  @override
  String get deleteLocalOnly => 'Chỉ xóa Local';

  @override
  String get deleteBothLocalAndCloud => 'Xóa cả hai nơi';

  @override
  String deleteBookOptionsContent(String title) {
    return 'Bạn muốn xóa cuốn sách \"$title\" theo hình thức nào?\n\n• Chỉ xóa Local: Giải phóng dung lượng máy, vẫn giữ sách trên đám mây để tải lại sau.\n• Xóa cả hai nơi: Xóa vĩnh viễn sách ở cả máy này và trên đám mây WebDAV.';
  }

  @override
  String get deletedFromLocal => 'Đã xóa sách khỏi Local';

  @override
  String get deletedFromBoth => 'Đã xóa sách ở cả Local & Cloud';

  @override
  String get deleteFromCloudTitle => 'Xóa khỏi đám mây';

  @override
  String confirmDeleteFromCloud(String title) {
    return 'Bạn có chắc chắn muốn xóa cuốn sách \"$title\" khỏi máy chủ đám mây WebDAV không? Cuốn sách này chưa được tải về máy, hành động này sẽ xóa vĩnh viễn sách khỏi mây.';
  }

  @override
  String get requestedDeletionFromCloud => 'Đã gửi yêu cầu xóa khỏi Cloud';

  @override
  String get deleteBookTitle => 'Xóa sách';

  @override
  String get downloadBook => 'Tải xuống';

  @override
  String get bookNotOnCloudCannotPull =>
      'Cuốn sách này chưa từng được tải lên đám mây. Không thể kéo dữ liệu về.';

  @override
  String get bookNotOnCloudPushFull =>
      'Cuốn sách này chưa tồn tại trên đám mây. Hệ thống sẽ tải lên toàn bộ tệp sách và tiến trình đọc.';
}
