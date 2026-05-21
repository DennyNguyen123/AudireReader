import 'package:flutter/material.dart';

class LocaleNotifier extends ChangeNotifier {
  static final LocaleNotifier instance = LocaleNotifier._();
  LocaleNotifier._();

  String _localeCode = 'en';
  String get localeCode => _localeCode;

  Locale get locale => Locale(_localeCode);

  void init(String code) {
    _localeCode = code.isEmpty ? 'en' : code;
  }

  void updateLocale(String code) {
    final normalized = code.isEmpty ? 'en' : code;
    if (_localeCode != normalized) {
      _localeCode = normalized;
      notifyListeners();
    }
  }
}
