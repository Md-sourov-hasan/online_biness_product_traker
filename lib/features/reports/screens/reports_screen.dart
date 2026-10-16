import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../../../core/services/theme_language_service.dart';
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Export Action Card
            _buildExportActionsCard(controller, themeService),
            20.verticalSpace,

            // 2. Weekly Revenue Comparison Chart
            Text(
              'weekly_revenue'.tr,
              style: getTextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: themeService.textColor,
              ),
            ),
            12.verticalSpace,
            _buildWeeklyBarChart(controller, themeService),
            24.verticalSpace,

            // 3. Brand Performance Statistics
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

            // 4. Expense Category Breakdown Pie Chart
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
      ),
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
            children: [
              Icon(Icons.file_download_rounded, color: AppColors.primary, size: 20.w),
              8.horizontalSpace,
              Text(
                'Professional Business Reports',
                style: getTextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: themeService.textColor,
                ),
              ),
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

  // --- 2. Weekly Bar Chart ---
  Widget _buildWeeklyBarChart(ReportsController controller, ThemeLanguageService themeService) {
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
          maxY: 40000,
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
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final text = (value.toInt() >= 0 && value.toInt() < days.length) ? days[value.toInt()] : '';
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
            horizontalInterval: 10000,
            getDrawingHorizontalLine: (value) => FlLine(color: themeService.inputBorderColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            _buildBar(0, 11500),
            _buildBar(1, 23000),
            _buildBar(2, 8700),
            _buildBar(3, 34500),
            _buildBar(4, 18000),
            _buildBar(5, 29000),
            _buildBar(6, 15000),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: 14.w,
          borderRadius: BorderRadius.circular(4.r),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 40000,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // --- 3. Brand Performance List ---
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

  // --- 4. Expense Distribution Card ---
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
