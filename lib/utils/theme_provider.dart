import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'en';
  String _displayName = 'Doctor';

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String get displayName => _displayName;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void setDisplayName(String name) {
    _displayName = name.trim();
    notifyListeners();
  }
}

/// Global instance used across the app for localization helper `t()`
final ThemeProvider globalThemeProvider = ThemeProvider();

String t(String enText, String arText) {
  return globalThemeProvider.language == 'ar' ? arText : enText;
}

Color colorWithOpacity(Color color, double opacity) => color.withOpacity(opacity);
