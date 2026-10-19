import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/models/branch_model.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';

class BranchCard extends StatelessWidget {
  final Branch branch;
  final int unitStocks;
  final double totalValuation;
  final int branchSkus;
  final int lowStockCount;
  final VoidCallback onTap;

  const BranchCard({
    super.key,
    required this.branch,
    required this.unitStocks,
    required this.totalValuation,
    required this.branchSkus,
    this.lowStockCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##,###');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: branch.color.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: branch.color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Accent Strip & Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      branch.color.withValues(alpha: 0.12),
                      branch.color.withValues(alpha: 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: branch.color.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  branch.color,
                                  branch.color.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: branch.color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 24.w,
                              ),
                            ),
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        branch.name,
                                        style: getTextStyle(
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (branch.banglaName.isNotEmpty) ...[
                                      6.horizontalSpace,
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: branch.color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          branch.banglaName,
                                          style: getTextStyle(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w600,
                                            color: branch.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                3.verticalSpace,
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 13.w,
                                      color: AppColors.textSecondary,
                                    ),
                                    4.horizontalSpace,
                                    Expanded(
                                      child: Text(
                                        branch.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: getTextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    10.horizontalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: branch.isActive
                            ? AppColors.secondary.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: branch.isActive
                              ? AppColors.secondary.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              color: branch.isActive ? AppColors.secondary : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          5.horizontalSpace,
                          Text(
                            branch.isActive ? 'Active' : 'Offline',
                            style: getTextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: branch.isActive ? AppColors.secondary : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Metric Display: Unit Stocks, Total Valuation, Branch SKUs
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // 1. Unit Stocks
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Unit Stocks',
                            value: '$unitStocks',
                            subValue: 'Pieces',
                            icon: Icons.inventory_2_rounded,
                            accentColor: AppColors.primary,
                          ),
                        ),
                        10.horizontalSpace,
                        // 2. Total Valuation
                        Expanded(
                          flex: 12,
                          child: _buildMetricTile(
                            label: 'Total Valuation',
                            value: '৳${currencyFormatter.format(totalValuation.toInt())}',
                            subValue: 'Asset Value',
                            icon: Icons.account_balance_wallet_rounded,
                            accentColor: AppColors.secondary,
                            isHighlighted: true,
                          ),
                        ),
                        10.horizontalSpace,
                        // 3. Branch SKUs
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Branch SKUs',
                            value: '$branchSkus',
                            subValue: 'Products',
                            icon: Icons.category_rounded,
                            accentColor: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                    14.verticalSpace,

                    // Manager & Action Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12.r,
                              backgroundColor: AppColors.backgroundNeutral,
                              child: Icon(
                                Icons.person_rounded,
                                size: 14.w,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            6.horizontalSpace,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.managerName,
                                  style: getTextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  branch.managerPhone,
                                  style: getTextStyle(
                                    fontSize: 9.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: branch.color,
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: branch.color.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Inventory',
                                style: getTextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              4.horizontalSpace,
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12.w,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    required Color accentColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isHighlighted
            ? accentColor.withValues(alpha: 0.08)
            : AppColors.backgroundNeutral,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isHighlighted
              ? accentColor.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13.w, color: accentColor),
              4.horizontalSpace,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getTextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? accentColor : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          6.verticalSpace,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: getTextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: isHighlighted ? accentColor : AppColors.textPrimary,
              ),
            ),
          ),
          2.verticalSpace,
          Text(
            subValue,
            style: getTextStyle(
              fontSize: 9.sp,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
