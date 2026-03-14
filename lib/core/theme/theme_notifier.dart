// lib/core/theme/theme_notifier.dart

import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, blueDark, custom }

class ThemeNotifier extends ValueNotifier<ThemeData> {
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

  void setMode(AppThemeMode mode) {
    _currentMode = mode;
    _updateTheme();
  }

  void setCustomColors(Color bg, Color primary) {
    _customBg = bg;
    _customPrimary = primary;
    if (_currentMode == AppThemeMode.custom) {
      _updateTheme();
    }
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
    primaryColor: const Color(0xFFF8BBD0), // Mantenemos el rosa como acento
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
    primaryColor: const Color(0xFFE0E1DD),
    cardColor: const Color(0xFF1B263B),
    dividerColor: const Color(0xFF415A77),
    iconTheme: const IconThemeData(color: Color(0xFFE0E1DD)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE0E1DD)),
      titleTextStyle: TextStyle(
        color: Color(0xFFE0E1DD),
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
