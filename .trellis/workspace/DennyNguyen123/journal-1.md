# Journal - DennyNguyen123 (Part 1)

> AI development session journal
> Started: 2026-06-19

---



## Session 1: Thêm hỗ trợ OpenAI TTS

**Date**: 2026-06-25
**Task**: Thêm hỗ trợ OpenAI TTS
**Branch**: `main`

### Summary

Cập nhật AppSettings, AudioHandler, TtsService và giao diện để cấu hình Endpoint, API Key và Model cho OpenAI TTS.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 2: Custom Sleep Timer

**Date**: 2026-06-25
**Task**: Custom Sleep Timer
**Branch**: `main`

### Summary

Added custom sleep timer input via dialog and a countdown indicator in the reading screen AppBar.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 3: Refactor EdgeTTS to Bing Translator HTTP API

**Date**: 2026-06-25
**Task**: Refactor EdgeTTS to Bing Translator HTTP API
**Branch**: `main`

### Summary

Nâng cấp EdgeTtsService sử dụng HTTP POST giống với 9router để tăng độ ổn định. Đã xóa bỏ WebSocket và tự động quản lý token cookie.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 4: Integrate Multi-Provider BGM

**Date**: 2026-06-25
**Task**: Integrate Multi-Provider BGM
**Branch**: `main`

### Summary

Created BgmProvider interface. Added RadioBrowserProvider and OpenLofiProvider. Refactored BgmService to support multiple providers, stream URL sources, and automatic fallback to Local on network failure. Wrote unit tests for new providers. Updated UI in BgmPlayerSheet to select providers.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 5: Explain Shorebird patch limitations and workflow

**Date**: 2026-06-25
**Task**: Explain Shorebird patch limitations and workflow
**Branch**: `main`

### Summary

Analyzed Shorebird logs and explained UnpatchableChangeException due to asset/font changes. Clarified usage of 'shorebird release' vs 'shorebird patch' when upgrading versions.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 6: Thêm nút Force Push và Force Pull đồng bộ WebDAV

**Date**: 2026-07-03
**Task**: Thêm nút Force Push và Force Pull đồng bộ WebDAV
**Branch**: `main`

### Summary

Bổ sung phương thức forcePush() và forcePull() vào SyncService; thêm giao diện nút bấm trong WebdavSettingsSection & SyncSettingsScreen; thêm icon thao tác nhanh trên AppBar của LibraryScreen kèm hộp thoại cảnh báo xác nhận an toàn

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 7: Bổ sung tùy chọn Chỉ ghi đè tiến trình đọc cho Force Push và Force Pull

**Date**: 2026-07-03
**Task**: Bổ sung tùy chọn Chỉ ghi đè tiến trình đọc cho Force Push và Force Pull
**Branch**: `main`

### Summary

Thêm tham số progressOnly vào hàm forcePush và forcePull trong SyncService; Cập nhật Dialog xác nhận trong SyncSettingsScreen và LibraryScreen hỗ trợ checkbox lựa chọn; Tối ưu hóa hiệu năng đồng bộ toàn bộ bằng cách kiểm tra tệp sách tồn tại trước khi upload/download; Cập nhật đa ngôn ngữ app_vi.arb và app_en.arb.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 8: Hoan thanh tim kiem, them dai phat radio va nho vi tri theo URL

**Date**: 2026-07-03
**Task**: Hoan thanh tim kiem, them dai phat radio va nho vi tri theo URL
**Branch**: `main`

### Summary

Sua loi nho phan dang nghe BGM theo URL; them tinh nang search dai radio, add vao thu vien, sua va xoa link truc tiep

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 9: Sua loi compile settings va bgm_player_sheet

**Date**: 2026-07-03
**Task**: Sua loi compile settings va bgm_player_sheet
**Branch**: `main`

### Summary

Bo sung import va fix syntax Column children trong bgm_player_sheet, bo sung truong setting con thieu

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 10: Cai tien chon nguon nhac nen BGM

**Date**: 2026-07-03
**Task**: Cai tien chon nguon nhac nen BGM
**Branch**: `main`

### Summary

Da loai bo dropdown chon Source o cai dat chinh BGM, chuyen bo chon nguon thanh dang Tab/Chip trong form Add Track voi 4 tuy chon (File cuc bo, Link truc tiep, Radio, Lofi) luu thang vao thu vien nhac cuc bo.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 11: Sua loi BGM add track khong hien thi vao thu vien

**Date**: 2026-07-04
**Task**: Sua loi BGM add track khong hien thi vao thu vien
**Branch**: `main`

### Summary

Da loai bo bo loc sourceType trong LocalBgmProvider.fetchTracks de load toan bo danh sach track (bao gom ca radio va openlofi) trong database len playlist chinh.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 12: Sua loi khong hien thi nut Sua Xoa trong thu vien BGM

**Date**: 2026-07-04
**Task**: Sua loi khong hien thi nut Sua Xoa trong thu vien BGM
**Branch**: `main`

### Summary

Da loai bo dieu kien track.sourceType == 'local' || track.sourceType == 'direct_url' bao quanh nut Sua va Xoa trong bgm_player_sheet.dart, cho phep Sua va Xoa bat ky track nao trong thu vien.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 13: Triển khai Force Push và Force Pull đồng bộ WebDAV cho từng cuốn sách

**Date**: 2026-07-04
**Task**: Triển khai Force Push và Force Pull đồng bộ WebDAV cho từng cuốn sách
**Branch**: `main`

### Summary

Thêm hàm forcePushBook và forcePullBook vào SyncService; Cập nhật PopupMenuButton của GridView và ListView trong LibraryScreen để hiển thị tùy chọn đồng bộ sách khi WebDAV được bật; Thêm dialog xác nhận có checkbox chọn đồng bộ nhanh tiến trình đọc; Bổ sung các bản dịch tiếng Việt/tiếng Anh tương ứng.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete
