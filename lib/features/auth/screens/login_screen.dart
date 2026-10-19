import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../core/common/widgets/stockmate_components.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/customize_filled_button.dart';
import '../../../features/bottom_navigation/controllers/bottom_navigation_controller.dart';
import '../../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService auth = Get.find<AuthService>();
  final ThemeLanguageService theme = Get.find<ThemeLanguageService>();

  String _selectedRole = AppConstants.roleOwner;
  bool _showCustomInput = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: '••••••••');

  @override
  void initState() {
    super.initState();
    _updateRoleDefaults(_selectedRole);
  }

  void _updateRoleDefaults(String role) {
    if (role == AppConstants.roleOwner) {
      _nameController.text = 'Sourov Hasan';
      _emailController.text = 'owner@stockmate.com';
    } else if (role == AppConstants.roleManager) {
      _nameController.text = 'Store Manager';
      _emailController.text = 'manager@stockmate.com';
    } else {
      _nameController.text = 'Sales Associate';
      _emailController.text = 'staff@stockmate.com';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _proceedToDashboard() async {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      await auth.loginAsRole(
        _selectedRole,
        customName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        customEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      );

      if (Get.isRegistered<BottomNavigationController>()) {
        Get.find<BottomNavigationController>().changeTab(0);
      }

      if (mounted) {
        context.go(AppRoute.bottomNavigationScreen);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showThemeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Obx(() {
          final currentMode = theme.currentThemeMode.value;
          final currentTokens = theme.t;

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
                      onPressed: () => Navigator.pop(ctx),
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
                          theme.setTheme(mode);
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
      },
    );
  }

  Widget _colorDot(Color c) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final t = theme.t;
      final isDark = theme.isDark;

      return Scaffold(
        backgroundColor: t.bg,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      t.bg,
                      t.surfaceAlt.withValues(alpha: 0.6),
                      t.bg,
                    ]
                  : [
                      t.bg,
                      t.surfaceAlt,
                      t.bg,
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Header Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: t.border),
                          boxShadow: [
                            BoxShadow(
                              color: t.shadow,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: t.success,
                              ),
                            ),
                            6.horizontalSpace,
                            Text(
                              'STOCKMATE ERP',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: t.textSec,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Quick Dark/Light Toggle
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              theme.toggleDarkMode();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: t.card,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: t.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: t.shadow,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isDark ? '🌙' : '☀️',
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                  4.horizontalSpace,
                                  Text(
                                    isDark ? 'Dark' : 'Light',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: t.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          8.horizontalSpace,
                          // Theme Palette Picker Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showThemeModal(context);
                            },
                            child: Container(
                              padding: EdgeInsets.all(7.w),
                              decoration: BoxDecoration(
                                color: t.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: t.accent.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: t.shadow,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.palette_outlined,
                                color: t.accent,
                                size: 18.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  14.verticalSpace,

                  // 1. Brand Logo & Header
                  Container(
                    width: 68.w,
                    height: 68.w,
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: t.accent.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 36.w),
                  ),
                  14.verticalSpace,
                  Text(
                    AppConstants.appName,
                    style: getTextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: t.text,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    'Select your role to access your dedicated workspace',
                    textAlign: TextAlign.center,
                    style: getTextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: t.textSec,
                    ),
                  ),
                  20.verticalSpace,

                  // 2. Interactive 3-Role Selection Cards
                  RepaintBoundary(
                    child: Column(
                      children: [
                        _RoleSelectionCard(
                          t: t,
                          role: AppConstants.roleOwner,
                          title: 'Owner / Super Admin',
                          badge: 'Full Financial & Governance',
                          description: 'Section 9 P&L, Investor Cap Tables, Borrowed Loans, Price Floor Controls & Audit Trail',
                          icon: Icons.shield_rounded,
                          accentColor: AppColors.warning,
                          isSelected: _selectedRole == AppConstants.roleOwner,
                          onTap: () {
                            setState(() {
                              _selectedRole = AppConstants.roleOwner;
                              _updateRoleDefaults(_selectedRole);
                            });
                          },
                        ),
                        12.verticalSpace,

                        _RoleSelectionCard(
                          t: t,
                          role: AppConstants.roleManager,
                          title: 'Store Manager',
                          badge: 'Operational & Restock Control',
                          description: 'Inventory Management, Discount Requests, Restock Orders & Operational Sales Analytics',
                          icon: Icons.manage_accounts_rounded,
                          accentColor: AppColors.purple,
                          isSelected: _selectedRole == AppConstants.roleManager,
                          onTap: () {
                            setState(() {
                              _selectedRole = AppConstants.roleManager;
                              _updateRoleDefaults(_selectedRole);
                            });
                          },
                        ),
                        12.verticalSpace,

                        _RoleSelectionCard(
                          t: t,
                          role: AppConstants.roleStaff,
                          title: 'Sales Associate / Staff',
                          badge: 'Privacy-First Terminal',
                          description: 'Fast POS Checkout, Product Selling Prices, Availability Checks & Personal Expense Submissions',
                          icon: Icons.point_of_sale_rounded,
                          accentColor: t.accent,
                          isSelected: _selectedRole == AppConstants.roleStaff,
                          onTap: () {
                            setState(() {
                              _selectedRole = AppConstants.roleStaff;
                              _updateRoleDefaults(_selectedRole);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  18.verticalSpace,

                  // Optional Toggle for Custom Name/Email
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showCustomInput = !_showCustomInput);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showCustomInput ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: t.textMuted,
                          size: 18.w,
                        ),
                        4.horizontalSpace,
                        Text(
                          _showCustomInput ? 'Hide credentials' : 'Edit session name & email',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: t.textSec,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_showCustomInput) ...[
                    12.verticalSpace,
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: t.border),
                        boxShadow: [
                          BoxShadow(
                            color: t.shadow,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: TextStyle(color: t.text, fontSize: 13.sp),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: TextStyle(color: t.textSec, fontSize: 12.sp),
                              isDense: true,
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.border)),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.accent, width: 2)),
                            ),
                          ),
                          8.verticalSpace,
                          TextField(
                            controller: _emailController,
                            style: TextStyle(color: t.text, fontSize: 13.sp),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: TextStyle(color: t.textSec, fontSize: 12.sp),
                              isDense: true,
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.border)),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.accent, width: 2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  20.verticalSpace,

                  // 3. Enter Dashboard Primary CTA Button
                  CustomFilledButton(
                    text: 'Enter Dashboard as ${_getRoleDisplayShort(_selectedRole)}',
                    color: t.accent,
                    isLoading: _isLoading,
                    onPressed: _proceedToDashboard,
                  ),
                  14.verticalSpace,

                  // Footer Security Note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14.w, color: t.textMuted),
                      6.horizontalSpace,
                      Flexible(
                        child: Text(
                          'End-to-End Capability Enforced • Role-Based Access Control',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.sp, color: t.textMuted),
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _getRoleDisplayShort(String role) {
    if (role == AppConstants.roleOwner) return 'Owner';
    if (role == AppConstants.roleManager) return 'Manager';
    return 'Staff';
  }
}

class _RoleSelectionCard extends StatefulWidget {
  final ThemeTokens t;
  final String role;
  final String title;
  final String badge;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.t,
    required this.role,
    required this.title,
    required this.badge,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleSelectionCard> createState() => _RoleSelectionCardState();
}

class _RoleSelectionCardState extends State<_RoleSelectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.978).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isSelected = widget.isSelected;
    final accentColor = widget.accentColor;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: () {
          _pressController.reverse();
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : t.card,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected ? accentColor : t.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.18)
                      : t.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isSelected ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(widget.icon, color: accentColor, size: 24.w),
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
                              widget.title,
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
                          widget.badge,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                      6.verticalSpace,
                      Text(
                        widget.description,
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
        ),
      ),
    );
  }
}
