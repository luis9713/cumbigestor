import 'package:flutter/material.dart';

// Colores basados en la bandera de Cumbitara
const Color cumbitaraYellow = Color(0xFFFFC107); // Amarillo
const Color cumbitaraGreen = Color(0xFF2E7D32); // Verde
const Color cumbitaraWhite = Color(0xFFFFFFFF); // Blanco

ThemeData cumbitaraTheme() {
  return ThemeData(
    // Colores principales
    primaryColor: cumbitaraGreen, // Verde como color principal
    scaffoldBackgroundColor: cumbitaraWhite, // Fondo blanco
    colorScheme: ColorScheme.light(
      primary: cumbitaraGreen,
      secondary: cumbitaraYellow, // Amarillo como color secundario
      surface: cumbitaraWhite,
      onPrimary: cumbitaraWhite, // Texto blanco sobre el color primario
      onSecondary: cumbitaraGreen, // Texto verde sobre el color secundario
      onSurface: Colors.black, // Texto negro sobre superficies blancas
    ),

    // Estilo de los AppBars
    appBarTheme: const AppBarTheme(
      backgroundColor: cumbitaraGreen, // AppBar en verde
      foregroundColor: cumbitaraWhite, // Iconos y texto del AppBar en blanco
      elevation: 4,
    ),

    // Estilo de las pestañas (TabBar)
    tabBarTheme: TabBarThemeData(
      labelColor: cumbitaraYellow, // Texto de la pestaña seleccionada en amarillo
      unselectedLabelColor: cumbitaraWhite.withOpacity(0.7), // Texto de pestañas no seleccionadas en blanco opaco
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: cumbitaraYellow, width: 2), // Indicador en amarillo
      ),
    ),

    // Estilo de los botones elevados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cumbitaraYellow, // Fondo de los botones en amarillo
        foregroundColor: cumbitaraGreen, // Texto e iconos de los botones en verde
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Estilo de las tarjetas
    cardTheme: CardThemeData(
      color: cumbitaraWhite, // Fondo de las tarjetas en blanco
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: cumbitaraGreen, width: 1), // Borde verde
      ),
    ),

    // Estilo del texto
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: cumbitaraGreen, // Títulos en verde
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.black, // Texto del cuerpo en negro
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        color: Colors.black87, // Texto secundario en negro claro
      ),
    ),

    // Estilo de los campos de texto
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: cumbitaraGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: cumbitaraYellow, width: 2),
      ),
      labelStyle: const TextStyle(color: cumbitaraGreen),
      hintStyle: const TextStyle(color: Colors.black54),
    ),

    // Estilo del SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cumbitaraGreen,
      contentTextStyle: const TextStyle(color: cumbitaraWhite),
      actionTextColor: cumbitaraYellow,
    ),

    // Estilo del Drawer
    drawerTheme: const DrawerThemeData(
      backgroundColor: cumbitaraWhite,
    ),
  );
}