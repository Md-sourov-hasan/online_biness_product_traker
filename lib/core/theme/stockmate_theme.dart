import 'package:flutter/material.dart';

/// The six exact theme identifiers per StockMate Themes Specification
enum StockMateThemeMode {
  light,
  dark,
  midnight,
  emerald,
  amoled,
  sunset,
}

/// The 23 theme tokens defined across all six themes
class ThemeTokens {
  final String name;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textSec;
  final Color textMuted;
  final Color accent;
  final Color accentLight;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color danger;
  final Color dangerLight;
  final Color purple;
  final Color purpleLight;
  final Color nav;
  final Color card;
  final Color input;
  final Color shadow;
  final List<Color> chartBar;

  const ThemeTokens({
    required this.name,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textSec,
    required this.textMuted,
    required this.accent,
    required this.accentLight,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.danger,
    required this.dangerLight,
    required this.purple,
    required this.purpleLight,
    required this.nav,
    required this.card,
    required this.input,
    required this.shadow,
    required this.chartBar,
  });

  /// Alpha suffix helper matching the prototype's hex suffix behavior:
  /// 11 -> ~6.7% (17/255)
  /// 22 -> ~13.3% (34/255)
  /// 33 -> ~20% (51/255)
  /// 44 -> ~26.7% (68/255)
  /// 99 -> ~60% (153/255)
  /// cc -> ~80% (204/255)
  Color withHexSuffix(Color color, String suffix) {
    int alpha = 255;
    switch (suffix.toLowerCase()) {
      case '11':
        alpha = 17;
        break;
      case '22':
        alpha = 34;
        break;
      case '33':
        alpha = 51;
        break;
      case '44':
        alpha = 68;
        break;
      case '99':
        alpha = 153;
        break;
      case 'cc':
        alpha = 204;
        break;
      default:
        final parsed = int.tryParse(suffix, radix: 16);
        if (parsed != null) alpha = parsed;
    }
    return color.withValues(alpha: alpha / 255.0);
  }

  /// Converts tokens to standard Flutter ThemeData
  ThemeData toThemeData() {
    final isDarkTheme = name != "Light";
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      canvasColor: surface,
      cardColor: card,
      dividerColor: border,
      primaryColor: accent,
      colorScheme: ColorScheme(
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        primary: accent,
        onPrimary: Colors.white,
        secondary: success,
        onSecondary: Colors.white,
        error: danger,
        onError: Colors.white,
        surface: card,
        onSurface: text,
      ),
      fontFamily: 'SF Pro Display',
    );
  }
}

/// The Authoritative Master Color Registry from Section 4 of StockMate Themes Specification
class StockMateThemes {
  static const ThemeTokens light = ThemeTokens(
    name: "Light",
    bg: Color(0xFFF5F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF0F8),
    border: Color(0xFFE2E4EF),
    text: Color(0xFF1A1D2E),
    textSec: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    accent: Color(0xFF4F6EF7),
    accentLight: Color(0xFFEEF1FE),
    success: Color(0xFF10B981),
    successLight: Color(0xFFD1FAE5),
    warning: Color(0xFFF59E0B),
    warningLight: Color(0xFFFEF3C7),
    danger: Color(0xFFEF4444),
    dangerLight: Color(0xFFFEE2E2),
    purple: Color(0xFF8B5CF6),
    purpleLight: Color(0xFFEDE9FE),
    nav: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    input: Color(0xFFEEEFF3),
    shadow: Color(0x14000000), // rgba(0,0,0,0.08)
    chartBar: [
      Color(0xFF4F6EF7),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
    ],
  );

  static const ThemeTokens dark = ThemeTokens(
    name: "Dark",
    bg: Color(0xFF0F1117),
    surface: Color(0xFF1C1F2E),
    surfaceAlt: Color(0xFF252836),
    border: Color(0xFF2E3347),
    text: Color(0xFFF1F3FA),
    textSec: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    accent: Color(0xFF6C8EFF),
    accentLight: Color(0xFF1E2444),
    success: Color(0xFF34D399),
    successLight: Color(0xFF0D2E22),
    warning: Color(0xFFFBBF24),
    warningLight: Color(0xFF2E2208),
    danger: Color(0xFFF87171),
    dangerLight: Color(0xFF2E0F0F),
    purple: Color(0xFFA78BFA),
    purpleLight: Color(0xFF1E1533),
    nav: Color(0xFF1C1F2E),
    card: Color(0xFF1C1F2E),
    input: Color(0xFF252836),
    shadow: Color(0x66000000), // rgba(0,0,0,0.4)
    chartBar: [
      Color(0xFF6C8EFF),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
      Color(0xFFF87171),
      Color(0xFFA78BFA),
    ],
  );

  static const ThemeTokens midnight = ThemeTokens(
    name: "Midnight Blue",
    bg: Color(0xFF060D1F),
    surface: Color(0xFF0D1B35),
    surfaceAlt: Color(0xFF112244),
    border: Color(0xFF1A3366),
    text: Color(0xFFE8F0FF),
    textSec: Color(0xFF8BA4D4),
    textMuted: Color(0xFF4A6490),
    accent: Color(0xFF3B82F6),
    accentLight: Color(0xFF0D1F44),
    success: Color(0xFF22D3EE),
    successLight: Color(0xFF061C22),
    warning: Color(0xFFF59E0B),
    warningLight: Color(0xFF1C1300),
    danger: Color(0xFFF87171),
    dangerLight: Color(0xFF1C0505),
    purple: Color(0xFF818CF8),
    purpleLight: Color(0xFF0F1133),
    nav: Color(0xFF0D1B35),
    card: Color(0xFF0D1B35),
    input: Color(0xFF112244),
    shadow: Color(0x99000000), // rgba(0,0,0,0.6)
    chartBar: [
      Color(0xFF3B82F6),
      Color(0xFF22D3EE),
      Color(0xFFF59E0B),
      Color(0xFFF87171),
      Color(0xFF818CF8),
    ],
  );

