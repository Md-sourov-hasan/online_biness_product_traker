import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_language_service.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0E1626)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                16.verticalSpace,

                // 1. Brand Logo & Header
                Container(
                  width: 68.w,
                  height: 68.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 36.w),
                ),
                16.verticalSpace,
                Text(
                  AppConstants.appName,
                  style: getTextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                4.verticalSpace,
                Text(
                  'Select your role to access your dedicated workspace',
                  textAlign: TextAlign.center,
                  style: getTextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                24.verticalSpace,

                // 2. Interactive 3-Role Selection Cards
                _buildRoleCard(
                  role: AppConstants.roleOwner,
                  title: 'Owner / Super Admin',
                  badge: 'Full Financial & Governance',
                  description: 'Section 9 P&L, Investor Cap Tables, Borrowed Loans, Price Floor Controls & Audit Trail',
                  icon: Icons.shield_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  isSelected: _selectedRole == AppConstants.roleOwner,
                  onTap: () {
                    setState(() {
                      _selectedRole = AppConstants.roleOwner;
                      _updateRoleDefaults(_selectedRole);
                    });
                  },
                ),
                14.verticalSpace,

                _buildRoleCard(
                  role: AppConstants.roleManager,
                  title: 'Store Manager',
                  badge: 'Operational & Restock Control',
                  description: 'Inventory Management, Discount Requests, Restock Orders & Operational Sales Analytics',
                  icon: Icons.manage_accounts_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                  isSelected: _selectedRole == AppConstants.roleManager,
                  onTap: () {
                    setState(() {
                      _selectedRole = AppConstants.roleManager;
                      _updateRoleDefaults(_selectedRole);
                    });
                  },
                ),
                14.verticalSpace,

                _buildRoleCard(
                  role: AppConstants.roleStaff,
                  title: 'Sales Associate / Staff',
                  badge: 'Privacy-First Terminal',
                  description: 'Fast POS Checkout, Product Selling Prices, Availability Checks & Personal Expense Submissions',
                  icon: Icons.point_of_sale_rounded,
                  accentColor: AppColors.secondary,
                  isSelected: _selectedRole == AppConstants.roleStaff,
                  onTap: () {
                    setState(() {
                      _selectedRole = AppConstants.roleStaff;
                      _updateRoleDefaults(_selectedRole);
                    });
                  },
                ),
                20.verticalSpace,

                // Optional Toggle for Custom Name/Email
                GestureDetector(
                  onTap: () => setState(() => _showCustomInput = !_showCustomInput),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showCustomInput ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 18.w,
                      ),
                      4.horizontalSpace,
                      Text(
                        _showCustomInput ? 'Hide credentials' : 'Edit session name & email',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
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
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            isDense: true,
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                          ),
                        ),
                        8.verticalSpace,
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            isDense: true,
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                24.verticalSpace,

                // 3. Enter Dashboard Primary CTA Button
                CustomFilledButton(
                  text: 'Enter Dashboard as ${_getRoleDisplayShort(_selectedRole)}',
                  onPressed: _proceedToDashboard,
                ),
                16.verticalSpace,

                // Footer Security Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 14.w, color: Colors.white.withValues(alpha: 0.5)),
                    6.horizontalSpace,
                    Text(
                      'End-to-End Capability Enforced • Role-Based Access Control',
                      style: TextStyle(fontSize: 10.sp, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                20.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String badge,
    required String description,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
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
                      Text(
                        title,
                        style: getTextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: accentColor, size: 20.w),
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
                      color: Colors.white.withValues(alpha: 0.7),
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

  String _getRoleDisplayShort(String role) {
    if (role == AppConstants.roleOwner) return 'Owner';
    if (role == AppConstants.roleManager) return 'Manager';
    return 'Staff';
  }
}
