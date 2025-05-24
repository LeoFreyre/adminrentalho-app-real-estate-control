import 'package:flutter/material.dart';

// Clase que define el tema de la aplicación
class AppTheme {
  // Definición de colores y fuente principales
  static const Color primaryColor = Color(0xFF3498DB);
  static const Color secondaryColor = Color(0xFF45526E);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF45526E);
  static const String fontFamily = 'Sailec';

  // Configuración del tema claro de la aplicación
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: false, // Opcional, pero ayuda a evitar cambios inesperados
    primaryColor: primaryColor,
    hintColor: secondaryColor,
    scaffoldBackgroundColor: backgroundColor,

    // Esquema de colores principal
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      // ignore: deprecated_member_use
      background: backgroundColor,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      // ignore: deprecated_member_use
      onBackground: textColor,
      onSurface: textColor,
      error: Colors.red,
      onError: Colors.white,
    ),

    // Configuración del tema de la barra de aplicación
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Configuración de los estilos de texto
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: textColor,
        fontFamily: fontFamily,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textColor,
        fontFamily: fontFamily,
        fontSize: 14,
      ),
      titleLarge: TextStyle(
        color: textColor,
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Configuración del botón flotante
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),

    // Configuración de la barra de navegación inferior
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),

    // Configuración de los botones elevados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // Configuración del tema de iconos
    iconTheme: IconThemeData(color: primaryColor),

    // Configuración del tema de tarjetas
    cardTheme: CardTheme(
      color: backgroundColor,
      // ignore: deprecated_member_use
      shadowColor: Colors.grey.withOpacity(0.2),
      elevation: 4,
    ),

    // Configuración del tema de elementos de lista
    listTileTheme: ListTileThemeData(
      tileColor: Colors.grey[100],
      textColor: textColor,
      iconColor: primaryColor,
    ),

    // Configuración del tema de divisores
    dividerTheme: DividerThemeData(
      color: Colors.grey[300],
      thickness: 1,
      indent: 16,
      endIndent: 16,
    ),

    // Configuración de botones con bordes
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
      ),
    ),

    // Configuración de botones de texto
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryColor),
    ),

    // Configuración del tema de campos de entrada
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor),
      ),
      hintStyle: TextStyle(
        color: secondaryColor,
        fontFamily: fontFamily,
      ),
    ),

    // Configuración de la barra de desplazamiento
    scrollbarTheme: ScrollbarThemeData(
      // ignore: deprecated_member_use
      thumbColor: WidgetStateProperty.all(primaryColor.withOpacity(0.8)),
    ),

    // Configuración del tema de selección de texto
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primaryColor,
      // ignore: deprecated_member_use
      selectionColor: primaryColor.withOpacity(0.5),
    ),

    // Configuración del menú emergente
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      textStyle: TextStyle(color: textColor, fontFamily: fontFamily),
    ),

    // Configuración de los tooltips
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: Colors.white),
    ),
  );
}