  static const ThemeTokens emerald = ThemeTokens(
    name: "Emerald",
    bg: Color(0xFF021A10),
    surface: Color(0xFF05291A),
    surfaceAlt: Color(0xFF083524),
    border: Color(0xFF0E4D35),
    text: Color(0xFFECFDF5),
    textSec: Color(0xFF6EE7B7),
    textMuted: Color(0xFF34D399),
    accent: Color(0xFF10B981),
    accentLight: Color(0xFF042014),
    success: Color(0xFF34D399),
    successLight: Color(0xFF042014),
    warning: Color(0xFFF59E0B),
    warningLight: Color(0xFF1C1300),
    danger: Color(0xFFF87171),
    dangerLight: Color(0xFF1C0505),
    purple: Color(0xFFA78BFA),
    purpleLight: Color(0xFF130F22),
    nav: Color(0xFF05291A),
    card: Color(0xFF05291A),
    input: Color(0xFF083524),
    shadow: Color(0x99000000), // rgba(0,0,0,0.6)
    chartBar: [
      Color(0xFF10B981),
      Color(0xFF34D399),
      Color(0xFF6EE7B7),
      Color(0xFFF59E0B),
      Color(0xFFA78BFA),
    ],
  );

  static const ThemeTokens amoled = ThemeTokens(
    name: "AMOLED Black",
    bg: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceAlt: Color(0xFF111111),
    border: Color(0xFF1A1A1A),
    text: Color(0xFFFFFFFF),
    textSec: Color(0xFFAAAAAA),
    textMuted: Color(0xFF666666),
    accent: Color(0xFFFF4081),
    accentLight: Color(0xFF1A0010),
    success: Color(0xFF00E676),
    successLight: Color(0xFF001A0A),
    warning: Color(0xFFFFD740),
    warningLight: Color(0xFF1A1400),
    danger: Color(0xFFFF5252),
    dangerLight: Color(0xFF1A0000),
    purple: Color(0xFFE040FB),
    purpleLight: Color(0xFF150020),
    nav: Color(0xFF000000),
    card: Color(0xFF0A0A0A),
    input: Color(0xFF111111),
    shadow: Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
    chartBar: [
      Color(0xFFFF4081),
      Color(0xFF00E676),
      Color(0xFFFFD740),
      Color(0xFFFF5252),
      Color(0xFFE040FB),
    ],
  );

  static const ThemeTokens sunset = ThemeTokens(
    name: "Sunset Orange",
    bg: Color(0xFF1A0800),
    surface: Color(0xFF2A1100),
    surfaceAlt: Color(0xFF361800),
    border: Color(0xFF5C2D00),
    text: Color(0xFFFFF7ED),
    textSec: Color(0xFFFDBA74),
    textMuted: Color(0xFFF97316),
    accent: Color(0xFFF97316),
    accentLight: Color(0xFF1A0800),
    success: Color(0xFF34D399),
    successLight: Color(0xFF042014),
    warning: Color(0xFFFBBF24),
    warningLight: Color(0xFF1C1300),
    danger: Color(0xFFF87171),
    dangerLight: Color(0xFF1C0505),
    purple: Color(0xFFC084FC),
    purpleLight: Color(0xFF130F22),
    nav: Color(0xFF2A1100),
    card: Color(0xFF2A1100),
    input: Color(0xFF361800),
    shadow: Color(0x99000000), // rgba(0,0,0,0.6)
    chartBar: [
      Color(0xFFF97316),
      Color(0xFFFB923C),
      Color(0xFFFBBF24),
      Color(0xFF34D399),
      Color(0xFFC084FC),
    ],
  );

  static const Map<StockMateThemeMode, ThemeTokens> registry = {
    StockMateThemeMode.light: light,
    StockMateThemeMode.dark: dark,
    StockMateThemeMode.midnight: midnight,
    StockMateThemeMode.emerald: emerald,
    StockMateThemeMode.amoled: amoled,
    StockMateThemeMode.sunset: sunset,
  };

  static ThemeTokens get(StockMateThemeMode mode) => registry[mode] ?? dark;

  static StockMateThemeMode fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'light':
        return StockMateThemeMode.light;
      case 'dark':
        return StockMateThemeMode.dark;
      case 'midnight':
        return StockMateThemeMode.midnight;
      case 'emerald':
        return StockMateThemeMode.emerald;
      case 'amoled':
        return StockMateThemeMode.amoled;
      case 'sunset':
        return StockMateThemeMode.sunset;
      default:
        return StockMateThemeMode.dark;
    }
  }

  static String toKey(StockMateThemeMode mode) {
    switch (mode) {
      case StockMateThemeMode.light:
        return 'light';
      case StockMateThemeMode.dark:
        return 'dark';
      case StockMateThemeMode.midnight:
        return 'midnight';
      case StockMateThemeMode.emerald:
        return 'emerald';
      case StockMateThemeMode.amoled:
        return 'amoled';
      case StockMateThemeMode.sunset:
        return 'sunset';
    }
  }
}
