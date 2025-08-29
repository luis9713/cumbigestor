import 'package:flutter/material.dart';

// Paleta de colores moderna y elegante inspirada en Material Design 3
const Color primaryBlue = Color(0xFF1976D2);        // Azul primario elegante
const Color lightBlue = Color(0xFF42A5F5);          // Azul claro para acentos
const Color darkBlue = Color(0xFF0D47A1);           // Azul oscuro para contraste
const Color accentOrange = Color(0xFFFF8A65);       // Naranja suave para acentos
const Color backgroundLight = Color(0xFFF8F9FA);    // Fondo muy claro y limpio
const Color surfaceWhite = Color(0xFFFFFFFF);       // Blanco puro para superficies
const Color textPrimary = Color(0xFF212121);        // Gris oscuro para texto principal
const Color textSecondary = Color(0xFF757575);      // Gris medio para texto secundario
const Color successGreen = Color(0xFF4CAF50);       // Verde para éxito
const Color warningAmber = Color(0xFFFFC107);       // Ámbar para advertencias
const Color errorRed = Color(0xFFF44336);           // Rojo para errores

ThemeData cumbitaraTheme() {
  return ThemeData(
    // Configuración base
    useMaterial3: true,
    
    // Colores principales
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundLight,
    
    colorScheme: ColorScheme.light(
      // Colores primarios
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: lightBlue.withOpacity(0.1),
      onPrimaryContainer: darkBlue,
      
      // Colores secundarios
      secondary: accentOrange,
      onSecondary: Colors.white,
      secondaryContainer: accentOrange.withOpacity(0.1),
      onSecondaryContainer: Color(0xFFD84315),
      
      // Superficies
      surface: surfaceWhite,
      onSurface: textPrimary,
      surfaceContainerHighest: backgroundLight,
      
      // Estados
      error: errorRed,
      onError: Colors.white,
      
      // Fondo general
      background: backgroundLight,
      onBackground: textPrimary,
      
      // Colores de contorno
      outline: Color(0xFFE0E0E0),
      outlineVariant: Color(0xFFF5F5F5),
    ),

    // Estilo de los AppBars - Más moderno y limpio
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceWhite,
      foregroundColor: textPrimary,
      elevation: 0,
      surfaceTintColor: primaryBlue.withOpacity(0.05),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: primaryBlue),
    ),

    // Estilo de las pestañas - Más elegante
    tabBarTheme: TabBarThemeData(
      labelColor: primaryBlue,
      unselectedLabelColor: textSecondary,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: primaryBlue,
          width: 3,
        ),
      ),
      indicatorSize: TabBarIndicatorSize.label,
    ),

    // Estilo de los botones elevados - Más atractivo y moderno
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor: primaryBlue.withOpacity(0.3),
      ),
    ),

    // Estilo de botones de texto
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Estilo de las tarjetas - Diseño más moderno
    cardTheme: CardThemeData(
      color: surfaceWhite,
      elevation: 4,
      shadowColor: primaryBlue.withOpacity(0.1),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    ),

    // Estilo del texto - Tipografía mejorada
    textTheme: TextTheme(
      // Encabezados principales
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryBlue,
      ),
      
      // Títulos
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      
      // Cuerpo del texto
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.3,
      ),
      
      // Etiquetas
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
    ),

    // Estilo de los campos de texto - Más elegante
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorRed),
      ),
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Estilo del SnackBar - Más moderno
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: accentOrange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Estilo del Drawer - Más limpio
    drawerTheme: DrawerThemeData(
      backgroundColor: surfaceWhite,
      elevation: 8,
      shadowColor: primaryBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
    ),

    // Estilo de los ListTile
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      iconColor: primaryBlue,
      textColor: textPrimary,
      tileColor: Colors.transparent,
      selectedColor: primaryBlue,
      selectedTileColor: primaryBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Estilo de los FloatingActionButton
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Estilo de los Dividers
    dividerTheme: DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),

    // Estilo de los Chips
    chipTheme: ChipThemeData(
      backgroundColor: backgroundLight,
      selectedColor: primaryBlue.withOpacity(0.2),
      labelStyle: TextStyle(color: textPrimary),
      secondaryLabelStyle: TextStyle(color: Colors.white),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Color(0xFFE0E0E0)),
      ),
    ),
  );
}