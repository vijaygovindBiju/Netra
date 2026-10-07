import 'package:flutter/material.dart';

class NetraPalette {
  final Color background;
  final Color surface;
  final Color surfaceCard;
  final Color surfaceCardHover;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color secondary;
  final Color green;
  final Color amber;
  final Color red;
  final bool isDark;

  const NetraPalette({
    required this.background,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceCardHover,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.secondary,
    required this.green,
    required this.amber,
    required this.red,
    required this.isDark,
  });

  static const dark = NetraPalette(
    background: Color(0xFF0C0E14),
    surface: Color(0xFF141824),
    surfaceCard: Color(0xFF1A2030),
    surfaceCardHover: Color(0xFF222B40),
    border: Color(0xFF262E44),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFF7C4DFF),
    green: Color(0xFF00E676),
    amber: Color(0xFFFFB300),
    red: Color(0xFFFF3D00),
    isDark: true,
  );

  static const light = NetraPalette(
    background: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceCardHover: Color(0xFFE2E8F0),
    border: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    primary: Color(0xFF0284C7),
    secondary: Color(0xFF6366F1),
    green: Color(0xFF059669),
    amber: Color(0xFFD97706),
    red: Color(0xFFDC2626),
    isDark: false,
  );
}

class NetraColors {
  // Static color constants for backward compatibility
  static const Color background = Color(0xFF0C0E14);
  static const Color surface = Color(0xFF141824);
  static const Color surfaceCard = Color(0xFF1A2030);
  static const Color border = Color(0xFF262E44);
  
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

  // Theme-aware palette accessor
  static NetraPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? NetraPalette.dark : NetraPalette.light;
  }
}

class NetraTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NetraPalette.dark.background,
      primaryColor: NetraPalette.dark.primary,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E5FF),
        secondary: Color(0xFF7C4DFF),
        surface: Color(0xFF141824),
        error: Color(0xFFFF3D00),
      ),
      cardTheme: CardThemeData(
        color: NetraPalette.dark.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF262E44), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF262E44),
        thickness: 1,
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: NetraPalette.light.background,
      primaryColor: NetraPalette.light.primary,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0284C7),
        secondary: Color(0xFF6366F1),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFDC2626),
      ),
      cardTheme: CardThemeData(
        color: NetraPalette.light.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFCBD5E1),
        thickness: 1,
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }
}
