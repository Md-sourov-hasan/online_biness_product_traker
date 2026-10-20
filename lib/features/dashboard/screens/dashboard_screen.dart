import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';
import '../../bottom_navigation/controllers/bottom_navigation_controller.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../routes/app_routes.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/activity_log_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    final PermissionService perm = Get.find<PermissionService>();

    return CommonBackgroundScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Obx(() {
            if (perm.isStaff) {
              return const _StaffDashboardView();
            } else if (perm.isManager) {
              return const _ManagerDashboardView();
            } else {
              return const _OwnerDashboardView();
            }
          }),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. STAFF DASHBOARD (Spec Section 6.1: Intentionally Minimal & Privacy-First)
  // ===========================================================================
  static Widget _buildStaffDashboard(
    BuildContext context,
    AuthService auth,
    DatabaseService db,
    ThemeLanguageService themeService,
    BottomNavigationController nav,
  ) {
    final userName = auth.currentUser.value?.name ?? 'Staff';
    final userExpenses = db.getExpensesForUser(auth.currentUser.value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, auth, db, themeService),
        20.verticalSpace,

        // Staff Welcome Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.tealGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'SALES & DISPATCH TERMINAL',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.point_of_sale_rounded,
                    color: Colors.white,
                    size: 24.w,
                  ),
                ],
              ),
              12.verticalSpace,
              Text(
                'Welcome, $userName',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              4.verticalSpace,
              Text(
                'Ready to process customer sales and record delivery expenses.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        20.verticalSpace,

        // Quick Task Buttons for Staff
        Text(
          'Quick Tasks',
          style: getTextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        12.verticalSpace,
        Row(
          children: [
            Expanded(
              child: _buildStaffActionCard(
                title: 'New Sale (POS)',
                subtitle: 'Process order',
                icon: Icons.point_of_sale_rounded,
                color: AppColors.primary,
                theme: themeService,
                onTap: () => nav.changeTab(2),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: _buildStaffActionCard(
                title: 'Check Stock & Price',
                subtitle: 'View availability',
                icon: Icons.search_rounded,
                color: AppColors.teal,
                theme: themeService,
                onTap: () => nav.changeTab(1),
              ),
            ),
          ],
        ),
        12.verticalSpace,
        Row(
          children: [
            Expanded(
              child: _buildStaffActionCard(
                title: 'Record Expense',
                subtitle: 'Delivery / courier',
                icon: Icons.receipt_long_rounded,
                color: AppColors.error,
                theme: themeService,
                onTap: () => context.push(AppRoute.purchasesExpensesScreen),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: _buildStaffActionCard(
                title: 'My Submissions',
                subtitle: '${userExpenses.length} entries (30d)',
                icon: Icons.history_rounded,
                color: AppColors.secondary,
                theme: themeService,
                onTap: () => context.push(AppRoute.purchasesExpensesScreen),
              ),
            ),
          ],
        ),
        24.verticalSpace,

        // Available Products Quick Check (Price & Availability only - NO cost price!)
        Text(
          'Available Products & Customer Selling Prices',
          style: getTextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        10.verticalSpace,
        Obx(() {
          final products = db.products.take(6).toList();
          return Column(
            children: [
              for (int i = 0; i < products.length; i++) ...[
                if (i > 0) 8.verticalSpace,
                _buildStaffProductRow(products[i], themeService),
              ],
            ],
          );
        }),
        80.verticalSpace,
      ],
    );
  }

  static Widget _buildStaffProductRow(Product p, ThemeLanguageService themeService) {
    final inStock = p.quantity > 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: themeService.inputBorderColor,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.displayName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: themeService.textColor,
                  ),
                ),
                Text(
                  'Code: ${p.productCode} • ${inStock ? "${p.quantity} pcs available" : "Out of Stock"}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: inStock ? AppColors.success : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳${p.sellingPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Selling Price',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: themeService.subtextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildStaffActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required ThemeLanguageService theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 22.w),
            ),
            10.verticalSpace,
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            2.verticalSpace,
            Text(
              subtitle,
              style: TextStyle(fontSize: 11.sp, color: theme.subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. MANAGER DASHBOARD (Spec Section 5.4: Operational Metrics)
  // ===========================================================================
  static Widget _buildManagerDashboard(
    BuildContext context,
    AuthService auth,
    DatabaseService db,
    DashboardController controller,
    ThemeLanguageService themeService,
    BottomNavigationController nav,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, auth, db, themeService),
        20.verticalSpace,

        // Operational Stock Units Card (No Total Valuation exposed to Manager)
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OPERATIONAL INVENTORY',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 20.w,
                  ),
                ],
              ),
              10.verticalSpace,
              Obx(
                () => Text(
                  '${db.totalStockPieces} Units in Stock',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              4.verticalSpace,
              Obx(
                () => Text(
                  'Across ${db.products.length} distinct SKUs & ${db.allBrands.length} brands',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
        16.verticalSpace,

        // Rotating Sales Units & Expenses
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _buildRotatingMetricCard(
                  title: controller.currentSalesLabelKey.tr,
                  value: '৳${controller.currentPeriodSales.toStringAsFixed(0)}',
                  subtitle: 'Operational Sales',
                  icon: Icons.trending_up_rounded,
                  accentColor: AppColors.primary,
                  onTap: controller.cycleSalesRotation,
                  themeService: themeService,
                  tag: controller.currentSalesPeriod.toUpperCase(),
                ),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: themeService.cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.error,
                      size: 22.w,
                    ),
                    12.verticalSpace,
                    Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: themeService.subtextColor,
                      ),
                    ),
                    4.verticalSpace,
                    Obx(
                      () => Text(
                        '৳${db.totalExpenses.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: themeService.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        24.verticalSpace,

        // Quick Actions for Manager
        Text(
          'Manager Quick Actions',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        12.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildActionItem(
                'New Sale',
                Icons.point_of_sale_rounded,
                AppColors.primary,
                () => nav.changeTab(2),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'Restock',
                Icons.add_shopping_cart_rounded,
                AppColors.secondary,
                () => context.push(AppRoute.purchasesExpensesScreen),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'Add SKU',
                Icons.add_box_rounded,
                AppColors.warning,
                () => context.push(AppRoute.addEditProductScreen),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'Discounts',
                Icons.discount_rounded,
                AppColors.purple,
                () => context.push(AppRoute.discountManagementScreen),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'Suppliers',
                Icons.local_shipping_rounded,
                AppColors.teal,
                () => context.push(AppRoute.supplierManagementScreen),
                themeService,
              ),
            ),
          ],
        ),
        24.verticalSpace,

        _buildLowStockSection(db, context, themeService),
        24.verticalSpace,
        _buildRecentActivitySection(db, themeService),
        80.verticalSpace,
      ],
    );
  }

  // ===========================================================================
  // 3. OWNER DASHBOARD (Spec Section 2.1 & 10: Complete Financial & Audit Access)
  // ===========================================================================
  static Widget _buildOwnerDashboard(
    BuildContext context,
    AuthService auth,
    DatabaseService db,
    DashboardController controller,
    ThemeLanguageService themeService,
    BottomNavigationController nav,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, auth, db, themeService),
        20.verticalSpace,

        // 1. Product Quantity & Total Valuation Card
        _buildProductQuantityCard(context, db, themeService, nav),
        16.verticalSpace,

        // 2. 5-Second Rotating Sales & Profit Cards (Side by Side)
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _buildRotatingMetricCard(
                  title: controller.currentSalesLabelKey.tr,
                  value: '৳${controller.currentPeriodSales.toStringAsFixed(0)}',
                  subtitle: 'Tap to cycle',
                  icon: Icons.trending_up_rounded,
                  accentColor: AppColors.primary,
                  onTap: controller.cycleSalesRotation,
                  themeService: themeService,
                  tag: controller.currentSalesPeriod.toUpperCase(),
                ),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Obx(
                () => _buildRotatingMetricCard(
                  title: controller.currentProfitLabelKey.tr,
                  value:
                      '৳${controller.currentPeriodProfit.toStringAsFixed(0)}',
                  subtitle: 'Tap to cycle',
                  icon: Icons.auto_graph_rounded,
                  accentColor: AppColors.secondary,
                  onTap: controller.cycleProfitRotation,
                  themeService: themeService,
                  tag: controller.currentProfitPeriod.toUpperCase(),
                ),
              ),
            ),
          ],
        ),
        16.verticalSpace,

        // 3. Complete Financial & Accounting Breakdown (Spec Section 9)
        _buildComprehensiveFinancialSummary(db, themeService),
        20.verticalSpace,

        // 4. Owner Capital, Debt & Receivables Hub (Spec Section 11, 12, 13)
        _buildOwnerCapitalHub(context, db, themeService),
        24.verticalSpace,

        // 5. Quick Actions Grid
        Text(
          'quick_actions'.tr,
          style: getTextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        14.verticalSpace,
        _buildOwnerQuickActionsGrid(context, nav, themeService),
        24.verticalSpace,

        // 6. Active Low Stock Alerts Section
        _buildLowStockSection(db, context, themeService),
        24.verticalSpace,

        // 7. Recent Activity Timeline (Complete Audit Trail)
        _buildRecentActivitySection(db, themeService),
        80.verticalSpace,
      ],
    );
  }

  // --- Header with Exact-Time Sync (Spec Section 10.2) ---
  static Widget _buildHeader(
    BuildContext context,
    AuthService auth,
    DatabaseService db,
    ThemeLanguageService themeService,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.w,
                runSpacing: 4.h,
                children: [
                  Text(
                    'app_name'.tr,
                    style: getTextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Obx(
                      () => Text(
                        auth.currentUser.value?.role ?? 'Staff',
                        style: getTextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              4.verticalSpace,
              Obx(
                () => Text(
                  '${'welcome_back'.tr} ${auth.currentUser.value?.name ?? 'User'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getTextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: themeService.subtextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        8.horizontalSpace,
        // Notification Bell Icon with Live Badge
        Builder(
          builder: (context) {
            final NotificationsController notifCtrl =
                Get.isRegistered<NotificationsController>()
                ? Get.find<NotificationsController>()
                : Get.put(NotificationsController());

            return Obx(() {
              final unread = notifCtrl.unreadCount;
              return GestureDetector(
                onTap: () => context.push(AppRoute.notificationsScreen),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(7.5.w),
                      decoration: BoxDecoration(
                        color: themeService.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: unread > 0
                              ? AppColors.warning.withValues(alpha: 0.6)
                              : themeService.t.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        unread > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        size: 18.w,
                        color: unread > 0
                            ? AppColors.warning
                            : themeService.textColor,
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -3.h,
                        right: -3.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: themeService.backgroundColor,
                              width: 1.5,
                            ),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16.w,
                            minHeight: 16.h,
                          ),
                          child: Center(
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            });
          },
        ),
        8.horizontalSpace,
        // Exact-Time Sync Button (Spec Section 10.2: Exact available data up to the second)
        Obx(() {
          final isSyncing = db.isSyncing.value;
          final timeStr = DateFormat(
            'hh:mm:ss a',
          ).format(db.lastSyncTime.value);
          return GestureDetector(
            onTap: () async {
              await db.triggerCloudSync();
              Get.snackbar(
                'Authoritative State Synced',
                'Data synchronized up to $timeStr',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSyncing
                      ? AppColors.warning
                      : AppColors.secondary.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSyncing ? Icons.sync_rounded : Icons.cloud_done_rounded,
                    size: 14.w,
                    color: isSyncing ? AppColors.warning : AppColors.secondary,
                  ),
                  4.horizontalSpace,
                  Text(
                    isSyncing ? 'Syncing...' : 'Sync ($timeStr)',
                    style: getTextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isSyncing
                          ? AppColors.warning
                          : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- Product Quantity & Valuation Card ---
  static Widget _buildProductQuantityCard(
    BuildContext context,
    DatabaseService db,
    ThemeLanguageService themeService,
    BottomNavigationController nav,
  ) {
    return Obx(() {
      final totalPieces = db.totalStockPieces;
      final totalValuation = db.totalStockValuation;
      final catalogCount = db.products.length;
      final brandCount = db.allBrands.length;
      final auth = AuthService.to;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.blueGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 18.w,
                        ),
                      ),
                      8.horizontalSpace,
                      Expanded(
                        child: Text(
                          'total_inventory'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: getTextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (auth.isSuperAdmin) {
                      context.push(AppRoute.branchesScreen);
                    } else {
                      nav.changeTab(1);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          auth.isSuperAdmin ? 'View Branches' : 'View All',
                          style: getTextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        4.horizontalSpace,
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 10.w,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            14.verticalSpace,
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$totalPieces',
                  style: getTextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                6.horizontalSpace,
                Text(
                  'units_in_stock'.tr,
                  style: getTextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            8.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'total_valuation'.tr}: ৳${totalValuation.toStringAsFixed(0)}',
                  style: getTextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow,
                  ),
                ),
              ],
            ),
            12.verticalSpace,
            Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
            10.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SKUs: $catalogCount',
                  style: getTextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  'Brands: $brandCount',
                  style: getTextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // --- Rotating Metric Card ---
  static Widget _buildRotatingMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required ThemeLanguageService themeService,
    required String tag,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: accentColor, size: 20.w),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    tag,
                    style: getTextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            12.verticalSpace,
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getTextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: themeService.subtextColor,
              ),
            ),
            4.verticalSpace,
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getTextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: themeService.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Comprehensive Accounting Engine Summary (Spec Section 9) ---
  static Widget _buildComprehensiveFinancialSummary(
    DatabaseService db,
    ThemeLanguageService themeService,
  ) {
    return Obx(() {
      final grossSales = db.totalGrossSales;
      final discounts = db.totalAuthorizedDiscounts;
      final refunds = db.totalRefunds;
      final netSales = db.totalRevenue;
      final cogs = db.totalCOGS;
      final grossProfit = db.totalGrossProfit;
      final expenses = db.totalExpenses;
      final loanInterest = db.totalLoanInterestExpenses;
      final netProfit = db.netProfit;

      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: themeService.inputBorderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Financial Engine & Accounting Summary',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: themeService.textColor,
                    ),
                  ),
                ),
                8.horizontalSpace,
                Text(
                  'Spec Section 9',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            12.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: _buildFinancialItem(
                    'Net Revenue',
                    '৳${netSales.toStringAsFixed(0)}',
                    AppColors.primary,
                    themeService,
                  ),
                ),
                Container(
                  width: 1,
                  height: 35.h,
                  color: themeService.inputBorderColor,
                ),
                Expanded(
                  child: _buildFinancialItem(
                    'COGS',
                    '৳${cogs.toStringAsFixed(0)}',
                    Colors.orange,
                    themeService,
                  ),
                ),
                Container(
                  width: 1,
                  height: 35.h,
                  color: themeService.inputBorderColor,
                ),
                Expanded(
                  child: _buildFinancialItem(
                    'Gross Profit',
                    '৳${grossProfit.toStringAsFixed(0)}',
                    AppColors.secondary,
                    themeService,
                    isBold: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 35.h,
                  color: themeService.inputBorderColor,
                ),
                Expanded(
                  child: _buildFinancialItem(
                    'Net Profit',
                    '৳${netProfit.toStringAsFixed(0)}',
                    netProfit >= 0 ? AppColors.success : AppColors.error,
                    themeService,
                    isBold: true,
                  ),
                ),
              ],
            ),
            10.verticalSpace,
            Container(
              height: 1,
              color: themeService.inputBorderColor.withValues(alpha: 0.5),
            ),
            8.verticalSpace,
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 10.sp,
                  color: themeService.subtextColor,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: 'Gross: ৳${grossSales.toStringAsFixed(0)}'),
                  TextSpan(
                    text: '  •  ',
                    style: TextStyle(
                      color: themeService.subtextColor.withValues(alpha: 0.4),
                    ),
                  ),
                  TextSpan(text: 'Discounts: -৳${discounts.toStringAsFixed(0)}'),
                  TextSpan(
                    text: '  •  ',
                    style: TextStyle(
                      color: themeService.subtextColor.withValues(alpha: 0.4),
                    ),
                  ),
                  TextSpan(text: 'OpEx: -৳${expenses.toStringAsFixed(0)}'),
                  TextSpan(
                    text: '  •  ',
                    style: TextStyle(
                      color: themeService.subtextColor.withValues(alpha: 0.4),
                    ),
                  ),
                  TextSpan(text: 'Refunds: -৳${refunds.toStringAsFixed(0)}'),
                  if (loanInterest > 0) ...[
                    TextSpan(
                      text: '  •  ',
                      style: TextStyle(
                        color: themeService.subtextColor.withValues(alpha: 0.4),
                      ),
                    ),
                    TextSpan(
                      text: 'Loan Interest: -৳${loanInterest.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  static Widget _buildFinancialItem(
    String label,
    String amount,
    Color color,
    ThemeLanguageService themeService, {
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: getTextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: themeService.subtextColor,
          ),
        ),
        4.verticalSpace,
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            maxLines: 1,
            style: getTextStyle(
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // --- Owner Capital & Liabilities Hub (Spec Section 11, 12, 13) ---
  static Widget _buildOwnerCapitalHub(
    BuildContext context,
    DatabaseService db,
    ThemeLanguageService theme,
  ) {
    return Obx(() {
      final investors = db.investors;
      final totalActiveCapital = investors.fold(
        0.0,
        (sum, i) => sum + db.getNetActiveCapitalForInvestor(i.id),
      );

      final loans = db.loans;
      final totalDebt = loans.fold(
        0.0,
        (sum, l) => sum + db.getOutstandingLoanPrincipal(l.id),
      );

      final recs = db.receivables;
      final totalReceivables = recs.fold(
        0.0,
        (sum, r) => sum + db.getOutstandingReceivablePrincipal(r.id),
      );

      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Owner Capital, Loans & Receivables',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                ),
                8.horizontalSpace,
                Text(
                  'Exclusive Hub',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            12.verticalSpace,
            Row(
              children: [
                // Investors
                Expanded(
                  child: _buildOwnerHubTile(
                    title: 'Active Investors',
                    value: '৳${totalActiveCapital.toStringAsFixed(0)}',
                    subtitle: '${investors.length} Partners',
                    color: AppColors.primary,
                    theme: theme,
                    onTap: () =>
                        context.push(AppRoute.investorManagementScreen),
                  ),
                ),
                8.horizontalSpace,
                // Loans
                Expanded(
                  child: _buildOwnerHubTile(
                    title: 'Loan Debt',
                    value: '৳${totalDebt.toStringAsFixed(0)}',
                    subtitle: '${loans.length} Borrowed',
                    color: Colors.redAccent,
                    theme: theme,
                    onTap: () => context.push(AppRoute.loanManagementScreen),
                  ),
                ),
                8.horizontalSpace,
                // Money Lent
                Expanded(
                  child: _buildOwnerHubTile(
                    title: 'Money Lent',
                    value: '৳${totalReceivables.toStringAsFixed(0)}',
                    subtitle: '${recs.length} Receivables',
                    color: AppColors.secondary,
                    theme: theme,
                    onTap: () => context.push(AppRoute.moneyLentScreen),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  static Widget _buildOwnerHubTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required ThemeLanguageService theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            4.verticalSpace,
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: theme.textColor,
                ),
              ),
            ),
            2.verticalSpace,
            Text(
              subtitle,
              style: TextStyle(fontSize: 9.sp, color: theme.subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  // --- Owner Quick Actions Grid ---
  static Widget _buildOwnerQuickActionsGrid(
    BuildContext context,
    BottomNavigationController nav,
    ThemeLanguageService themeService,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildActionItem(
                'action_new_sale'.tr,
                Icons.point_of_sale_rounded,
                AppColors.primary,
                () => nav.changeTab(2),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'action_purchase'.tr,
                Icons.add_shopping_cart_rounded,
                AppColors.secondary,
                () => context.push(AppRoute.purchasesExpensesScreen),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'action_add_product'.tr,
                Icons.add_box_rounded,
                AppColors.warning,
                () => context.push(AppRoute.addEditProductScreen),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'action_reports'.tr,
                Icons.pie_chart_rounded,
                AppColors.purple,
                () => context.push(AppRoute.reportsScreen),
                themeService,
              ),
            ),
          ],
        ),
        12.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildActionItem(
                'Policies',
                Icons.shield_rounded,
                AppColors.primary,
                () => context.push(AppRoute.policyControlScreen),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'Discounts',
                Icons.discount_rounded,
                AppColors.rose,
                () => context.push(AppRoute.discountManagementScreen),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'Suppliers',
                Icons.local_shipping_rounded,
                AppColors.teal,
                () => context.push(AppRoute.supplierManagementScreen),
                themeService,
              ),
            ),
            Expanded(
              child: _buildActionItem(
                'Audit Logs',
                Icons.history_edu_rounded,
                AppColors.textSecondary,
                () => context.push(AppRoute.activityLogsScreen),
                themeService,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildActionItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ThemeLanguageService themeService,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: color, size: 22.w),
          ),
          6.verticalSpace,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: getTextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: themeService.textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Low Stock Alert Section ---
  static Widget _buildLowStockSection(
    DatabaseService db,
    BuildContext context,
    ThemeLanguageService themeService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 20.w,
                ),
                6.horizontalSpace,
                Text(
                  'low_stock_alerts'.tr,
                  style: getTextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: themeService.textColor,
                  ),
                ),
              ],
            ),
            Obx(
              () => Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${db.lowStockProducts.length} Items',
                  style: getTextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
        10.verticalSpace,
        Obx(() {
          final lowStock = db.lowStockProducts;
          if (lowStock.isEmpty) {
            return Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.secondary,
                    size: 20.w,
                  ),
                  8.horizontalSpace,
                  Text(
                    'All inventory levels are healthy.',
                    style: TextStyle(
                      color: themeService.subtextColor,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < lowStock.length; i++) ...[
                if (i > 0) 8.verticalSpace,
                _buildLowStockItem(lowStock[i], themeService),
              ],
            ],
          );
        }),
      ],
    );
  }

  static Widget _buildLowStockItem(Product p, ThemeLanguageService themeService) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.displayName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: themeService.textColor,
                  ),
                ),
                Text(
                  'Code: ${p.productCode} • Threshold: ${p.lowStockThreshold} pcs',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: themeService.subtextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${p.quantity} pcs left',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  // --- Recent Activity Section ---
  static Widget _buildRecentActivitySection(
    DatabaseService db,
    ThemeLanguageService themeService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recent_activities'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        12.verticalSpace,
        Obx(() {
          final logs = db.activityLogs.take(5).toList();
          if (logs.isEmpty) {
            return Text(
              'No recent activities.',
              style: TextStyle(color: themeService.subtextColor),
            );
          }
          return Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: themeService.inputBorderColor,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < logs.length; i++) ...[
                  if (i > 0) const Divider(height: 16),
                  _buildActivityLogRow(logs[i], themeService),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  static Widget _buildActivityLogRow(ActivityLog log, ThemeLanguageService themeService) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.bolt_rounded,
            color: AppColors.primary,
            size: 16.w,
          ),
        ),
        10.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: themeService.textColor,
                ),
              ),
              2.verticalSpace,
              Text(
                log.description,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: themeService.subtextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaffDashboardView extends StatelessWidget {
  const _StaffDashboardView();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final db = Get.find<DatabaseService>();
    final themeService = Get.find<ThemeLanguageService>();
    final nav = Get.find<BottomNavigationController>();
    return DashboardScreen._buildStaffDashboard(
      context,
      auth,
      db,
      themeService,
      nav,
    );
  }
}

class _ManagerDashboardView extends StatelessWidget {
  const _ManagerDashboardView();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final db = Get.find<DatabaseService>();
    final controller = Get.find<DashboardController>();
    final themeService = Get.find<ThemeLanguageService>();
    final nav = Get.find<BottomNavigationController>();
    return DashboardScreen._buildManagerDashboard(
      context,
      auth,
      db,
      controller,
      themeService,
      nav,
    );
  }
}

class _OwnerDashboardView extends StatelessWidget {
  const _OwnerDashboardView();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final db = Get.find<DatabaseService>();
    final controller = Get.find<DashboardController>();
    final themeService = Get.find<ThemeLanguageService>();
    final nav = Get.find<BottomNavigationController>();
    return DashboardScreen._buildOwnerDashboard(
      context,
      auth,
      db,
      controller,
      themeService,
      nav,
    );
  }
}
