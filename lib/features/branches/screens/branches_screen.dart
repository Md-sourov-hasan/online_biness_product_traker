import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../routes/app_routes.dart';
import '../controllers/branches_controller.dart';
import '../widgets/branch_card.dart';

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BranchesController controller = Get.put(BranchesController());
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final currencyFormatter = NumberFormat('#,##,###');

    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.w, color: themeService.textColor),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Store Branches',
              style: getTextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: themeService.textColor,
              ),
            ),
            Text(
              'Multi-Branch Inventory & Valuation Network',
              style: getTextStyle(
                fontSize: 11.sp,
                color: themeService.subtextColor,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Super Admin Network Overview Hero Banner
            Obx(() {
              final totalValuation = controller.totalNetworkValuation;
              final totalUnits = controller.totalNetworkStockUnits;
              final totalSkus = controller.totalNetworkSkus;
              final branchCount = controller.totalBranchesCount;

              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(7.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.hub_rounded,
                                  color: Colors.white,
                                  size: 18.w,
                                ),
                              ),
                              8.horizontalSpace,
                              Flexible(
                                child: Text(
                                  'SUPER ADMIN NETWORK',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: getTextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        8.horizontalSpace,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '$branchCount Active Outlets',
                            style: getTextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    14.verticalSpace,
                    Text(
                      '৳${currencyFormatter.format(totalValuation.toInt())}',
                      style: getTextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      'Combined Real-Time Inventory Valuation across all locations',
                      style: getTextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    16.verticalSpace,
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                    12.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: Colors.white, size: 16.w),
                              6.horizontalSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$totalUnits Units',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: getTextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Total Stock Units',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: getTextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.category_outlined, color: Colors.white, size: 16.w),
                              6.horizontalSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$totalSkus SKUs',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: getTextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Catalog Varieties',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: getTextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            20.verticalSpace,

            // 2. Search & Sort Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => controller.searchQuery.value = val,
                      style: getTextStyle(
                        fontSize: 13.sp,
                        color: themeService.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search branch name, address...',
                        hintStyle: getTextStyle(
                          fontSize: 12.sp,
                          color: themeService.subtextColor,
                        ),
                        prefixIcon: Icon(Icons.search_rounded, size: 20.w, color: themeService.subtextColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      ),
                    ),
                  ),
                ),
                10.horizontalSpace,
                // Sort Dropdown
                Obx(
                  () => Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedSort.value,
                        icon: Icon(Icons.sort_rounded, size: 18.w, color: AppColors.primary),
                        dropdownColor: themeService.cardColor,
                        items: ['Valuation', 'Stock Units', 'SKUs', 'Name'].map((s) {
                          return DropdownMenuItem<String>(
                            value: s,
                            child: Text(
                              s,
                              style: getTextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: themeService.textColor,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) controller.selectedSort.value = val;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            18.verticalSpace,

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Physical Outlets & Warehouses',
                  style: getTextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: themeService.textColor,
                  ),
                ),
                Obx(
                  () => Text(
                    '${controller.filteredBranches.length} Branches',
                    style: getTextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            14.verticalSpace,

            // 3. List of 5 Branch Cards (Bonani, Gulshan, Nikunjo, Jamgora, Savar)
            Obx(() {
              final branches = controller.filteredBranches;

              if (branches.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: Column(
                      children: [
                        Icon(Icons.store_mall_directory_outlined, size: 54.w, color: themeService.subtextColor),
                        12.verticalSpace,
                        Text(
                          'No branches found matching your search',
                          style: getTextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: themeService.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  final unitStocks = controller.db.getBranchUnitStocks(branch.name);
                  final valuation = controller.db.getBranchValuation(branch.name);
                  final skus = controller.db.getBranchSkus(branch.name);
                  final lowStockCount = controller.db.getBranchLowStockCount(branch.name);

                  return BranchCard(
                    branch: branch,
                    unitStocks: unitStocks,
                    totalValuation: valuation,
                    branchSkus: skus,
                    lowStockCount: lowStockCount,
                    onTap: () {
                      context.push(
                        AppRoute.branchInventoryScreen,
                        extra: branch,
                      );
                    },
                  );
                },
              );
            }),
            40.verticalSpace,
          ],
        ),
      ),
    );
  }
}
