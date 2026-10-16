import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bottom_navigation_controller.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../sales/screens/sales_screen.dart';
import '../../purchases_expenses/screens/purchases_expenses_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../../core/services/permission_service.dart';

class BottomNavigationScreen extends StatelessWidget {
  const BottomNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomNavigationController controller = Get.put(
      BottomNavigationController(),
    );
    final PermissionService perm = Get.find<PermissionService>();

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            // Guard against out of range if switched from Manager/Owner to Staff while on index 4
            if (perm.isStaff && controller.currentIndex > 3) {
              controller.changeTab(0);
            }
            return _getPage(controller.currentIndex, perm.isStaff);
          }),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(
              () => CustomBottomNavBar(
                currentIndex: controller.currentIndex,
                onTabSelected: (index) => controller.changeTab(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPage(int index, bool isStaff) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ProductsScreen();
      case 2:
        return const SalesScreen();
      case 3:
        return const PurchasesExpensesScreen();
      case 4:
        return isStaff ? const DashboardScreen() : const ReportsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
