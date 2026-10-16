import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/constants/colors.dart';
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
      return Container(
        decoration: BoxDecoration(
          color: themeService.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(
            top: BorderSide(color: themeService.inputBorderColor, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildNavItem(0, Icons.dashboard_rounded, 'nav_dashboard'.tr, themeService)),
                Expanded(child: _buildNavItem(1, Icons.inventory_2_rounded, 'nav_inventory'.tr, themeService)),
                Expanded(child: _buildNavItem(2, Icons.point_of_sale_rounded, 'nav_sales'.tr, themeService)),
                Expanded(child: _buildNavItem(3, Icons.receipt_long_rounded, 'nav_purchases_expenses'.tr, themeService)),
                Expanded(child: _buildNavItem(4, Icons.analytics_rounded, 'nav_reports'.tr, themeService)),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(int index, IconData icon, String label, ThemeLanguageService themeService) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : themeService.subtextColor,
              size: 22.w,
            ),
            4.verticalSpace,
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : themeService.subtextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
