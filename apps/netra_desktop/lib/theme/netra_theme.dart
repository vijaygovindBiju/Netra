import 'package:flutter/material.dart';

class NetraColors {
  static const Color background = Color(0xFF0C0E14);
  static const Color surface = Color(0xFF141824);
  static const Color surfaceCard = Color(0xFF1B2030);
  static const Color border = Color(0xFF262D42);
  
  // Accents
  static const Color cyan = Color(0xFF00E5FF);
  static const Color violet = Color(0xFF7C4DFF);
  static const Color green = Color(0xFF00E676);
  static const Color amber = Color(0xFFFFB300);
  static const Color red = Color(0xFFFF3D00);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class NetraTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NetraColors.background,
      primaryColor: NetraColors.cyan,
      colorScheme: const ColorScheme.dark(
        primary: NetraColors.cyan,
        secondary: NetraColors.violet,
        surface: NetraColors.surface,
        error: NetraColors.red,
      ),
      cardTheme: CardThemeData(
        color: NetraColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NetraColors.border, width: 1),
        ),
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }
}
