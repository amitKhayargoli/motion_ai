import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData defaultTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: "sf_pro",
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}
