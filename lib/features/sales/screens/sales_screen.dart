import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/sales_controller.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/common/widgets/custom_text_field.dart';
import '../../../core/common/widgets/customize_filled_button.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SalesController controller = Get.put(SalesController());
  final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
  final AuthService auth = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'sales_pos'.tr,
          style: getTextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: themeService.subtextColor,
          labelStyle: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
          tabs: [
            Tab(text: 'action_new_sale'.tr),
            Tab(text: 'sales_history'.tr),
          ],
        ),
        elevation: 0,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPosTab(),
          _buildSalesHistoryTab(),
        ],
      ),
    );
  }

  // --- TAB 1: POS / Sales Entry ---
  Widget _buildPosTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Product Selector / Search Button
          Text(
            'select_product'.tr,
            style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeService.textColor),
          ),
          8.verticalSpace,
          Obx(() {
            final p = controller.selectedProduct.value;
            if (p == null) {
              return GestureDetector(
                onTap: _showProductPickerModal,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.primary, size: 22.w),
                          10.horizontalSpace,
                          Text(
                            'Tap to search brand or catalog...',
                            style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14.w, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }

            return Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26.w),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.displayName,
                          style: getTextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
                        ),
                        2.verticalSpace,
                        Text(
                          'Code: ${p.productCode} • In Stock: ${p.quantity} pcs',
                          style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.secondary),
                        ),
                        if (!auth.isStaff) ...[
                          2.verticalSpace,
                          Text(
                            'Cost Price: ৳${p.pricePerPiece.toStringAsFixed(0)}',
                            style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.change_circle_rounded, color: AppColors.primary, size: 24.w),
                    onPressed: _showProductPickerModal,
                    tooltip: 'Change Product',
                  ),
                ],
              ),
            );
          }),
          16.verticalSpace,

          // 2. Editable Quantity with Quick Controls [-10] [-1] [+1] [+10]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'sale_quantity'.tr,
                style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeService.textColor),
              ),
              8.horizontalSpace,
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQtyControlBtn('-10', () => controller.adjustQuantity(-10)),
                      4.horizontalSpace,
                      _buildQtyControlBtn('-1', () => controller.adjustQuantity(-1)),
                      4.horizontalSpace,
                      _buildQtyControlBtn('+1', () => controller.adjustQuantity(1)),
                      4.horizontalSpace,
                      _buildQtyControlBtn('+10', () => controller.adjustQuantity(10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          8.verticalSpace,
          CustomTextField(
            label: '',
            hintText: '1',
            controller: controller.quantityController,
            keyboardType: TextInputType.number,
          ),
          16.verticalSpace,

          // 3. Editable Sale Price Per Piece
          CustomTextField(
            label: 'sale_price_per_piece'.tr,
            hintText: '0',
            controller: controller.salePriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          16.verticalSpace,

          // 4. Notes
          CustomTextField(
            label: 'notes'.tr,
            hintText: 'Customer name, order number, etc.',
            controller: controller.notesController,
          ),
          20.verticalSpace,

          // 5. Live Calculations Card (Total Revenue & Profit)
          Obx(() {
            final rev = controller.estimatedTotalRevenue.value;
            final profit = controller.estimatedProfit.value;

            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Sale Amount:',
                          style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeService.textColor),
                        ),
                      ),
                      8.horizontalSpace,
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '৳${rev.toStringAsFixed(0)}',
                          style: getTextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  if (!auth.isStaff) ...[
                    10.verticalSpace,
                    Divider(color: themeService.inputBorderColor),
                    10.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.auto_graph_rounded, size: 16.w, color: AppColors.secondary),
                              6.horizontalSpace,
                              Expanded(
                                child: Text(
                                  '${'estimated_profit'.tr}:',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: getTextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor),
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
                            '৳${profit.toStringAsFixed(0)}',
                            style: getTextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: profit >= 0 ? AppColors.secondary : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
          24.verticalSpace,

          // 6. Complete Sale Button
          CustomFilledButton(
            text: 'complete_sale'.tr,
            onPressed: () {
              controller.completeSale();
            },
          ),
          80.verticalSpace,
        ],
      ),
    );
  }

  // --- TAB 2: Sales History ---
  Widget _buildSalesHistoryTab() {
    return Column(
      children: [
        12.verticalSpace,
        // Period Filter Tabs (All, Today, Week, Month)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Obx(() {
            final active = controller.selectedPeriodFilter.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('All Time', 'all', active),
                  8.horizontalSpace,
                  _buildFilterPill('Today', 'today', active),
                  8.horizontalSpace,
                  _buildFilterPill('This Week', 'week', active),
                  8.horizontalSpace,
                  _buildFilterPill('This Month', 'month', active),
                ],
              ),
            );
          }),
        ),
        12.verticalSpace,

        // Sales Summary Banner
        Obx(() {
          final count = controller.filteredSales.length;
          final rev = controller.filteredRevenue;
          final profit = controller.filteredProfit;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('sales_count'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor)),
                      4.verticalSpace,
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('$count Orders', style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30.h, color: themeService.inputBorderColor),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('total_revenue'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor)),
                        4.verticalSpace,
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('৳${rev.toStringAsFixed(0)}', style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!auth.isStaff) ...[
                  Container(width: 1, height: 30.h, color: themeService.inputBorderColor),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('net_profit'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor)),
                        4.verticalSpace,
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text('৳${profit.toStringAsFixed(0)}', style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        12.verticalSpace,

        // Sales List
        Expanded(
          child: Obx(() {
            final salesList = controller.filteredSales;
            if (salesList.isEmpty) {
              return Center(
                child: Text('No sales found for this period.', style: TextStyle(color: themeService.subtextColor)),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: salesList.length,
              separatorBuilder: (c, i) => 10.verticalSpace,
              itemBuilder: (context, index) {
                final sale = salesList[index];
                final dateStr = DateFormat('dd MMM, hh:mm a').format(sale.timestamp);

                return Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sale.productName,
                              style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
                            ),
                          ),
                          Text(
                            '৳${sale.totalPrice.toStringAsFixed(0)}',
                            style: getTextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                      4.verticalSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${sale.quantity}x @ ৳${sale.unitPrice.toStringAsFixed(0)} • $dateStr',
                            style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                          ),
                          if (!auth.isStaff)
                            Text(
                              '+৳${sale.profit.toStringAsFixed(0)} profit',
                              style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.secondary),
                            ),
                        ],
                      ),
                      if (sale.notes.isNotEmpty) ...[
                        4.verticalSpace,
                        Text('Note: ${sale.notes}', style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor)),
                      ],
                    ],
                  ),
                );
              },
            );
          }),
        ),
        80.verticalSpace,
      ],
    );
  }

  // --- Product Picker Modal Bottom Sheet ---
  void _showProductPickerModal() {
    final searchFilter = ''.obs;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeService.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.sizeOf(context).height * 0.75,
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: themeService.inputBorderColor, borderRadius: BorderRadius.circular(2.r))),
              12.verticalSpace,
              Text('select_product'.tr, style: getTextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
              12.verticalSpace,
              // Search input
              TextField(
                onChanged: (v) => searchFilter.value = v,
                style: TextStyle(color: themeService.textColor),
                decoration: InputDecoration(
                  hintText: 'search_products'.tr,
                  hintStyle: TextStyle(color: themeService.subtextColor),
                  prefixIcon: Icon(Icons.search, color: themeService.subtextColor),
                  filled: true,
                  fillColor: themeService.inputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: themeService.inputBorderColor)),
                ),
              ),
              12.verticalSpace,
              Expanded(
                child: Obx(() {
                  final list = controller.db.products.where((p) {
                    final q = searchFilter.value.toLowerCase();
                    return p.brandName.toLowerCase().contains(q) ||
                        p.catalogName.toLowerCase().contains(q) ||
                        p.productCode.toLowerCase().contains(q);
                  }).toList();

                  if (list.isEmpty) {
                    return Center(child: Text('No products found', style: TextStyle(color: themeService.subtextColor)));
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (c, i) => Divider(color: themeService.inputBorderColor),
                    itemBuilder: (context, index) {
                      final product = list[index];
                      final isOut = product.quantity <= 0;

                      return ListTile(
                        onTap: isOut
                            ? null
                            : () {
                                controller.selectProduct(product);
                                Navigator.pop(ctx);
                              },
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20.w),
                        ),
                        title: Text(product.displayName, style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                        subtitle: Text('Code: ${product.productCode} • Cost: ৳${product.pricePerPiece.toStringAsFixed(0)}', style: TextStyle(color: themeService.subtextColor, fontSize: 11.sp)),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isOut ? AppColors.error.withValues(alpha: 0.1) : AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            isOut ? 'Out of Stock' : '${product.quantity} left',
                            style: TextStyle(color: isOut ? AppColors.error : AppColors.secondary, fontSize: 11.sp, fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQtyControlBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(label, style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
    );
  }

  Widget _buildFilterPill(String title, String value, String active) {
    final isSelected = active == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedPeriodFilter.value = value,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : themeService.cardColor,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: isSelected ? AppColors.primary : themeService.inputBorderColor),
          ),
          child: Center(
            child: Text(
              title,
              style: getTextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : themeService.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
