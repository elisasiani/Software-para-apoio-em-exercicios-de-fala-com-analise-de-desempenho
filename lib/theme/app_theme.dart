import 'package:flutter/material.dart';

class AppTheme {
  // Nome da família de fontes conforme definido no pubspec.yaml
  static const String fontFamily = 'LeagueSpartan';

  // Definição de cores principais baseadas no projeto
  static const Color primaryColor = Color(0xFFBC4ED8);
  static const Color secondaryColor = Color(0xFF7F00B2);
  static const Color backgroundColor = Color(0xFFFFF0FF);

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: backgroundColor,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      
      // Aplicando a fonte e cores ao TextTheme globalmente
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: secondaryColor,
        displayColor: secondaryColor,
        fontFamily: fontFamily,
      ),

      // Garantindo que componentes específicos também herdem a fonte e estilo
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: secondaryColor),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: secondaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.black38,
        ),
      ),
    );
  }
}
