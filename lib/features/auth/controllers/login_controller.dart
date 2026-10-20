import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../features/bottom_navigation/controllers/bottom_navigation_controller.dart';
import '../../../routes/app_routes.dart';

class RoleConfig {
  final String role;
  final String title;
  final String badge;
  final String description;
  final IconData icon;
  final Color? customAccent;

  const RoleConfig({
    required this.role,
    required this.title,
    required this.badge,
    required this.description,
    required this.icon,
    this.customAccent,
  });
}

class LoginController extends GetxController {
  final RxString selectedRole = AppConstants.roleOwner.obs;
  final RxBool showCustomInput = false.obs;
  final RxBool isLoading = false.obs;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(text: '••••••••');

  final List<RoleConfig> roleConfigs = const [
    RoleConfig(
      role: AppConstants.roleOwner,
      title: 'Owner / Super Admin',
      badge: 'Full Financial & Governance',
      description: 'Section 9 P&L, Investor Cap Tables, Borrowed Loans, Price Floor Controls & Audit Trail',
      icon: Icons.shield_rounded,
      customAccent: AppColors.warning,
    ),
    RoleConfig(
      role: AppConstants.roleManager,
      title: 'Store Manager',
      badge: 'Operational & Restock Control',
      description: 'Inventory Management, Discount Requests, Restock Orders & Operational Sales Analytics',
      icon: Icons.manage_accounts_rounded,
      customAccent: AppColors.purple,
    ),
    RoleConfig(
      role: AppConstants.roleStaff,
      title: 'Sales Associate / Staff',
      badge: 'Privacy-First Terminal',
      description: 'Fast POS Checkout, Product Selling Prices, Availability Checks & Personal Expense Submissions',
      icon: Icons.point_of_sale_rounded,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    updateRoleDefaults(selectedRole.value);
  }

  void selectRole(String role) {
    selectedRole.value = role;
    updateRoleDefaults(role);
  }

  void toggleCustomInput() {
    HapticFeedback.selectionClick();
    showCustomInput.value = !showCustomInput.value;
  }

  void updateRoleDefaults(String role) {
    if (role == AppConstants.roleOwner) {
      nameController.text = 'Sourov Hasan';
      emailController.text = 'owner@stockmate.com';
    } else if (role == AppConstants.roleManager) {
      nameController.text = 'Store Manager';
      emailController.text = 'manager@stockmate.com';
    } else {
      nameController.text = 'Sales Associate';
      emailController.text = 'staff@stockmate.com';
    }
  }

  String get roleDisplayShort {
    if (selectedRole.value == AppConstants.roleOwner) return 'Owner';
    if (selectedRole.value == AppConstants.roleManager) return 'Manager';
    return 'Staff';
  }

  Future<void> proceedToDashboard(BuildContext context) async {
    if (isLoading.value) return;

    if (Get.isRegistered<ConnectivityService>()) {
      final connectivity = Get.find<ConnectivityService>();
      if (!connectivity.isConnected.value) {
        Get.snackbar(
          'No Internet',
          'Please check your internet connection and try again',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    HapticFeedback.mediumImpact();
    isLoading.value = true;

    try {
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        await auth.loginAsRole(
          selectedRole.value,
          customName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
          customEmail: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
        );
      }

      if (Get.isRegistered<BottomNavigationController>()) {
        Get.find<BottomNavigationController>().changeTab(0);
      }

      if (context.mounted) {
        context.go(AppRoute.bottomNavigationScreen);
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
