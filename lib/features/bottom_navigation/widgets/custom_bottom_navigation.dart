import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/sizer.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();

    return Obx(() {
      final t = themeService.t;

      return Container(
        height: 64.h,
        decoration: BoxDecoration(
          color: t.nav,
          boxShadow: [
            BoxShadow(
              color: t.shadow,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: t.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard', themeService)),
                Expanded(child: _buildNavItem(1, Icons.inventory_2_rounded, 'Inventory', themeService)),
                Expanded(child: _buildNavItem(2, Icons.point_of_sale_rounded, 'Sales & POS', themeService)),
                Expanded(child: _buildNavItem(3, Icons.grid_view_rounded, 'More', themeService)),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(int index, IconData icon, String label, ThemeLanguageService themeService) {
    final t = themeService.t;
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? t.accentLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? t.accent : t.textMuted,
              size: 20.w,
            ),
            2.verticalSpace,
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? t.accent : t.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
