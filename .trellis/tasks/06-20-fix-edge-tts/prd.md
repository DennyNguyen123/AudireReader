# Fix Edge TTS iOS and Android

## Goal

Khắc phục triệt để lỗi Edge TTS bị dừng phát giữa chừng trên iOS (iPhone) và lỗi tự động chuyển về System TTS giọng nữ mặc định (HoaiMy) khi chọn giọng NamMinh trên Android.

## Requirements

1. **iOS (iPhone) - Phát âm thanh liên tục:**
   - Không bị dừng đột ngột giữa chừng khi phát âm thanh Edge TTS (chạy trong app lẫn chạy nền/khóa màn hình).
   - Tải và lưu tệp âm thanh Edge TTS thành tệp `.mp3` cục bộ trên thiết bị trước khi phát, không truyền phát trực tiếp (streaming) qua proxy localhost.

2. **Android - Đổi giọng chuẩn xác:**
   - Phát đúng giọng NamMinh (hoặc bất kỳ giọng nào người dùng chọn) trên Android, không tự động fallback về giọng nữ mặc định của hệ thống.
   - Loại bỏ hoàn toàn việc sử dụng proxy localhost cho stream để vượt qua chính sách chặn cleartext của Android.

3. **Chức năng bổ trợ không bị ảnh hưởng:**
   - Highlight chữ chạy theo từ đang đọc (word highlighting) vẫn phải hoạt động chính xác dựa trên siêu dữ liệu (metadata) của Edge TTS.
   - Tốc độ đọc (speech rate) được tùy chỉnh chính xác trên cả hai nền tảng.
   - Dọn dẹp tệp tin cache đã tải sau khi hết hạn (hơn 1 ngày) để tránh đầy dung lượng máy.
   - Khả năng hủy bỏ các tác vụ tải trước (prefetch) chạy ngầm khi người dùng ấn dừng hoặc chuyển bài để tối ưu băng thông và tránh bị Microsoft giới hạn (rate limit).

## Acceptance Criteria

- [x] Edge TTS trên iOS không bị ngắt quãng giữa chừng khi nghe thời gian dài hoặc khi chạy nền.
- [x] Edge TTS trên Android đổi giọng NamMinh phát ra đúng giọng nam, không bị chuyển sang giọng HoaiMy.
- [x] Chức năng highlight từ hoạt động chính xác, đồng bộ với giọng đọc của cả tệp mp3.
- [x] Các tác vụ tải trước (prefetch) được hủy kết nối thành công khi người dùng dừng phát hoặc chuyển chương.
- [x] Code sạch sẽ, loại bỏ lớp `EdgeTtsStreamAudioSource` không còn sử dụng.
