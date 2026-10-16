import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bottom_navigation_controller.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../sales/screens/sales_screen.dart';
import '../../purchases_expenses/screens/purchases_expenses_screen.dart';
import '../../reports/screens/reports_screen.dart';

class BottomNavigationScreen extends StatelessWidget {
  const BottomNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomNavigationController controller = Get.put(
      BottomNavigationController(),
    );

    return Scaffold(
      body: Stack(
        children: [
          Obx(() => _getPage(controller.currentIndex)),
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

  Widget _getPage(int index) {
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
        return const ReportsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
