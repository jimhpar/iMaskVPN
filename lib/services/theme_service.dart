import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'imask_theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.light) {
        await prefs.setString(_themeKey, 'light');
      } else if (mode == ThemeMode.dark) {
        await prefs.setString(_themeKey, 'dark');
      } else {
        await prefs.setString(_themeKey, 'system');
      }
    } catch (_) {}
  }

  // --- HIGH CONTRAST DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050811),
      primaryColor: const Color(0xFF00F2FE),
      cardColor: const Color(0xFF0D1527),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00F2FE),
        onPrimary: Color(0xFF000000),
        secondary: Color(0xFF38BDF8),
        surface: Color(0xFF0D1527),
        onSurface: Color(0xFFFFFFFF),
        outline: Color(0xFF1E293B),
        surfaceContainerHighest: Color(0xFF152238),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF050811),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  // --- HIGH CONTRAST PURE BLACK & WHITE LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Pure White
      primaryColor: const Color(0xFF000000), // Pure Black
      cardColor: const Color(0xFFFFFFFF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF1E293B),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000), // Pure Black Text
        outline: Color(0xFF000000),
        surfaceContainerHighest: Color(0xFFF1F5F9),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF000000)),
        titleTextStyle: TextStyle(
          color: Color(0xFF000000),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
