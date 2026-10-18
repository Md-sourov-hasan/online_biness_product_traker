import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bottom_navigation_controller.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../sales/screens/sales_screen.dart';
import '../../settings/screens/more_screen.dart';

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
          Obx(() {
            return IndexedStack(
              index: controller.currentIndex,
              children: const [
                DashboardScreen(),
                ProductsScreen(),
                SalesScreen(),
                MoreScreen(),
              ],
            );
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
}
