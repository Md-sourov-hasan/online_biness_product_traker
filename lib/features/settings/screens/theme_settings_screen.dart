import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../core/common/widgets/stockmate_components.dart';
import '../../../core/utils/constants/colors.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();

    return Obx(() {
      final t = themeService.t;
      final currentMode = themeService.currentThemeMode.value;
      final isDark = themeService.isDark;

      return Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Section 7.2)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/settings');
                          }
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: t.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '←',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: t.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Appearance & Theme',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: t.text,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Card 1 – Dark Mode Toggle (Section 7.2 & 7.3)
                StockMateCard(
                  t: t,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🌙 Dark Mode',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: t.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isDark ? 'Dark mode is ON' : 'Dark mode is OFF',
                            style: TextStyle(
                              fontSize: 12,
                              color: t.textSec,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Custom Switch Knob per Section 7.3
                      GestureDetector(
                        onTap: () => themeService.toggleDarkMode(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 52,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isDark ? t.accent : t.border,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                top: 3,
                                left: isDark ? 25 : 3,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.modalOverlay, // rgba(0,0,0,0.35)
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    isDark ? '🌙' : '☀️',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Card 2 – Choose Theme (Section 7.2)
                StockMateCard(
                  t: t,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Theme',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: StockMateThemeMode.values.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final mode = StockMateThemeMode.values[index];
                          final theme = StockMateThemes.get(mode);
                          final isSelected = currentMode == mode;

                          return GestureDetector(
                            onTap: () => themeService.setTheme(mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? t.accentLight : t.surfaceAlt,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? t.accent : t.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Mini Preview (Variant M: 40x40)
                                  ThemePreviewTile(
                                    theme: theme,
                                    activeTheme: t,
                                    variant: PreviewVariant.M,
                                  ),
                                  const SizedBox(width: 14),
                                  // Name + Swatches
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          theme.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: t.text,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            theme.accent,
                                            theme.success,
                                            theme.warning,
                                            theme.danger,
                                            theme.purple,
                                          ].map((c) {
                                            return Container(
                                              width: 14,
                                              height: 14,
                                              margin: const EdgeInsets.only(right: 5),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: c,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Selected Check Badge
                                  if (isSelected)
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: t.accent,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.check,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Card 3 – Current Theme Info (Section 7.2)
                StockMateCard(
                  t: t,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Theme',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Mini Preview (Variant L: 56x56)
                          ThemePreviewTile(
                            theme: t,
                            activeTheme: t,
                            variant: PreviewVariant.L,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: t.accent,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isDark ? 'Dark theme' : 'Light theme',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: t.textSec,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    t.accent,
                                    t.success,
                                    t.warning,
                                    t.danger,
                                    t.purple,
                                  ].map((c) {
                                    return Container(
                                      width: 16,
                                      height: 16,
                                      margin: const EdgeInsets.only(right: 5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: c,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
