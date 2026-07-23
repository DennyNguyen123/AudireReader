import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'database/database_helper.dart';
import 'shortcut_helper.dart';

class GlobalHotkeyManager {
  static Future<void> init() async {
    if (kIsWeb) return;
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    // Khởi tạo hotkey_manager (bắt buộc theo tài liệu của hotkey_manager)
    await hotKeyManager.unregisterAll();
    await updateBossKey();
  }

  static Future<void> updateBossKey() async {
    if (kIsWeb) return;
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    // Hủy đăng ký tất cả các phím tắt toàn cục cũ
    await hotKeyManager.unregisterAll();

    // Lấy phím tắt mới từ Database
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    final bossHotKeyStr = settings.hotkeyBossKey;
    final bossAction = settings.bossKeyAction;

    final HotKey? hotKey = ShortcutHelper.parseToGlobalHotKey(bossHotKeyStr);

    if (hotKey != null) {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (hotKey) async {
          // Xử lý logic Boss Key Toàn Cục
          final isVisible = await windowManager.isVisible();
          final isMinimized = await windowManager.isMinimized();

          if (isVisible && !isMinimized) {
            // Đang hiện trên màn hình -> Ẩn hoặc Thu nhỏ
            if (bossAction == 'hide') {
              await windowManager.hide();
            } else {
              await windowManager.minimize();
            }
          } else {
            // Đang ẩn (hide) hoặc thu nhỏ (minimize) -> Hiện lại ngay lập tức
            await windowManager.show();
            await windowManager.focus();
          }
        },
      );
    }
  }
}
