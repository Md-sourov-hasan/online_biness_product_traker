import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stockmate_theme.dart';
import '../utils/constants/colors.dart';

class ThemeLanguageService extends GetxService {
  static ThemeLanguageService get to => Get.find<ThemeLanguageService>();

  /// Active theme state. Default on launch: dark per Spec Section 1.1
  final Rx<StockMateThemeMode> currentThemeMode = StockMateThemeMode.dark.obs;
  final Rx<Locale> currentLocale = const Locale('en', 'US').obs;
  final RxString currentCurrency = 'USD'.obs; // 'USD' or 'BDT'

  // Last non-light theme remembered for dark mode toggle round-tripping
  StockMateThemeMode lastDarkTheme = StockMateThemeMode.dark;

  SharedPreferences? _prefs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load Theme
      final savedThemeKey = _prefs?.getString('sm_theme_key');
      if (savedThemeKey != null) {
        currentThemeMode.value = StockMateThemes.fromKey(savedThemeKey);
      } else {
        // Fallback to legacy index if exists
        final legacyIndex = _prefs?.getInt('sm_theme_mode');
        if (legacyIndex != null && legacyIndex >= 0 && legacyIndex < StockMateThemeMode.values.length) {
          currentThemeMode.value = StockMateThemeMode.values[legacyIndex];
        } else {
          currentThemeMode.value = StockMateThemeMode.dark;
        }
      }

      if (currentThemeMode.value != StockMateThemeMode.light) {
        lastDarkTheme = currentThemeMode.value;
      }

      // Load Locale
      final langCode = _prefs?.getString('sm_language') ?? 'en';
      final countryCode = _prefs?.getString('sm_country') ?? 'US';
      currentLocale.value = Locale(langCode, countryCode);
      Get.updateLocale(currentLocale.value);

      // Load Currency
      currentCurrency.value = _prefs?.getString('sm_currency') ?? 'USD';
    } catch (e) {
      debugPrint('Error loading theme/language preferences: $e');
    }
  }

  /// Active token object `t` per Spec Section 1.1
  ThemeTokens get t => StockMateThemes.get(currentThemeMode.value);

  /// Current theme string key (light, dark, midnight, emerald, amoled, sunset)
  String get themeKey => StockMateThemes.toKey(currentThemeMode.value);

  /// Mode flag: isDark = themeName !== "light". Only light counts as a light theme; the other five are dark.
  bool get isDark => currentThemeMode.value != StockMateThemeMode.light;

  /// Flutter ThemeData derived from the active tokens
  ThemeData get themeData => t.toThemeData();

  // Convenience & backward-compatible getters mapping directly to tokens
  Color get cardColor => t.card;
  Color get backgroundColor => t.bg;
  Color get scaffoldBackgroundColor => t.bg;
  Color get textColor => t.text;
  Color get subtextColor => t.textSec;
  Color get textMutedColor => t.textMuted;
  Color get accentColor => t.accent;
  Color get accentLightColor => t.accentLight;
  Color get successColor => t.success;
  Color get successLightColor => t.successLight;
  Color get warningColor => t.warning;
  Color get warningLightColor => t.warningLight;
  Color get dangerColor => t.danger;
  Color get dangerLightColor => t.dangerLight;
  Color get purpleColor => t.purple;
  Color get purpleLightColor => t.purpleLight;
  Color get inputFillColor => t.input;
  Color get inputBorderColor => t.border;
  Color get shadowColor => t.shadow;
  List<Color> get chartBarColors => t.chartBar;

  /// Set theme directly by enum
  Future<void> setTheme(StockMateThemeMode mode) async {
    currentThemeMode.value = mode;
    if (mode != StockMateThemeMode.light) {
      lastDarkTheme = mode;
    }
    await _prefs?.setString('sm_theme_key', StockMateThemes.toKey(mode));
    await _prefs?.setInt('sm_theme_mode', mode.index);
    Get.changeTheme(themeData);
  }

  /// Set theme by key string
  Future<void> setThemeByName(String key) async {
    await setTheme(StockMateThemes.fromKey(key));
  }

  /// Toggle dark mode switch per Spec Section 7.3:
  /// Turning it off goes to Light; turning it on returns to Dark (or remembered last dark theme)
  Future<void> toggleDarkMode() async {
    if (isDark) {
      await setTheme(StockMateThemeMode.light);
    } else {
      await setTheme(lastDarkTheme == StockMateThemeMode.light ? StockMateThemeMode.dark : lastDarkTheme);
    }
  }

  // Legacy AppThemeMode bridge
  Future<void> setLegacyTheme(AppThemeMode mode) async {
    switch (mode) {
      case AppThemeMode.light:
        await setTheme(StockMateThemeMode.light);
        break;
      case AppThemeMode.dark:
        await setTheme(StockMateThemeMode.dark);
        break;
      case AppThemeMode.midnight:
        await setTheme(StockMateThemeMode.midnight);
        break;
    }
  }

  Future<void> setLanguage(String langCode, String countryCode) async {
    final newLocale = Locale(langCode, countryCode);
    currentLocale.value = newLocale;
    await _prefs?.setString('sm_language', langCode);
    await _prefs?.setString('sm_country', countryCode);
    Get.updateLocale(newLocale);
  }

  Future<void> setCurrency(String symbolOrCode) async {
    currentCurrency.value = symbolOrCode;
    await _prefs?.setString('sm_currency', symbolOrCode);
  }
}
