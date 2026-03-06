// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. Definimos nuestra paleta de colores pastel
  static const Color pastelYellow = Color(
    0xFFFFF59D,
  ); // Amarillo suave (Principal)
  static const Color softPink = Color(0xFFF8BBD0); // Rosa suave (Acentos)
  static const Color creamBackground = Color(0xFFFFFDF7); // Blanco cálido/Crema
  static const Color softGreen = Color(0xFFC8E6C9); // Verde suave (Decorativo)
  static const Color darkText = Color(
    0xFF5D4037,
  ); // Café suave para el texto (amigable para leer)

  // 2. Creamos el Tema Global
  static ThemeData get lightTheme {
    return ThemeData(
      // Fondo general de la app
      scaffoldBackgroundColor: creamBackground,

      // Tipografía redondeada y amigable (Quicksand es perfecta para esto)
      textTheme: GoogleFonts.quicksandTextTheme().apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),

      // Paleta de colores principal
      colorScheme: ColorScheme.fromSeed(
        seedColor: pastelYellow,
        primary: pastelYellow,
        secondary: softPink,
        background: creamBackground,
      ),

      // Diseño global de las Cajas de Texto (Inputs)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            Colors.white, // Fondo blanco puro para resaltar sobre el crema
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
        // Bordes súper redondeados sin focus
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        // Bordes suaves y verdes cuando haces clic para escribir
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: softGreen, width: 2),
        ),
        // Color del texto de ayuda (placeholder)
        labelStyle: const TextStyle(color: Color(0xFF8D6E63)),
      ),

      // Diseño global de los Botones Principales
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pastelYellow,
          foregroundColor: darkText, // Color del texto dentro del botón
          elevation: 2, // Sombra súper suave
          shadowColor: softPink.withOpacity(0.5), // Sombra con un toque rosado
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Botones muy redondeados
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Quicksand',
          ),
        ),
      ),
    );
  }
}
