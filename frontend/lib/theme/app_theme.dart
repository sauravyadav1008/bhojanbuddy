// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.yellow[50],
    primaryColor: Colors.green[400],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.pink, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.pinkAccent, fontSize: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink[300],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.green[300],
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
