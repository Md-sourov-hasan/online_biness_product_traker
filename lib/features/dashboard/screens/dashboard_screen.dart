import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../products/controllers/products_controller.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../bottom_navigation/controllers/bottom_navigation_controller.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are ready
    final ProductsController productsController = Get.put(ProductsController());
    final OrdersController ordersController = Get.put(OrdersController());
    final BottomNavigationController nav = Get.find<BottomNavigationController>();

    return CommonBackgroundScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back,',
                        style: getTextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        'Store Owner',
                        style: getTextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24.w,
                    backgroundColor: AppColors.accentLight,
                    child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28.w),
                  ),
                ],
              ),
              32.verticalSpace,
              
              // Key Metrics Row
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      'Total Revenue',
                      '৳${ordersController.totalRevenue.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_rounded,
                      AppColors.primary,
                    )),
                  ),
                  16.horizontalSpace,
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      'Total Orders',
                      '${ordersController.completedOrders.length}',
                      Icons.receipt_long_rounded,
                      AppColors.secondary,
                    )),
                  ),
                ],
              ),
              16.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      'Stock Value',
                      '৳${productsController.totalStockValue.toStringAsFixed(0)}',
                      Icons.inventory_2_rounded,
                      AppColors.warning,
                    )),
                  ),
                  16.horizontalSpace,
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      'Low Stock Alerts',
                      '${productsController.lowStockProducts.length}',
                      Icons.warning_amber_rounded,
                      AppColors.error,
                      isAlert: productsController.lowStockProducts.isNotEmpty,
                    )),
                  ),
                ],
              ),
              32.verticalSpace,
              
              Text(
                'Quick Actions',
                style: getTextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              16.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(
                    'Add Product',
                    Icons.add_box_rounded,
                    AppColors.primary,
                    () => context.push(AppRoute.addEditProductScreen),
                  ),
                  _buildQuickAction(
                    'Create Order',
                    Icons.add_shopping_cart_rounded,
                    AppColors.secondary,
                    () => context.push(AppRoute.addOrderScreen),
                  ),
                  _buildQuickAction(
                    'View Reports',
                    Icons.analytics_rounded,
                    AppColors.warning,
                    () => nav.changeTab(3),
                  ),
                ],
              ),
              32.verticalSpace,
              
              Text(
                'Recent Low Stock',
                style: getTextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              16.verticalSpace,
              Obx(() {
                final lowStockList = productsController.lowStockProducts;
                if (lowStockList.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Text(
                        'All products are well stocked!',
                        style: getTextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: lowStockList.take(3).map((p) => Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.name,
                          style: getTextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${p.stockQuantity} left',
                          style: getTextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isAlert = false}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: isAlert ? color.withOpacity(0.2) : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isAlert ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 24.w),
          ),
          16.verticalSpace,
          Text(
            title,
            style: getTextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          4.verticalSpace,
          Text(
            value,
            style: getTextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28.w),
          ),
          8.verticalSpace,
          Text(
            title,
            style: getTextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
