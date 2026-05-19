import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  static final ThemeNotifier instance = ThemeNotifier._();
  ThemeNotifier._();

  String _themeMode = 'System';
  String get themeMode => _themeMode;

  void init(String mode) {
    _themeMode = mode.isEmpty ? 'System' : mode;
  }

  void updateTheme(String mode) {
    final normalized = mode.isEmpty ? 'System' : mode;
    if (_themeMode != normalized) {
      _themeMode = normalized;
      notifyListeners();
    }
  }
}
