import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  Locale locale = const Locale('en', ''); // Default to English initially

  void updateTheme(bool isDarkMode) {
    themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void updateLanguage(String newLanguage) {
    if (newLanguage == 'Malay') {
      locale = const Locale('ms', '');
    } else {
      locale = const Locale('en', '');
    }
    notifyListeners();
  }
}

// Global instance to quickly access the provider
final themeProvider = ThemeProvider();
