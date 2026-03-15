// lib/core/theme/theme_notifier.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, blueDark, custom }

class ThemeNotifier extends ValueNotifier<ThemeData> {
  static const String _modeKey = 'theme_mode';
  static const String _customBgKey = 'theme_custom_bg';
  static const String _customPrimaryKey = 'theme_custom_primary';

  // Patrón Singleton para acceder a él desde cualquier pantalla mágicamente
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;
  ThemeNotifier._internal() : super(_lightTheme);

  AppThemeMode _currentMode = AppThemeMode.light;
  AppThemeMode get currentMode => _currentMode;

  // Colores por defecto para el modo Custom
  Color _customBg = const Color(0xFF2C2C2C);
  Color _customPrimary = const Color(0xFFF8BBD0);

  Color get customBg => _customBg;
  Color get customPrimary => _customPrimary;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString(_modeKey);
    if (savedMode != null) {
      _currentMode = AppThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => AppThemeMode.light,
      );
    }

    final savedCustomBg = prefs.getInt(_customBgKey);
    if (savedCustomBg != null) {
      _customBg = Color(savedCustomBg);
    }

    final savedCustomPrimary = prefs.getInt(_customPrimaryKey);
    if (savedCustomPrimary != null) {
      _customPrimary = Color(savedCustomPrimary);
    }

    _updateTheme();
  }

  void setMode(AppThemeMode mode) {
    _currentMode = mode;
    _updateTheme();
    _persistTheme();
  }

  void setCustomColors(Color bg, Color primary) {
    _customBg = bg;
    _customPrimary = primary;
    _persistTheme();
    if (_currentMode == AppThemeMode.custom) {
      _updateTheme();
    }
  }

  Future<void> _persistTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, _currentMode.name);
    await prefs.setInt(_customBgKey, _customBg.toARGB32());
    await prefs.setInt(_customPrimaryKey, _customPrimary.toARGB32());
  }

  void _updateTheme() {
    switch (_currentMode) {
      case AppThemeMode.dark:
        value = _darkTheme;
        break;
      case AppThemeMode.blueDark:
        value = _blueDarkTheme;
        break;
      case AppThemeMode.custom:
        value = _buildCustomTheme(_customBg, _customPrimary);
        break;
      case AppThemeMode.light:
      default:
        value = _lightTheme;
        break;
    }
  }

  // ================= TEMAS PREDEFINIDOS =================

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFDF7), // Tu crema pastel
    primaryColor: const Color(0xFF5D4037),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFFFF59D),
    iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF5D4037)),
      titleTextStyle: TextStyle(
        color: Color(0xFF5D4037),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF5D4037)),
      bodyMedium: TextStyle(color: Colors.grey),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // Oscuro puro
    primaryColor: const Color.fromARGB(
      255,
      236,
      41,
      109,
    ), // Mantenemos el rosa como acento
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: Colors.grey.shade800,
    iconTheme: const IconThemeData(color: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );

  static final ThemeData _blueDarkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1B2A), // Azul noche
    primaryColor: const Color.fromARGB(255, 137, 138, 137),
    cardColor: const Color(0xFF1B263B),
    dividerColor: const Color(0xFF415A77),
    iconTheme: const IconThemeData(color: Color(0xFFE0E1DD)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE0E1DD)),
      titleTextStyle: TextStyle(
        color: Color.fromARGB(255, 97, 97, 97),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE0E1DD)),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );

  static ThemeData _buildCustomTheme(Color bg, Color primary) {
    final isDark = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      cardColor: isDark ? bg.withValues(alpha: 0.8) : Colors.white,
      dividerColor: primary.withValues(alpha: 0.3),
      iconTheme: IconThemeData(color: primary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor.withValues(alpha: 0.7)),
      ),
    );
  }
}
