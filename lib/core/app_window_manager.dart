import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'database/database_helper.dart';
import '../views/library/widgets/close_app_dialog.dart';

class AppWindowManager with WindowListener {
  static final AppWindowManager _instance = AppWindowManager._internal();
  factory AppWindowManager() => _instance;
  AppWindowManager._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> init() async {
    if (kIsWeb) return;
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(_instance);
  }

  @override
  void onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    if (!isPreventClose) return;

    try {
      final db = await DatabaseHelper.getInstance();
      final settings = await db.getSettings();
      final closeAction = settings.closeAction;

      if (closeAction == 'tray') {
        await windowManager.hide();
        return;
      }

      if (closeAction == 'exit') {
        exit(0);
      }

      // 'ask' - Hiển thị hộp thoại xác nhận
      final context = navigatorKey.currentContext;
      if (context == null) {
        exit(0);
      }

      final result = await CloseAppDialog.show(context);
      if (result == null) {
        // Người dùng bấm Hủy -> Không làm gì cả
        return;
      }

      if (result.remember) {
        final updatedSettings = settings.copyWith(closeAction: result.action);
        await db.saveSettings(updatedSettings);
      }

      if (result.action == 'tray') {
        await windowManager.hide();
      } else {
        exit(0);
      }
    } catch (e) {
      debugPrint('[AppWindowManager] onWindowClose error: $e');
      exit(0);
    }
  }
}
