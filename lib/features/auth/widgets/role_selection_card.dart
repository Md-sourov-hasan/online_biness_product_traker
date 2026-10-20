import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../core/utils/sizer.dart';

class RoleSelectionCard extends StatelessWidget {
  final ThemeTokens t;
  final String title;
  final String badge;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleSelectionCard({
    super.key,
    required this.t,
    required this.title,
    required this.badge,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : t.card,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? accentColor : t.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? accentColor.withValues(alpha: 0.18) : t.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isSelected ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: accentColor, size: 24.w),
            ),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: getTextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: t.text,
                          ),
                        ),
                      ),
                      AnimatedScale(
                        scale: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: accentColor,
                            size: 20.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                  4.verticalSpace,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.5.h),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                  6.verticalSpace,
                  Text(
                    description,
                    style: getTextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: t.textSec,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
