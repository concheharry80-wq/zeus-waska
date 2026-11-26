import 'package:flutter/material.dart';
import 'package:zeus_waska/models/enums.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF141426);
  static const Color surfaceLight = Color(0xFF1E1E38);
  static const Color electricPurple = Color(0xFF8B3DFF);
  static const Color neonPink = Color(0xFFFF2D95);
  static const Color electricBlue = Color(0xFF00D9FF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color warningAmber = Color(0xFFFFB300);
  static const Color dangerRed = Color(0xFFFF3B5C);
  static const Color textPrimary = Color(0xFFF7F7FF);
  static const Color textSecondary = Color(0xFFA7A9C9);

  static const List<Color> playerPalette = [
    Color(0xFF8B3DFF),
    Color(0xFFFF2D95),
    Color(0xFF00D9FF),
    Color(0xFF00E676),
    Color(0xFFFFB300),
    Color(0xFFFF5E3A),
    Color(0xFF3D7BFF),
    Color(0xFFE040FB),
    Color(0xFF1DE9B6),
    Color(0xFFFF4081),
    Color(0xFF651FFF),
    Color(0xFF00B0FF),
  ];

  static const List<String> playerAvatars = [
    '🎧', '🎮', '🎲', '🔥', '🚀', '⚡', '🎵', '🌟',
    '🦊', '🐱', '🐼', '🦁', '🦄', '👾', '🤖', '💎',
    '🎯', '🪩', '🎤', '🏆', '🍕', '🛸', '🕶️', '🎪',
  ];
}

class AppTheme {
  static Color primaryFor(AppVisualTheme visualTheme) {
    switch (visualTheme) {
      case AppVisualTheme.neonNight:
        return AppColors.electricPurple;
      case AppVisualTheme.cyberCyan:
        return AppColors.electricBlue;
      case AppVisualTheme.magentaPulse:
        return AppColors.neonPink;
    }
  }

  static Color secondaryFor(AppVisualTheme visualTheme) {
    switch (visualTheme) {
      case AppVisualTheme.neonNight:
        return AppColors.neonPink;
      case AppVisualTheme.cyberCyan:
        return AppColors.electricPurple;
      case AppVisualTheme.magentaPulse:
        return AppColors.electricBlue;
    }
  }

  static LinearGradient brandGradient(AppVisualTheme visualTheme) {
    return LinearGradient(
      colors: [primaryFor(visualTheme), secondaryFor(visualTheme)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static ThemeData buildTheme(AppVisualTheme visualTheme) {
    final primary = primaryFor(visualTheme);
    final secondary = secondaryFor(visualTheme);

    final colorScheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      tertiary: AppColors.electricBlue,
      surface: AppColors.surface,
      error: AppColors.dangerRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface.withValues(alpha: 0.85),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: primary.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight.withValues(alpha: 0.75),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.electricBlue, width: 1.8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
