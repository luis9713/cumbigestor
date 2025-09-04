import 'package:flutter/material.dart';

// Paleta de colores inspirada en diseños modernos con tonos verdes vibrantes
const Color primaryGreen = Color(0xFF4CAF50);       // Verde principal vibrante
const Color lightGreen = Color(0xFF81C784);         // Verde claro para acentos
const Color darkGreen = Color(0xFF2E7D32);          // Verde oscuro para contraste
const Color accentGreen = Color(0xFF66BB6A);        // Verde medio para elementos activos
const Color backgroundLight = Color(0xFFF1F8E9);    // Fondo muy claro con toque verde
const Color backgroundGreen = Color(0xFFE8F5E8);    // Fondo verde muy suave
const Color surfaceWhite = Color(0xFFFFFFFF);       // Blanco puro para superficies
const Color cardGreen = Color(0xFFF8FBF8);          // Fondo de tarjetas con toque verde
const Color textPrimary = Color(0xFF1B5E20);        // Verde oscuro para texto principal
const Color textSecondary = Color(0xFF4A6741);      // Verde gris para texto secundario
const Color textLight = Color(0xFF81C784);          // Verde claro para texto secundario
const Color successGreen = Color(0xFF4CAF50);       // Verde para éxito
const Color warningAmber = Color(0xFFFFB74D);       // Naranja suave para advertencias
const Color errorRed = Color(0xFFE57373);           // Rojo suave para errores
const Color iconGreen = Color(0xFF388E3C);          // Verde para iconos
const Color accentOrange = Color(0xFFFF8A65);       // Naranja como color de acento

ThemeData cumbitaraTheme() {
  return ThemeData(
    // Configuración base
    useMaterial3: true,
    
    // Colores principales
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: backgroundLight,
    
    colorScheme: ColorScheme.light(
      // Colores primarios
      primary: primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: lightGreen.withOpacity(0.2),
      onPrimaryContainer: darkGreen,
      
      // Colores secundarios
      secondary: accentOrange,
      onSecondary: Colors.white,
      secondaryContainer: accentOrange.withOpacity(0.1),
      onSecondaryContainer: Color(0xFFD84315),
      
      // Superficies
      surface: surfaceWhite,
      onSurface: textPrimary,
      surfaceContainerHighest: backgroundGreen,
      
      // Estados
      error: errorRed,
      onError: Colors.white,
      
      // Fondo general
      background: backgroundLight,
      onBackground: textPrimary,
      
      // Colores de contorno
      outline: lightGreen.withOpacity(0.3),
      outlineVariant: backgroundGreen,
    ),

    // Estilo de los AppBars - Más moderno y limpio
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceWhite,
      foregroundColor: textPrimary,
      elevation: 0,
      surfaceTintColor: primaryGreen.withOpacity(0.05),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: primaryGreen),
    ),

    // Estilo de las pestañas - Más elegante
    tabBarTheme: TabBarThemeData(
      labelColor: primaryGreen,
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
          color: primaryGreen,
          width: 3,
        ),
      ),
      indicatorSize: TabBarIndicatorSize.label,
    ),

    // Estilo de los botones elevados - Más atractivo y moderno
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
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
        shadowColor: primaryGreen.withOpacity(0.3),
      ),
    ),

    // Estilo de botones de texto
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
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
      color: cardGreen,
      elevation: 6,
      shadowColor: primaryGreen.withOpacity(0.15),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: lightGreen.withOpacity(0.2), width: 1),
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
        color: primaryGreen,
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
        color: primaryGreen,
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
      fillColor: backgroundGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: lightGreen.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: lightGreen.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: errorRed),
      ),
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Estilo del SnackBar - Más moderno
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkGreen,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: lightGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Estilo del Drawer - Más moderno y alineado con el nuevo diseño
    drawerTheme: DrawerThemeData(
      backgroundColor: surfaceWhite,
      elevation: 12,
      shadowColor: primaryGreen.withOpacity(0.15),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
    ),

    // Estilo de los ListTile
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      iconColor: primaryGreen,
      textColor: textPrimary,
      tileColor: Colors.transparent,
      selectedColor: primaryGreen,
      selectedTileColor: primaryGreen.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Estilo de los FloatingActionButton
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Estilo de los Dividers
    dividerTheme: DividerThemeData(
      color: lightGreen.withOpacity(0.3),
      thickness: 1,
      space: 1,
    ),

    // Estilo de los Chips
    chipTheme: ChipThemeData(
      backgroundColor: backgroundGreen,
      selectedColor: primaryGreen.withOpacity(0.2),
      labelStyle: TextStyle(color: textPrimary),
      secondaryLabelStyle: TextStyle(color: Colors.white),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: lightGreen.withOpacity(0.3)),
      ),
    ),
  );
}