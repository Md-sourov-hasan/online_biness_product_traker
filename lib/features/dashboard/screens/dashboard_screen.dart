import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';
import '../../bottom_navigation/controllers/bottom_navigation_controller.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.put(DashboardController());
    final DatabaseService db = Get.find<DatabaseService>();
    final AuthService auth = Get.find<AuthService>();
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final BottomNavigationController nav = Get.find<BottomNavigationController>();

    return CommonBackgroundScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Store / User Info & Cloud Sync Indicator
              _buildHeader(context, auth, db, themeService),
              20.verticalSpace,

              // 1. Product Quantity & Valuation Card
              _buildProductQuantityCard(db, themeService, nav),
              16.verticalSpace,

              // 2. 5-Second Rotating Sales & Profit Cards (Side by Side)
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildRotatingMetricCard(
                          title: controller.currentSalesLabelKey.tr,
                          value: '৳${controller.currentPeriodSales.toStringAsFixed(0)}',
                          subtitle: 'Tap to cycle',
                          icon: Icons.trending_up_rounded,
                          accentColor: AppColors.primary,
                          onTap: controller.cycleSalesRotation,
                          themeService: themeService,
                          tag: controller.currentSalesPeriod.toUpperCase(),
                        )),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Obx(() => _buildRotatingMetricCard(
                          title: controller.currentProfitLabelKey.tr,
                          value: '৳${controller.currentPeriodProfit.toStringAsFixed(0)}',
                          subtitle: 'Tap to cycle',
                          icon: Icons.auto_graph_rounded,
                          accentColor: AppColors.secondary,
                          onTap: controller.cycleProfitRotation,
                          themeService: themeService,
                          tag: controller.currentProfitPeriod.toUpperCase(),
                        )),
                  ),
                ],
              ),
              16.verticalSpace,

              // 3. Financial Balance Summary (Revenue, Expense, Net Profit)
              _buildFinancialSummaryRow(db, themeService),
              24.verticalSpace,

              // 4. Quick Action Buttons
              Text(
                'quick_actions'.tr,
                style: getTextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: themeService.textColor,
                ),
              ),
              14.verticalSpace,
              _buildQuickActionsGrid(context, nav, themeService),
              24.verticalSpace,

              // 5. Active Low Stock Alerts Section
              _buildLowStockSection(db, context, themeService),
              24.verticalSpace,

              // 6. Recent Activity Timeline
              _buildRecentActivitySection(db, themeService),
              80.verticalSpace, // Spacing for bottom navbar
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Header Section with Cloud Sync Indicator ---
  Widget _buildHeader(
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
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Obx(() => Text(
                          auth.currentUser.value?.role ?? 'Staff',
                          style: getTextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        )),
                  ),
                ],
              ),
              4.verticalSpace,
              Obx(() => Text(
                    '${'welcome_back'.tr} ${auth.currentUser.value?.name ?? 'User'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getTextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: themeService.subtextColor,
                    ),
                  )),
            ],
          ),
        ),
        8.horizontalSpace,
        // Cloud Sync Indicator Button
        Obx(() {
          final isSyncing = db.isSyncing.value;
          return GestureDetector(
            onTap: () => _showCloudSyncDialog(context, db, themeService),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSyncing ? AppColors.warning : AppColors.secondary.withValues(alpha: 0.5),
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
                  Container(
                    width: 7.w,
                    height: 7.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSyncing ? AppColors.warning : AppColors.secondary,
                    ),
                  ),
                  4.horizontalSpace,
                  Icon(
                    isSyncing ? Icons.sync_rounded : Icons.cloud_done_rounded,
                    size: 14.w,
                    color: isSyncing ? AppColors.warning : AppColors.secondary,
                  ),
                  4.horizontalSpace,
                  Text(
                    isSyncing ? 'Syncing...' : 'Synced',
                    style: getTextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isSyncing ? AppColors.warning : AppColors.secondary,
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

  // --- 2. Product Quantity & Valuation Summary Card ---
  Widget _buildProductQuantityCard(
    DatabaseService db,
    ThemeLanguageService themeService,
    BottomNavigationController nav,
  ) {
    return Obx(() {
      final totalPieces = db.totalStockPieces;
      final totalValuation = db.totalStockValuation;
      final catalogCount = db.products.length;
      final brandCount = db.allBrands.length;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
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
                        child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18.w),
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
                  onTap: () => nav.changeTab(1),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: getTextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white, size: 14.w),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            14.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalPieces pcs',
                        style: getTextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        '${'stock_valuation'.tr}: ৳${totalValuation.toStringAsFixed(0)}',
                        style: getTextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '$catalogCount Items • $brandCount Brands',
                    style: getTextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // --- 3. Rotating Metric Card (Auto-rotates every 5s) ---
  Widget _buildRotatingMetricCard({
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
            4.verticalSpace,
            Row(
              children: [
                Icon(Icons.refresh_rounded, size: 10.w, color: themeService.subtextColor),
                4.horizontalSpace,
                Text(
                  'Auto 5s',
                  style: getTextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w400,
                    color: themeService.subtextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Financial Balance Summary (Revenue, Expense, Net Profit) ---
  Widget _buildFinancialSummaryRow(DatabaseService db, ThemeLanguageService themeService) {
    return Obx(() {
      final revenue = db.totalRevenue;
      final expenses = db.totalExpenses;
      final netProfit = db.netProfit;

      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildFinancialItem(
                'total_revenue'.tr,
                '৳${revenue.toStringAsFixed(0)}',
                AppColors.primary,
                themeService,
              ),
            ),
            Container(width: 1, height: 36.h, color: themeService.inputBorderColor),
            Expanded(
              child: _buildFinancialItem(
                'total_expenses'.tr,
                '৳${expenses.toStringAsFixed(0)}',
                AppColors.error,
                themeService,
              ),
            ),
            Container(width: 1, height: 36.h, color: themeService.inputBorderColor),
            Expanded(
              child: _buildFinancialItem(
                'net_profit'.tr,
                '৳${netProfit.toStringAsFixed(0)}',
                netProfit >= 0 ? AppColors.secondary : AppColors.error,
                themeService,
                isBold: true,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFinancialItem(
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
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: getTextStyle(
            fontSize: 14.sp,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- 5. Quick Actions Grid ---
  Widget _buildQuickActionsGrid(
    BuildContext context,
    BottomNavigationController nav,
    ThemeLanguageService themeService,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildActionItem(
            'action_new_sale'.tr,
            Icons.point_of_sale_rounded,
            AppColors.primary,
            () => nav.changeTab(2), // Switch to Sales POS tab
            themeService,
          ),
        ),
        Expanded(
          child: _buildActionItem(
            'action_purchase'.tr,
            Icons.add_shopping_cart_rounded,
            AppColors.secondary,
            () => nav.changeTab(3), // Switch to Purchase/Expense tab
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
            const Color(0xFF8B5CF6),
            () => nav.changeTab(4), // Reports
            themeService,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
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

  // --- 6. Low Stock Alert Section ---
  Widget _buildLowStockSection(
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
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20.w),
                  6.horizontalSpace,
                  Expanded(
                    child: Text(
                      'low_stock_alerts'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getTextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: themeService.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() => Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: db.lowStockProducts.isNotEmpty
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '${db.lowStockProducts.length} Items',
                    style: getTextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: db.lowStockProducts.isNotEmpty ? AppColors.error : AppColors.secondary,
                    ),
                  ),
                )),
          ],
        ),
        12.verticalSpace,
        Obx(() {
          final lowStockList = db.lowStockProducts;
          if (lowStockList.isEmpty) {
            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: AppColors.secondary, size: 22.w),
                  12.horizontalSpace,
                  Expanded(
                    child: Text(
                      'all_stocked'.tr,
                      style: getTextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: themeService.subtextColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: lowStockList.take(3).map((p) {
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
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
                            style: getTextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: themeService.textColor,
                            ),
                          ),
                          2.verticalSpace,
                          Text(
                            'Code: ${p.productCode} • Cost: ৳${p.pricePerPiece.toStringAsFixed(0)}',
                            style: getTextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: themeService.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${p.quantity} ${'items_left'.tr}',
                        style: getTextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // --- 7. Recent Activity Timeline ---
  Widget _buildRecentActivitySection(DatabaseService db, ThemeLanguageService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'recent_activity'.tr,
              style: getTextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: themeService.textColor,
              ),
            ),
            Icon(Icons.history_rounded, size: 20.w, color: themeService.subtextColor),
          ],
        ),
        12.verticalSpace,
        Obx(() {
          final logs = db.activityLogs;
          if (logs.isEmpty) {
            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: Text(
                  'No recent activity recorded yet.',
                  style: getTextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: themeService.subtextColor,
                  ),
                ),
              ),
            );
          }

          return Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.take(5).length,
              separatorBuilder: (context, i) => Divider(height: 20.h, color: themeService.inputBorderColor),
              itemBuilder: (context, index) {
                final log = logs[index];
                IconData icon;
                Color iconColor;

                switch (log.type) {
                  case 'sale':
                    icon = Icons.shopping_bag_rounded;
                    iconColor = AppColors.secondary;
                    break;
                  case 'purchase':
                    icon = Icons.add_business_rounded;
                    iconColor = AppColors.primary;
                    break;
                  case 'expense':
                    icon = Icons.receipt_rounded;
                    iconColor = AppColors.error;
                    break;
                  default:
                    icon = Icons.tune_rounded;
                    iconColor = AppColors.warning;
                }

                final timeStr = DateFormat('hh:mm a • dd MMM').format(log.timestamp);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(icon, color: iconColor, size: 16.w),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log.title,
                                style: getTextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: themeService.textColor,
                                ),
                              ),
                              Text(
                                timeStr,
                                style: getTextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w400,
                                  color: themeService.subtextColor,
                                ),
                              ),
                            ],
                          ),
                          4.verticalSpace,
                          Text(
                            log.description,
                            style: getTextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: themeService.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }),
      ],
    );
  }

  // --- Cloud Sync Modal Dialog ---
  void _showCloudSyncDialog(BuildContext context, DatabaseService db, ThemeLanguageService themeService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeService.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 24.w),
            8.horizontalSpace,
            Text(
              'cloud_sync_title'.tr,
              style: getTextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'cloud_synced'.tr,
              style: getTextStyle(fontSize: 13.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
            ),
            12.verticalSpace,
            Obx(() => Text(
                  'Last Synced: ${DateFormat('dd MMM yyyy, hh:mm a').format(db.lastSyncTime.value)}',
                  style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.secondary),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr, style: TextStyle(color: themeService.subtextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await db.triggerCloudSync();
              Get.snackbar('Cloud Synced', 'All business data updated to cloud', snackPosition: SnackPosition.BOTTOM);
            },
            child: Text('sync_now'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
