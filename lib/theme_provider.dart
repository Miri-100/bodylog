import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeData get currentTheme =>
      _themeMode == ThemeMode.dark ? darkTheme : lightTheme;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void updateTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F6FB),
    primaryColor: const Color(0xFF764BA2),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF764BA2),
      secondary: Color(0xFF667EEA),
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2D3142)),
      bodyMedium: TextStyle(color: Color(0xFF2D3142)),
      titleLarge: TextStyle(color: Color(0xFF2D3142)),
    ),
    dividerColor: Color(0xFFE6E6E6),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF6C7280)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(const Color(0xFF764BA2)),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: const Color(0xFF9B7BFF),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF9B7BFF),
      secondary: Color(0xFF667EEA),
      surface: Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: const Color(0xFF1F1F1F),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
    ),
    dividerColor: Colors.white12,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: Colors.white70,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(const Color(0xFF9B7BFF)),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

final themeProvider = ThemeProvider();
