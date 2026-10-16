import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants/colors.dart';

class ThemeLanguageService extends GetxService {
  static ThemeLanguageService get to => Get.find<ThemeLanguageService>();

  final Rx<AppThemeMode> currentThemeMode = AppThemeMode.light.obs;
  final Rx<Locale> currentLocale = const Locale('en', 'US').obs;
  final RxString currentCurrency = '৳'.obs;

  SharedPreferences? _prefs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final themeIndex = _prefs?.getInt('sm_theme_mode') ?? 0;
      if (themeIndex >= 0 && themeIndex < AppThemeMode.values.length) {
        currentThemeMode.value = AppThemeMode.values[themeIndex];
      }

      final langCode = _prefs?.getString('sm_language') ?? 'en';
      final countryCode = _prefs?.getString('sm_country') ?? 'US';
      currentLocale.value = Locale(langCode, countryCode);
      Get.updateLocale(currentLocale.value);

      currentCurrency.value = _prefs?.getString('sm_currency') ?? '৳';
    } catch (e) {
      debugPrint('Error loading theme/language preferences: $e');
    }
  }

  ThemeData get themeData {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return AppColors.getLightTheme();
      case AppThemeMode.dark:
        return AppColors.getDarkTheme();
      case AppThemeMode.midnight:
        return AppColors.getMidnightTheme();
    }
  }

  bool get isDark => currentThemeMode.value == AppThemeMode.dark || currentThemeMode.value == AppThemeMode.midnight;
  bool get isMidnight => currentThemeMode.value == AppThemeMode.midnight;

  Color get cardColor {
    if (currentThemeMode.value == AppThemeMode.midnight) return AppColors.midnightCard;
    if (currentThemeMode.value == AppThemeMode.dark) return AppColors.darkCard;
    return AppColors.cardBackground;
  }

  Color get backgroundColor {
    if (currentThemeMode.value == AppThemeMode.midnight) return AppColors.midnightBackground;
    if (currentThemeMode.value == AppThemeMode.dark) return AppColors.darkBackground;
    return AppColors.backgroundNeutral;
  }

  Color get textColor {
    if (currentThemeMode.value == AppThemeMode.midnight) return AppColors.midnightTextPrimary;
    if (currentThemeMode.value == AppThemeMode.dark) return AppColors.darkTextPrimary;
    return AppColors.textPrimary;
  }

  Color get subtextColor {
    if (currentThemeMode.value == AppThemeMode.midnight) return AppColors.midnightTextSecondary;
    if (currentThemeMode.value == AppThemeMode.dark) return AppColors.darkTextSecondary;
    return AppColors.textSecondary;
  }

  Color get inputFillColor {
    if (currentThemeMode.value == AppThemeMode.midnight) return AppColors.midnightInput;
    if (currentThemeMode.value == AppThemeMode.dark) return AppColors.darkInput;
    return AppColors.inputBackground;
  }

  Color get inputBorderColor {
    if (currentThemeMode.value == AppThemeMode.midnight) return AppColors.midnightInputBorder;
    if (currentThemeMode.value == AppThemeMode.dark) return AppColors.darkInputBorder;
    return AppColors.inputBorder;
  }

  Future<void> setTheme(AppThemeMode mode) async {
    currentThemeMode.value = mode;
    await _prefs?.setInt('sm_theme_mode', mode.index);
    Get.changeTheme(themeData);
  }

  Future<void> setLanguage(String langCode, String countryCode) async {
    final newLocale = Locale(langCode, countryCode);
    currentLocale.value = newLocale;
    await _prefs?.setString('sm_language', langCode);
    await _prefs?.setString('sm_country', countryCode);
    Get.updateLocale(newLocale);
  }

  Future<void> setCurrency(String symbol) async {
    currentCurrency.value = symbol;
    await _prefs?.setString('sm_currency', symbol);
  }
}
