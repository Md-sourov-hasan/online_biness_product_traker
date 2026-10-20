import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/theme_language_service.dart';
import '../../theme/stockmate_theme.dart';
import '../../utils/sizer.dart';
import '../styles/global_text_style.dart';
import 'stockmate_components.dart';

class ThemeSelectionBottomSheet extends StatelessWidget {
  const ThemeSelectionBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const ThemeSelectionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeLanguageService>();

    return Obx(() {
      final currentMode = themeService.currentThemeMode.value;
      final currentTokens = themeService.t;

      return Container(
        decoration: BoxDecoration(
          color: currentTokens.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: currentTokens.border),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: currentTokens.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            16.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color Themes',
                      style: getTextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: currentTokens.text,
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      'Select your favorite aesthetic palette',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: currentTokens.textSec,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: currentTokens.textSec, size: 20.w),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            16.verticalSpace,
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: StockMateThemeMode.values.length,
                separatorBuilder: (_, _) => 8.verticalSpace,
                itemBuilder: (context, index) {
                  final mode = StockMateThemeMode.values[index];
                  final modeTokens = StockMateThemes.get(mode);
                  final isSelected = currentMode == mode;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeService.setTheme(mode);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? currentTokens.accent.withValues(alpha: 0.12)
                            : currentTokens.surfaceAlt,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isSelected ? currentTokens.accent : currentTokens.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          ThemePreviewTile(
                            theme: modeTokens,
                            activeTheme: currentTokens,
                            variant: PreviewVariant.M,
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  modeTokens.name,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: currentTokens.text,
                                  ),
                                ),
                                2.verticalSpace,
                                Row(
                                  children: [
                                    _colorDot(modeTokens.bg),
                                    4.horizontalSpace,
                                    _colorDot(modeTokens.surface),
                                    4.horizontalSpace,
                                    _colorDot(modeTokens.accent),
                                    4.horizontalSpace,
                                    _colorDot(modeTokens.success),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: currentTokens.accent, size: 20.w),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
      ),
    );
  }
}
