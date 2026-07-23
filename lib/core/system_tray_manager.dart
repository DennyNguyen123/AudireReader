import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class AppTrayManager with TrayListener {
  // Thiết kế theo chuẩn Singleton
  static final AppTrayManager _instance = AppTrayManager._internal();
  factory AppTrayManager() => _instance;
  AppTrayManager._internal();

  static Future<void> init() async {
    if (kIsWeb) return;
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    // Đặt biểu tượng ở khay hệ thống
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/images/app_icon.ico'
          : 'assets/images/logo.png',
    );

    // Khắc phục triệt để lỗi hiển thị rác unicode (ToolTip bắt buộc phải set)
    await trayManager.setToolTip('Audire Reader');

    // Tạo Context Menu (Menu chuột phải)
    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_app', label: 'Show Audire Reader'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit'),
      ],
    );
    await trayManager.setContextMenu(menu);
    trayManager.addListener(_instance);
  }

  @override
  void onTrayIconMouseDown() async {
    // Nhấp chuột trái vào icon -> Bật lại ứng dụng
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    // Nhấp chuột phải -> Bật context menu
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_app') {
      await windowManager.show();
      await windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      exit(0);
    }
  }
}
