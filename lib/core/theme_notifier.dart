import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  static final ThemeNotifier instance = ThemeNotifier._();
  ThemeNotifier._();

  String _themeMode = 'System';
  String get themeMode => _themeMode;

  String? _primaryColorHex;
  String? get primaryColorHex => _primaryColorHex;

  void init(String mode, {String? primaryColorHex}) {
    _themeMode = mode.isEmpty ? 'System' : mode;
    _primaryColorHex = primaryColorHex;
  }

  void updateTheme(String mode, {String? primaryColorHex}) {
    final normalized = mode.isEmpty ? 'System' : mode;
    bool changed = false;
    
    if (_themeMode != normalized) {
      _themeMode = normalized;
      changed = true;
    }
    
    if (_primaryColorHex != primaryColorHex) {
      _primaryColorHex = primaryColorHex;
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }
}
