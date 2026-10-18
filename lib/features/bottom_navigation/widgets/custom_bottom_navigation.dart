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

  static const List<_NavItemData> _navItems = [
    _NavItemData(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItemData(icon: Icons.inventory_2_rounded, label: 'Inventory'),
    _NavItemData(icon: Icons.point_of_sale_rounded, label: 'Sales & POS'),
    _NavItemData(icon: Icons.grid_view_rounded, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final t = themeService.t;

    return SafeArea(
        top: false,
        child: Container(
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
          height: 66.h,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: t.border.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: t.shadow,
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: t.accent.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _navItems.length;

              return Stack(
                children: [
                  // Smooth Animated Sliding Indicator Pill
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: tabWidth * currentIndex,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: t.accentLight,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: t.accent.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 20.w,
                          height: 3.h,
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Interactive Nav Items Row
                  Row(
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isSelected = currentIndex == index;

                      return Expanded(
                        child: _BouncingNavItem(
                          isSelected: isSelected,
                          icon: item.icon,
                          label: item.label,
                          accentColor: t.accent,
                          mutedColor: t.textMuted,
                          onTap: () => onTabSelected(index),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      );
  }
}

class _BouncingNavItem extends StatefulWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final Color accentColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _BouncingNavItem({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  State<_BouncingNavItem> createState() => _BouncingNavItemState();
}

class _BouncingNavItemState extends State<_BouncingNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Scaling Icon
              AnimatedScale(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                scale: widget.isSelected ? 1.15 : 1.0,
                child: Icon(
                  widget.icon,
                  size: 21.w,
                  color: widget.isSelected
                      ? widget.accentColor
                      : widget.mutedColor,
                ),
              ),
              3.verticalSpace,
              // Animated Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected
                      ? widget.accentColor
                      : widget.mutedColor,
                  letterSpacing: widget.isSelected ? 0.2 : 0,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.label,
  });
}
