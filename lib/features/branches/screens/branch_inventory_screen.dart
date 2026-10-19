import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/models/branch_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../routes/app_routes.dart';
import '../controllers/branches_controller.dart';
import '../widgets/transfer_stock_dialog.dart';

class BranchInventoryScreen extends StatefulWidget {
  final Branch branch;

  const BranchInventoryScreen({super.key, required this.branch});

  @override
  State<BranchInventoryScreen> createState() => _BranchInventoryScreenState();
}

class _BranchInventoryScreenState extends State<BranchInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedBrand = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BranchesController controller = Get.find<BranchesController>();
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final PermissionService perm = Get.find<PermissionService>();
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
            Row(
              children: [
                Text(
                  '${widget.branch.name} Inventory',
                  style: getTextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: themeService.textColor,
                  ),
                ),
                if (widget.branch.banglaName.isNotEmpty) ...[
                  6.horizontalSpace,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: widget.branch.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      widget.branch.banglaName,
                      style: getTextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: widget.branch.color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              widget.branch.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getTextStyle(
                fontSize: 11.sp,
                color: themeService.subtextColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: widget.branch.color, size: 26.w),
            tooltip: 'Add Product to this Branch',
            onPressed: () {
              context.push(
                AppRoute.addEditProductScreen,
                extra: Product(
                  id: '',
                  brandName: '',
                  catalogName: '',
                  productCode: '',
                  quantity: 1,
                  pricePerPiece: 0,
                  branchName: widget.branch.name,
                ),
              );
            },
          ),
          8.horizontalSpace,
        ],
      ),
      body: Column(
        children: [
          // 1. Branch Metrics Ribbon (Reactive)
          Obx(() {
            final unitStocks = controller.db.getBranchUnitStocks(widget.branch.name);
            final valuation = controller.db.getBranchValuation(widget.branch.name);
            final skus = controller.db.getBranchSkus(widget.branch.name);
            final lowStock = controller.db.getBranchLowStockCount(widget.branch.name);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: widget.branch.color.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: widget.branch.color.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Unit Stocks
                  Expanded(
                    child: _buildHeaderMetric(
                      label: 'Unit Stocks',
                      value: '$unitStocks',
                      icon: Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      themeService: themeService,
                    ),
                  ),
                  Container(width: 1, height: 35.h, color: Colors.grey.withValues(alpha: 0.2)),
                  // Total Valuation
                  Expanded(
                    flex: 12,
                    child: _buildHeaderMetric(
                      label: 'Valuation',
                      value: '৳${currencyFormatter.format(valuation.toInt())}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.secondary,
                      themeService: themeService,
                    ),
                  ),
                  Container(width: 1, height: 35.h, color: Colors.grey.withValues(alpha: 0.2)),
                  // SKUs
                  Expanded(
                    child: _buildHeaderMetric(
                      label: 'SKUs',
                      value: '$skus',
                      icon: Icons.category_rounded,
                      color: AppColors.purple,
                      themeService: themeService,
                    ),
                  ),
                  if (lowStock > 0) ...[
                    Container(width: 1, height: 35.h, color: Colors.grey.withValues(alpha: 0.2)),
                    Expanded(
                      child: _buildHeaderMetric(
                        label: 'Low Stock',
                        value: '$lowStock',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.error,
                        themeService: themeService,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          // 2. Search & Brand Filter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: Container(
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: getTextStyle(fontSize: 13.sp, color: themeService.textColor),
                decoration: InputDecoration(
                  hintText: 'Search in ${widget.branch.name} inventory...',
                  hintStyle: getTextStyle(fontSize: 12.sp, color: themeService.subtextColor),
                  prefixIcon: Icon(Icons.search_rounded, size: 20.w, color: themeService.subtextColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 18.w, color: themeService.subtextColor),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                ),
              ),
            ),
          ),

          // 3. Brand Filter Chips
          Obx(() {
            final branchProducts = controller.db.getBranchProducts(widget.branch.name);
            final brands = ['All', ...branchProducts.map((p) => p.brandName).toSet()];

            if (brands.length <= 2) return const SizedBox.shrink();

            return Container(
              height: 38.h,
              margin: EdgeInsets.only(top: 4.h, bottom: 8.h),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: brands.length,
                separatorBuilder: (context, index) => 8.horizontalSpace,
                itemBuilder: (context, idx) {
                  final brand = brands[idx];
                  final isSelected = _selectedBrand == brand;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedBrand = brand),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.branch.color
                            : themeService.cardColor,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? widget.branch.color
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        brand,
                        style: getTextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : themeService.textColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),

          // 4. Products List
          Expanded(
            child: Obx(() {
              final products = controller.getProductsForBranch(
                widget.branch.name,
                query: _searchQuery,
                selectedBrand: _selectedBrand,
              );

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 54.w, color: themeService.subtextColor),
                      12.verticalSpace,
                      Text(
                        'No products found in ${widget.branch.name}',
                        style: getTextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: themeService.textColor,
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        'Tap the + button to add products to this branch',
                        style: getTextStyle(
                          fontSize: 12.sp,
                          color: themeService.subtextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 80.h),
                itemCount: products.length,
                separatorBuilder: (context, index) => 12.verticalSpace,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isLowStock = product.quantity <= product.lowStockThreshold;
                  final totalItemValuation = product.quantity * product.pricePerPiece;

                  return Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isLowStock
                            ? AppColors.warning.withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Brand & SKU Badge, Quantity Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: widget.branch.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    product.brandName,
                                    style: getTextStyle(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: widget.branch.color,
                                    ),
                                  ),
                                ),
                                6.horizontalSpace,
                                Text(
                                  product.productCode,
                                  style: getTextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: themeService.subtextColor,
                                  ),
                                ),
                              ],
                            ),
                            // Stock badge
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: isLowStock
                                    ? AppColors.error.withValues(alpha: 0.12)
                                    : AppColors.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                    size: 12.w,
                                    color: isLowStock ? AppColors.error : AppColors.secondary,
                                  ),
                                  4.horizontalSpace,
                                  Text(
                                    '${product.quantity} units',
                                    style: getTextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isLowStock ? AppColors.error : AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        10.verticalSpace,

                        // Product Title
                        Text(
                          product.displayName,
                          style: getTextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: themeService.textColor,
                          ),
                        ),
                        10.verticalSpace,

                        // Financial breakdown: Unit Cost, Selling Price, Line Valuation
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: themeService.inputFillColor,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cost Price',
                                    style: getTextStyle(fontSize: 10.sp, color: themeService.subtextColor),
                                  ),
                                  2.verticalSpace,
                                  Text(
                                    '৳${product.pricePerPiece.toStringAsFixed(0)}',
                                    style: getTextStyle(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: themeService.textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selling Price',
                                    style: getTextStyle(fontSize: 10.sp, color: themeService.subtextColor),
                                  ),
                                  2.verticalSpace,
                                  Text(
                                    '৳${product.sellingPrice.toStringAsFixed(0)}',
                                    style: getTextStyle(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Line Valuation',
                                    style: getTextStyle(fontSize: 10.sp, color: themeService.subtextColor),
                                  ),
                                  2.verticalSpace,
                                  Text(
                                    '৳${currencyFormatter.format(totalItemValuation.toInt())}',
                                    style: getTextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        12.verticalSpace,

                        // Action Buttons: Edit, Quick +/- Stock, Transfer
                        Row(
                          children: [
                            // Quick Quantity Incrementor
                            Container(
                              decoration: BoxDecoration(
                                color: themeService.cardColor,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: product.quantity > 0
                                        ? () => controller.adjustProductQuantity(product.id, -1)
                                        : null,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      child: Icon(Icons.remove, size: 16.w, color: themeService.textColor),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                                    child: Text(
                                      '${product.quantity}',
                                      style: getTextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: themeService.textColor,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => controller.adjustProductQuantity(product.id, 1),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      child: Icon(Icons.add, size: 16.w, color: themeService.textColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            8.horizontalSpace,

                            // Transfer Stock Button
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                ),
                                icon: Icon(Icons.swap_horiz_rounded, size: 15.w, color: AppColors.primary),
                                label: Text(
                                  'Transfer',
                                  style: getTextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                onPressed: () {
                                  TransferStockDialog.show(
                                    context: context,
                                    product: product,
                                    sourceBranchName: widget.branch.name,
                                    availableBranches: controller.db.branches,
                                  );
                                },
                              ),
                            ),
                            8.horizontalSpace,

                            // Edit Product Button
                            if (perm.canManageInventory)
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 18.w, color: themeService.subtextColor),
                                tooltip: 'Edit Product',
                                onPressed: () {
                                  context.push(
                                    AppRoute.addEditProductScreen,
                                    extra: product,
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeLanguageService themeService,
  }) {
    return Column(
      children: [
        Icon(icon, size: 15.w, color: color),
        4.verticalSpace,
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: getTextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: themeService.textColor,
            ),
          ),
        ),
        Text(
          label,
          style: getTextStyle(
            fontSize: 9.sp,
            color: themeService.subtextColor,
          ),
        ),
      ],
    );
  }
}
