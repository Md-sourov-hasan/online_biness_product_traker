import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../controllers/products_controller.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../routes/app_routes.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductsController controller = Get.put(ProductsController());
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();

    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'inventory_title'.tr,
          style: getTextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28.w),
            onPressed: () => context.push(AppRoute.addEditProductScreen),
          ),
          12.horizontalSpace,
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Stock Valuation Header Bar
          _buildValuationHeader(controller, themeService),
          12.verticalSpace,

          // 2. Search Box & View Switcher (Brand vs Flat)
          _buildSearchAndFilters(controller, themeService),
          12.verticalSpace,

          // 3. Product Listing (Brand-grouped or Flat)
          Expanded(
            child: Obx(() {
              if (controller.filteredProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 54.w, color: themeService.subtextColor),
                      12.verticalSpace,
                      Text(
                        'No products found matching your filter.\nTap + to add new product.',
                        textAlign: TextAlign.center,
                        style: getTextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: themeService.subtextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (controller.isBrandView.value) {
                return _buildBrandGroupedList(controller, context, themeService);
              } else {
                return _buildFlatList(controller, context, themeService);
              }
            }),
          ),
          80.verticalSpace, // Spacing for bottom navbar
        ],
      ),
    );
  }

  // --- 1. Stock Valuation Bar ---
  Widget _buildValuationHeader(ProductsController controller, ThemeLanguageService themeService) {
    return Obx(() {
      final totalValuation = controller.totalStockValue;
      final totalUnits = controller.db.totalStockPieces;
      final totalBrands = controller.db.allBrands.length;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'stock_valuation'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getTextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: themeService.subtextColor,
                    ),
                  ),
                  4.verticalSpace,
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '৳${totalValuation.toStringAsFixed(0)}',
                      style: getTextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            8.horizontalSpace,
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: [
                _buildMiniBadge('$totalUnits', 'total_units'.tr, AppColors.secondary, themeService),
                _buildMiniBadge('$totalBrands', 'brands_count'.tr, const Color(0xFF8B5CF6), themeService),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMiniBadge(String count, String label, Color color, ThemeLanguageService themeService) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: getTextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: getTextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Search & Filter Bar ---
  Widget _buildSearchAndFilters(ProductsController controller, ThemeLanguageService themeService) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: themeService.inputBorderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: themeService.subtextColor, size: 20.w),
                      8.horizontalSpace,
                      Expanded(
                        child: TextField(
                          onChanged: (val) => controller.searchQuery.value = val,
                          style: getTextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: themeService.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'search_products'.tr,
                            hintStyle: getTextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                              color: themeService.subtextColor,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Obx(() => controller.searchQuery.value.isNotEmpty
                          ? GestureDetector(
                              onTap: () => controller.searchQuery.value = '',
                              child: Icon(Icons.close_rounded, color: themeService.subtextColor, size: 16.w),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
              10.horizontalSpace,
              // View Switcher (Brand vs Flat)
              Obx(() => Container(
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: themeService.inputBorderColor),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.category_rounded,
                            size: 20.w,
                            color: controller.isBrandView.value ? AppColors.primary : themeService.subtextColor,
                          ),
                          tooltip: 'Brand View',
                          onPressed: () => controller.isBrandView.value = true,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.list_alt_rounded,
                            size: 20.w,
                            color: !controller.isBrandView.value ? AppColors.primary : themeService.subtextColor,
                          ),
                          tooltip: 'Flat List',
                          onPressed: () => controller.isBrandView.value = false,
                        ),
                      ],
                    ),
                  )),
            ],
          ),
          8.verticalSpace,
          // Brand Filter Horizontal Pills
          Obx(() {
            final brands = controller.brandList;
            return SizedBox(
              height: 32.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: brands.length,
                separatorBuilder: (c, i) => 8.horizontalSpace,
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  final isSelected = controller.selectedBrandFilter.value == brand;
                  return GestureDetector(
                    onTap: () => controller.selectedBrandFilter.value = brand,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : themeService.cardColor,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : themeService.inputBorderColor,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          brand,
                          style: getTextStyle(
                            fontSize: 12.sp,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : themeService.textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 3. Brand Grouped View ---
  Widget _buildBrandGroupedList(
    ProductsController controller,
    BuildContext context,
    ThemeLanguageService themeService,
  ) {
    final grouped = controller.groupedByBrand;

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: grouped.keys.length,
      separatorBuilder: (c, i) => 16.verticalSpace,
      itemBuilder: (context, index) {
        final brandName = grouped.keys.elementAt(index);
        final productList = grouped[brandName]!;
        final brandUnits = productList.fold(0, (sum, p) => sum + p.quantity);
        final brandValuation = productList.fold(0.0, (sum, p) => sum + p.totalPrice);

        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Group Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.label_important_rounded, color: AppColors.primary, size: 18.w),
                          8.horizontalSpace,
                          Expanded(
                            child: Text(
                              brandName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: getTextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: themeService.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    8.horizontalSpace,
                    Text(
                      '$brandUnits pcs • ৳${brandValuation.toStringAsFixed(0)}',
                      style: getTextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Products inside brand
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(12.w),
                itemCount: productList.length,
                separatorBuilder: (c, i) => Divider(height: 16.h, color: themeService.inputBorderColor),
                itemBuilder: (context, pIndex) {
                  final product = productList[pIndex];
                  return _buildProductRowItem(product, controller, context, themeService);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 4. Flat List View ---
  Widget _buildFlatList(
    ProductsController controller,
    BuildContext context,
    ThemeLanguageService themeService,
  ) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: controller.filteredProducts.length,
      separatorBuilder: (c, i) => 12.verticalSpace,
      itemBuilder: (context, index) {
        final product = controller.filteredProducts[index];
        return Container(
          padding: EdgeInsets.all(14.w),
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
          child: _buildProductRowItem(product, controller, context, themeService),
        );
      },
    );
  }

  // --- Product Row Item with Quick Qty controls ---
  Widget _buildProductRowItem(
    dynamic product,
    ProductsController controller,
    BuildContext context,
    ThemeLanguageService themeService,
  ) {
    final isLowStock = product.quantity <= product.lowStockThreshold;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 22.w),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.brandName} - ${product.catalogName}',
                    style: getTextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: themeService.textColor,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    'Code: ${product.productCode} • Cost: ৳${product.pricePerPiece.toStringAsFixed(0)}/pc',
                    style: getTextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: themeService.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${product.quantity} pcs',
                    style: getTextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isLowStock ? AppColors.error : AppColors.secondary,
                    ),
                  ),
                ),
                4.verticalSpace,
                Text(
                  'Val: ৳${product.totalPrice.toStringAsFixed(0)}',
                  style: getTextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: themeService.subtextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        8.verticalSpace,
        // Quick Quantity Buttons [-10] [-1] [+1] [+10] & Edit Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickQtyBtn('-10', () => controller.adjustQuantity(product.id, -10), themeService),
                    4.horizontalSpace,
                    _buildQuickQtyBtn('-1', () => controller.adjustQuantity(product.id, -1), themeService),
                    4.horizontalSpace,
                    _buildQuickQtyBtn('+1', () => controller.adjustQuantity(product.id, 1), themeService),
                    4.horizontalSpace,
                    _buildQuickQtyBtn('+10', () => controller.adjustQuantity(product.id, 10), themeService),
                  ],
                ),
              ),
            ),
            8.horizontalSpace,
            GestureDetector(
              onTap: () => context.push(
                AppRoute.addEditProductScreen,
                extra: product,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 12.w, color: AppColors.primary),
                    4.horizontalSpace,
                    Text(
                      'Edit',
                      style: getTextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickQtyBtn(String label, VoidCallback onTap, ThemeLanguageService themeService) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: themeService.inputFillColor,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: themeService.inputBorderColor),
        ),
        child: Text(
          label,
          style: getTextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: themeService.textColor,
          ),
        ),
      ),
    );
  }
}
