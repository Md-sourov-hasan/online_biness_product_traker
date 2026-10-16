import 'package:flutter/material.dart';

enum AppThemeMode {
  light,
  dark,
  midnight,
}

class AppColors {
  // Primary brand palette
  static const Color primary = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // Secondary & Accents
  static const Color secondary = Color(0xFF10B981); // Emerald Green for profit/success
  static const Color accentLight = Color(0xFFEFF6FF); // Soft blue tint
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF06B6D4); // Cyan

  // Light Theme Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundNeutral = Color(0xFFF8FAFC); // Slate 50
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0); // Slate 200

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkInput = Color(0xFF334155); // Slate 700
  static const Color darkInputBorder = Color(0xFF475569);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Midnight Theme Colors (Deep OLED Navy/Black with neon pops)
  static const Color midnightBackground = Color(0xFF060913); // Deepest OLED Void
  static const Color midnightCard = Color(0xFF0E1626); // Midnight Navy Glass
  static const Color midnightInput = Color(0xFF17233D);
  static const Color midnightInputBorder = Color(0xFF1E3A8A);
  static const Color midnightPrimary = Color(0xFF38BDF8); // Neon Sky Blue
  static const Color midnightSecondary = Color(0xFF34D399); // Neon Mint Green
  static const Color midnightTextPrimary = Color(0xFFF1F5F9);
  static const Color midnightTextSecondary = Color(0xFF7DD3FC);

  // Theme-aware helpers
  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundNeutral,
      cardColor: cardBackground,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: error,
        surface: cardBackground,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: secondary,
        error: error,
        surface: darkCard,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData getMidnightTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: midnightPrimary,
      scaffoldBackgroundColor: midnightBackground,
      cardColor: midnightCard,
      colorScheme: const ColorScheme.dark(
        primary: midnightPrimary,
        secondary: midnightSecondary,
        error: error,
        surface: midnightCard,
      ),
      useMaterial3: true,
    );
  }
}
