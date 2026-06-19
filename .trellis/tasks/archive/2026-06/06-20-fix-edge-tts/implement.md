# Kế hoạch triển khai sửa lỗi Edge TTS

Tài liệu này chứa danh sách các bước cần thực hiện để sửa lỗi dừng phát Edge TTS trên iOS và Android.

## Checklist triển khai

- [ ] **Bước 1: Chỉnh sửa cấu trúc lớp trong [audio_handler.dart](file:///d:/Personal_Sources/NovelReader/lib/services/audio_handler.dart)**
  - Xóa bỏ lớp `EdgeTtsStreamAudioSource`.
  - Thay đổi khai báo `CachedAudio` bằng cách bỏ thuộc tính `streamSource`.

- [ ] **Bước 2: Cập nhật hàm `prefetchSingle()` trong [audio_handler.dart](file:///d:/Personal_Sources/NovelReader/lib/services/audio_handler.dart)**
  - Gộp chung luồng xử lý tải Edge TTS cho tất cả nền tảng.
  - Lưu trữ bytes tải về trực tiếp dưới dạng tệp tin cục bộ `.mp3` sử dụng `PathHelper.getAppCacheDirectory()`.
  - Đăng ký `subscription` vào `_activePrefetches[cacheKey]` để quản lý đóng kết nối.

- [ ] **Bước 3: Cập nhật hàm `speak()` trong [audio_handler.dart](file:///d:/Personal_Sources/NovelReader/lib/services/audio_handler.dart)**
  - Loại bỏ logic phân chia hệ điều hành cũ.
  - Đợi tải tệp thông qua hàm `prefetchSingle` nếu tệp chưa có trong cache.
  - Khởi tạo nguồn phát qua tệp cục bộ sử dụng `ja.AudioSource.uri(Uri.file(cached.filePath!))`.

- [ ] **Bước 4: Xác minh biên dịch**
  - Chạy phân tích cú pháp để đảm bảo không lỗi biên dịch: `flutter analyze`.

---

## Kế hoạch kiểm thử & Kiểm chứng

### Kiểm thử thủ công (Manual Verification)
- Khởi chạy ứng dụng bằng lệnh:
  ```bash
  flutter run
  ```
- Kiểm tra tính năng TTS bằng cách chọn một chương truyện bất kỳ, thiết lập nguồn đọc là **Microsoft Edge TTS (Online)**.
- **Trên thiết bị Android (hoặc Giả lập):**
  - Vào phần cài đặt TTS, thay đổi giọng đọc thành **NamMinh (vi-VN-NamMinhNeural)**.
  - Nhấp Phát và xác nhận giọng đọc phát ra là giọng nam.
- **Trên thiết bị iOS (iPhone hoặc Giả lập):**
  - Nhấp Phát và nghe thử liên tục khoảng vài phút để xác nhận trình đọc chuyển tiếp các đoạn mượt mà, không bị dừng giữa chừng.
  - Bấm khóa màn hình điện thoại hoặc chuyển ứng dụng ra màn hình nền để xác nhận tính năng đọc chạy nền vẫn tiếp tục hoạt động.
- **Xác nhận tính năng Highlight:**
  - Xác nhận khi đọc đến từ nào thì từ đó trên màn hình được highlight tương ứng.
