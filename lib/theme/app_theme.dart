// lib/theme/app_theme.dart
import 'package:flutter/material.dart'; // <-- ¡CORREGIDO CON DOS PUNTOS!

class AppTheme {
  // --- Colores de la Filà ---
  static const Color primaryRed = Color(
    0xFF9B0000,
  ); // Rojo principal (Abencerraje)
  static const Color secondaryGold = Color(0xFFFFD700); // Dorado (Oro)
  static const Color darkBackground = Color(0xFF121212); // Fondo oscuro
  static const Color lightBackground = Color(0xFF1E1E1E); // Fondo de tarjetas
  static const Color textColor = Color(0xFFE0E0E0); // Texto principal

  // --- Definición del Tema Oscuro ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryRed,

    colorScheme: const ColorScheme.dark(
      primary: primaryRed, // Color principal (botones, appbar)
      secondary: secondaryGold, // Color secundario (acentos, botones flotantes)
      surface: lightBackground, // Color de fondo general
      error: Colors.redAccent, // Color para errores
      onPrimary:
          Colors.white, // Texto sobre color primario (ej. en botones rojos)
      onSecondary:
          Colors.black, // Texto sobre color secundario (ej. en botones dorados)
      onSurface: textColor, // Texto sobre el fondo
    ),

    // --- Estilo del AppBar ---
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: secondaryGold, // Título en Dorado
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(
        color: textColor,
      ), // Iconos (ej. flecha de atrás)
    ),

    // --- Estilo del Bottom Navigation Bar ---
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkBackground,
      selectedItemColor: primaryRed, // Icono seleccionado (Rojo)
      unselectedItemColor: Colors.grey, // Icono no seleccionado
      type: BottomNavigationBarType.fixed, // Para que siempre se vean los 5
      elevation: 8,
    ),

    // --- Estilo de los Botones Flotantes (FAB) ---
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryGold, // Dorado
      foregroundColor: Colors.black, // Icono en negro
    ),

    // --- Estilo de los Botones Elevados ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed, // Fondo Rojo
        foregroundColor: Colors.white, // Texto Blanco
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // --- Estilo de los Campos de Texto ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: primaryRed,
        ), // Borde rojo al enfocar
      ),
      labelStyle: const TextStyle(color: Colors.grey),
    ),

    // --- Estilo de las Tarjetas (Cards) ---
    cardTheme: CardThemeData(
      elevation: 2,
      color: lightBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // --- Estilo del Texto ---
    textTheme: const TextTheme(
      // (Puedes personalizar más estilos aquí si quieres)
      bodyMedium: TextStyle(color: textColor),
      headlineSmall: TextStyle(color: textColor),
    ),
  );
}
