import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/models/branch_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../controllers/branches_controller.dart';

class TransferStockDialog extends StatefulWidget {
  final Product product;
  final String sourceBranchName;
  final List<Branch> availableBranches;

  const TransferStockDialog({
    super.key,
    required this.product,
    required this.sourceBranchName,
    required this.availableBranches,
  });

  static Future<void> show({
    required BuildContext context,
    required Product product,
    required String sourceBranchName,
    required List<Branch> availableBranches,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TransferStockDialog(
        product: product,
        sourceBranchName: sourceBranchName,
        availableBranches: availableBranches,
      ),
    );
  }

  @override
  State<TransferStockDialog> createState() => _TransferStockDialogState();
}

class _TransferStockDialogState extends State<TransferStockDialog> {
  late String _selectedTargetBranch;
  int _transferQuantity = 1;

  @override
  void initState() {
    super.initState();
    final otherBranches = widget.availableBranches
        .where((b) => b.name.toLowerCase() != widget.sourceBranchName.toLowerCase())
        .toList();

    _selectedTargetBranch = otherBranches.isNotEmpty ? otherBranches.first.name : '';
    if (widget.product.quantity > 0) {
      _transferQuantity = 1;
    } else {
      _transferQuantity = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeLanguageService>();
    final controller = Get.find<BranchesController>();

    final otherBranches = widget.availableBranches
        .where((b) => b.name.toLowerCase() != widget.sourceBranchName.toLowerCase())
        .toList();

    final maxAvailable = widget.product.quantity;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: themeService.cardColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                          size: 20.w,
                        ),
                      ),
                      10.horizontalSpace,
                      Text(
                        'Transfer Stock',
                        style: getTextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: themeService.textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20.w, color: themeService.subtextColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              16.verticalSpace,

              // Product Info Card
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: themeService.inputFillColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          widget.product.brandName.isNotEmpty
                              ? widget.product.brandName.substring(0, 1).toUpperCase()
                              : 'P',
                          style: getTextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: getTextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: themeService.textColor,
                            ),
                          ),
                          4.verticalSpace,
                          Row(
                            children: [
                              Text(
                                'Code: ${widget.product.productCode}',
                                style: getTextStyle(
                                  fontSize: 11.sp,
                                  color: themeService.subtextColor,
                                ),
                              ),
                              8.horizontalSpace,
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  '$maxAvailable in ${widget.sourceBranchName}',
                                  style: getTextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
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
              18.verticalSpace,

              // Source and Destination Branch Route Visual
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From Branch',
                          style: getTextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: themeService.subtextColor,
                          ),
                        ),
                        6.verticalSpace,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: themeService.inputFillColor,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.store_rounded, size: 16.w, color: AppColors.primary),
                              6.horizontalSpace,
                              Expanded(
                                child: Text(
                                  widget.sourceBranchName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: getTextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: themeService.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  12.horizontalSpace,
                  Padding(
                    padding: EdgeInsets.only(top: 18.h),
                    child: Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20.w),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To Target Branch',
                          style: getTextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: themeService.subtextColor,
                          ),
                        ),
                        6.verticalSpace,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          decoration: BoxDecoration(
                            color: themeService.inputFillColor,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTargetBranch.isNotEmpty ? _selectedTargetBranch : null,
                              isExpanded: true,
                              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18.w, color: AppColors.primary),
                              dropdownColor: themeService.cardColor,
                              items: otherBranches.map((b) {
                                return DropdownMenuItem<String>(
                                  value: b.name,
                                  child: Row(
                                    children: [
                                      Icon(Icons.storefront_rounded, size: 14.w, color: b.color),
                                      6.horizontalSpace,
                                      Expanded(
                                        child: Text(
                                          b.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: getTextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: themeService.textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedTargetBranch = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              20.verticalSpace,

              // Quantity Selector
              Text(
                'Transfer Quantity (Units)',
                style: getTextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: themeService.textColor,
                ),
              ),
              8.verticalSpace,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: themeService.inputFillColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline_rounded,
                          color: _transferQuantity > 1 ? AppColors.error : Colors.grey,
                          size: 26.w),
                      onPressed: _transferQuantity > 1
                          ? () => setState(() => _transferQuantity--)
                          : null,
                    ),
                    Column(
                      children: [
                        Text(
                          '$_transferQuantity',
                          style: getTextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: themeService.textColor,
                          ),
                        ),
                        Text(
                          'of $maxAvailable available',
                          style: getTextStyle(
                            fontSize: 10.sp,
                            color: themeService.subtextColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline_rounded,
                          color: _transferQuantity < maxAvailable ? AppColors.secondary : Colors.grey,
                          size: 26.w),
                      onPressed: _transferQuantity < maxAvailable
                          ? () => setState(() => _transferQuantity++)
                          : null,
                    ),
                  ],
                ),
              ),
              24.verticalSpace,

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: getTextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: themeService.subtextColor,
                        ),
                      ),
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      onPressed: maxAvailable > 0 && _selectedTargetBranch.isNotEmpty
                          ? () {
                              final success = controller.transferBranchStock(
                                productId: widget.product.id,
                                targetBranch: _selectedTargetBranch,
                                transferQty: _transferQuantity,
                              );
                              Navigator.of(context).pop();
                              if (success) {
                                Get.snackbar(
                                  'Transfer Successful 🚚',
                                  '$_transferQuantity units of ${widget.product.displayName} transferred to $_selectedTargetBranch',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.secondary,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 3),
                                );
                              } else {
                                Get.snackbar(
                                  'Transfer Failed',
                                  'Unable to complete stock transfer',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.error,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          : null,
                      child: Text(
                        'Confirm Transfer',
                        style: getTextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
