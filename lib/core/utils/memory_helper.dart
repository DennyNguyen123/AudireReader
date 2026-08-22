import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class MemoryHelper {
  /// Lên lịch dọn dẹp RAM thừa sau khi ứng dụng khởi động và giao diện đã ổn định.
  static void schedulePostStartupCleanup({
    Duration delay = const Duration(seconds: 3),
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(delay, () {
        trimMemory();
      });
    });
  }

  /// Lắng nghe vòng đời ứng dụng để tự động dọn RAM khi người dùng thu nhỏ / ẩn app / vào background.
  static AppLifecycleListener? initLifecycleListener() {
    return AppLifecycleListener(
      onHide: () => trimMemory(),
      onPause: () => trimMemory(),
    );
  }

  /// Thu hồi bộ đệm hình ảnh mồ côi, kích hoạt Flutter Engine / Dart VM dọn dẹp
  /// và ép Hệ điều hành (Windows/Linux/Android) trả RAM vật lý về cho OS (giảm số trên Task Manager).
  static void trimMemory() {
    try {
      // 1. Dọn cache hình ảnh không còn gắn trên cây Widget đang hiển thị
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 2. Gửi tín hiệu Memory Pressure để Flutter Engine & Dart VM dọn rác và cache thừa
      WidgetsBinding.instance.handleMemoryPressure();

      // 3. Ép OS kernel thu hồi Physical Working Set / trả heap về hệ thống
      _trimOsWorkingSet();
    } catch (_) {
      // Bỏ qua nếu có lỗi
    }
  }

  static void _trimOsWorkingSet() {
    if (kIsWeb) return;

    if (Platform.isWindows) {
      try {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final getCurrentProcess = kernel32.lookupFunction<
          IntPtr Function(),
          int Function()
        >('GetCurrentProcess');
        final setProcessWorkingSetSize = kernel32.lookupFunction<
          Int32 Function(IntPtr, IntPtr, IntPtr),
          int Function(int, int, int)
        >('SetProcessWorkingSetSize');

        final processHandle = getCurrentProcess();
        // -1, -1 báo Windows kernel giải phóng các trang nhớ không dùng trong Working Set
        setProcessWorkingSetSize(processHandle, -1, -1);
      } catch (_) {}
    } else if (Platform.isLinux || Platform.isAndroid) {
      try {
        final libc = DynamicLibrary.process();
        final mallocTrim = libc.lookupFunction<
          Int32 Function(IntPtr),
          int Function(int)
        >('malloc_trim');
        mallocTrim(0);
      } catch (_) {}
    }
  }
}

/// NavigatorObserver tự động kích hoạt dọn dẹp RAM khi người dùng đóng một màn hình, Dialog hoặc Sheet.
/// Áp dụng cơ chế Debounce thông minh để tránh giật lag khi chuyển cảnh liên tục.
class MemoryNavObserver extends NavigatorObserver {
  Timer? _debounceTimer;
  final Duration debounceDuration;

  MemoryNavObserver({
    this.debounceDuration = const Duration(seconds: 2),
  });

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    // Hủy timer cũ nếu có tương tác điều hướng mới
    _debounceTimer?.cancel();

    // Đợi 2 giây sau khi hiệu ứng đóng hoàn tất và UI đã ổn định
    _debounceTimer = Timer(debounceDuration, () {
      MemoryHelper.trimMemory();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // Hủy dọn dẹp nếu người dùng vừa mở thêm màn hình mới
    _debounceTimer?.cancel();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _debounceTimer?.cancel();
  }
}
