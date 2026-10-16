import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/reports_controller.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController controller = Get.put(ReportsController());
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final PermissionService perm = Get.find<PermissionService>();

    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'reports_title'.tr,
          style: getTextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        actions: [
          if (perm.canExportReports) ...[
            IconButton(
              icon: Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24.w),
              tooltip: 'export_pdf'.tr,
              onPressed: () => controller.exportPdf(),
            ),
            IconButton(
              icon: Icon(Icons.table_chart_rounded, color: AppColors.secondary, size: 24.w),
              tooltip: 'export_csv'.tr,
              onPressed: () => controller.exportCsv(),
            ),
            8.horizontalSpace,
          ],
        ],
        elevation: 0,
      ),
      body: Obx(() {
        if (!perm.canViewFinancialMetrics) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_person_rounded, size: 56.w, color: AppColors.error),
                  16.verticalSpace,
                  Text(
                    'Financial Reports Restricted',
                    style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
                  ),
                  8.verticalSpace,
                  Text(
                    'Under Section 6 (Role-Based Access Control), Staff accounts do not have permission to view store margins, COGS, or business profit reports.',
                    textAlign: TextAlign.center,
                    style: getTextStyle(fontSize: 13.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Export Action Card & Statement Selector
              _buildExportActionsCard(controller, themeService),
              16.verticalSpace,

              // 2. Spec Section 9 Accounting Breakdown Card
              _buildAccountingBridgeCard(controller, themeService),
              20.verticalSpace,

              // 3. 7-Day Revenue Bar Chart
              Text(
                'weekly_revenue'.tr,
                style: getTextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: themeService.textColor,
                ),
              ),
              12.verticalSpace,
              _buildDynamicWeeklyBarChart(controller, themeService),
              24.verticalSpace,

              // 4. Brand Performance Statistics
              Text(
                'brand_performance'.tr,
                style: getTextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: themeService.textColor,
                ),
              ),
              12.verticalSpace,
              _buildBrandPerformanceList(controller, themeService),
              24.verticalSpace,

              // 5. Expense Distribution Breakdown
              Text(
                'expense_distribution'.tr,
                style: getTextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: themeService.textColor,
                ),
              ),
              12.verticalSpace,
              _buildExpenseDistributionCard(controller, themeService),
              80.verticalSpace,
            ],
          ),
        );
      }),
    );
  }

  // --- 1. Export Action Card ---
  Widget _buildExportActionsCard(ReportsController controller, ThemeLanguageService themeService) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
              Row(
                children: [
                  Icon(Icons.file_download_rounded, color: AppColors.primary, size: 20.w),
                  8.horizontalSpace,
                  Text(
                    'Export Business Reports',
                    style: getTextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: themeService.textColor,
                    ),
                  ),
                ],
              ),
              // Report Type Selector
              Obx(() => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedReportType.value,
                      dropdownColor: themeService.cardColor,
                      style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.w700),
                      items: const [
                        DropdownMenuItem(value: 'pl', child: Text('P&L Statement')),
                        DropdownMenuItem(value: 'sales', child: Text('Sales Report')),
                        DropdownMenuItem(value: 'inventory', child: Text('Inventory Report')),
                      ],
                      onChanged: (val) {
                        if (val != null) controller.selectedReportType.value = val;
                      },
                    ),
                  )),
            ],
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.exportPdf(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                  label: Text('export_pdf'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.exportCsv(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  icon: const Icon(Icons.table_view_rounded, size: 18),
                  label: Text('export_csv'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Spec Section 9 Accounting Breakdown Bridge Card ---
  Widget _buildAccountingBridgeCard(ReportsController controller, ThemeLanguageService themeService) {
    return Obx(() {
      final grossSales = controller.db.totalGrossSales;
      final discounts = controller.db.totalAuthorizedDiscounts;
      final refunds = controller.db.totalRefunds;
      final netRevenue = controller.db.totalRevenue;
      final cogs = controller.db.totalCOGS;
      final grossProfit = controller.db.totalGrossProfit;
      final opEx = controller.db.totalExpenses;
      final loanInterest = controller.db.totalLoanInterestExpenses;
      final netProfit = controller.db.netProfit;
      final netMargin = netRevenue > 0 ? (netProfit / netRevenue) * 100 : 0.0;

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Engine Breakdown (Spec Sec 9)',
                  style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: (netProfit >= 0 ? AppColors.secondary : AppColors.error).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Margin: ${netMargin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: netProfit >= 0 ? AppColors.secondary : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            12.verticalSpace,
            _buildBridgeRow('Gross Sales', '৳${grossSales.toStringAsFixed(0)}', AppColors.primary, false, themeService),
            _buildBridgeRow('Less: Authorized Discounts', '- ৳${discounts.toStringAsFixed(0)}', AppColors.warning, false, themeService),
            _buildBridgeRow('Less: Returns & Refunds', '- ৳${refunds.toStringAsFixed(0)}', AppColors.error, false, themeService),
            Divider(color: themeService.inputBorderColor, height: 16.h),
            _buildBridgeRow('Net Sales (Revenue)', '৳${netRevenue.toStringAsFixed(0)}', AppColors.primary, true, themeService),
            _buildBridgeRow('Less: COGS (WAC Inventory Cost)', '- ৳${cogs.toStringAsFixed(0)}', themeService.subtextColor, false, themeService),
            Divider(color: themeService.inputBorderColor, height: 16.h),
            _buildBridgeRow('Gross Profit', '৳${grossProfit.toStringAsFixed(0)}', const Color(0xFF10B981), true, themeService),
            _buildBridgeRow('Less: Operating Expenses (Courier/Rent)', '- ৳${opEx.toStringAsFixed(0)}', AppColors.error, false, themeService),
            if (loanInterest > 0)
              _buildBridgeRow('Less: Loan Interest Expense', '- ৳${loanInterest.toStringAsFixed(0)}', AppColors.error, false, themeService),
            Divider(color: themeService.inputBorderColor, height: 16.h),
            _buildBridgeRow(
              'NET BUSINESS PROFIT',
              '৳${netProfit.toStringAsFixed(0)}',
              netProfit >= 0 ? AppColors.secondary : AppColors.error,
              true,
              themeService,
              fontSize: 15.sp,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBridgeRow(
    String label,
    String value,
    Color color,
    bool isBold,
    ThemeLanguageService themeService, {
    double? fontSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: getTextStyle(
              fontSize: fontSize ?? (isBold ? 13.sp : 12.sp),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? themeService.textColor : themeService.subtextColor,
            ),
          ),
          Text(
            value,
            style: getTextStyle(
              fontSize: fontSize ?? (isBold ? 14.sp : 12.sp),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Dynamic Weekly Bar Chart ---
  Widget _buildDynamicWeeklyBarChart(ReportsController controller, ThemeLanguageService themeService) {
    return Obx(() {
      final sales = controller.db.sales;
      // Calculate daily sales for last 7 days
      final now = DateTime.now();
      final List<double> dayTotals = List.filled(7, 0.0);
      final List<String> dayLabels = [];

      for (int i = 6; i >= 0; i--) {
        final dayDate = now.subtract(Duration(days: i));
        dayLabels.add(DateFormat('E').format(dayDate));
        final daySales = sales.where((s) {
          return s.timestamp.year == dayDate.year &&
              s.timestamp.month == dayDate.month &&
              s.timestamp.day == dayDate.day;
        }).fold(0.0, (sum, s) => sum + s.totalPrice);
        dayTotals[6 - i] = daySales;
      }

      final maxVal = dayTotals.reduce((curr, next) => curr > next ? curr : next);
      final chartMax = (maxVal > 0 ? (maxVal * 1.3) : 10000.0).clamp(5000.0, 1000000.0);

      return Container(
        height: 220.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: chartMax,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '৳${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final idx = value.toInt();
                    final text = (idx >= 0 && idx < dayLabels.length) ? dayLabels[idx] : '';
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(text, style: TextStyle(color: themeService.subtextColor, fontSize: 10.sp, fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: chartMax / 4,
              getDrawingHorizontalLine: (value) => FlLine(color: themeService.inputBorderColor, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: dayTotals[i],
                    color: AppColors.primary,
                    width: 14.w,
                    borderRadius: BorderRadius.circular(4.r),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: chartMax,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    });
  }

  // --- 4. Brand Performance List ---
  Widget _buildBrandPerformanceList(ReportsController controller, ThemeLanguageService themeService) {
    return Obx(() {
      final brands = controller.db.allBrands;
      if (brands.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: brands.take(4).map((b) {
          final productsInBrand = controller.db.products.where((p) => p.brandName == b).toList();
          final totalUnits = productsInBrand.fold(0, (sum, p) => sum + p.quantity);
          final valuation = productsInBrand.fold(0.0, (sum, p) => sum + p.totalPrice);

          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18.w,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          b.isNotEmpty ? b[0].toUpperCase() : 'B',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14.sp),
                        ),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b, maxLines: 1, overflow: TextOverflow.ellipsis, style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                            2.verticalSpace,
                            Text('$totalUnits units in inventory', maxLines: 1, overflow: TextOverflow.ellipsis, style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                8.horizontalSpace,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '৳${valuation.toStringAsFixed(0)}',
                    style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  // --- 5. Expense Distribution Card ---
  Widget _buildExpenseDistributionCard(ReportsController controller, ThemeLanguageService themeService) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Obx(() {
        final expenses = controller.db.expenses;
        if (expenses.isEmpty) {
          return Center(
            child: Text('No expenses recorded', style: TextStyle(color: themeService.subtextColor)),
          );
        }

        final Map<String, double> catTotals = {};
        for (var e in expenses) {
          catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
        }

        final totalExp = controller.db.totalExpenses;

        return Column(
          children: catTotals.entries.map((entry) {
            final percentage = totalExp > 0 ? (entry.value / totalExp) * 100 : 0.0;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: getTextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                      Text('৳${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)', style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.error)),
                    ],
                  ),
                  6.verticalSpace,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: themeService.inputFillColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
                      minHeight: 6.h,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}
