import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0B2A5B);
  static const Color pageBackground = Color(0xFFF6F7FB);
  static const Color heading = Color(0xFF0B1B2B);
  static const Color subtitle = Color(0xFF9AA6B2);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: pageBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: primary,
        surface: Colors.white,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: heading,
        ),
        bodyMedium: const TextStyle(fontSize: 16, color: subtitle),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
