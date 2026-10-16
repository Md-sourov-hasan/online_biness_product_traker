import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/sales_controller.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/sale_model.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/database_service.dart';
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
  final PermissionService perm = Get.find<PermissionService>();
  final DatabaseService db = Get.find<DatabaseService>();

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
            Obx(() => Tab(text: 'POS Cart (${controller.cart.length})')),
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

  // ===========================================================================
  // TAB 1: POS / SALES CART & CHECKOUT (Spec Section 7 & 4.2)
  // ===========================================================================
  Widget _buildPosTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Limit Indicator (Spec Section 7.1: Max 10 SKUs, Max 100 units)
          Obx(() {
            final skuCount = controller.distinctSkuCount;
            final unitCount = controller.totalUnitCount;
            final maxSkus = db.policy.value.maxDistinctSkusPerSale;
            final maxUnits = db.policy.value.maxTotalUnitsPerSale;

            final skuExceeded = skuCount > maxSkus;
            final unitExceeded = unitCount > maxUnits;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: (skuExceeded || unitExceeded) ? Colors.redAccent.withValues(alpha: 0.1) : themeService.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: (skuExceeded || unitExceeded) ? Colors.redAccent : themeService.inputBorderColor,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 18.w, color: skuExceeded ? Colors.redAccent : AppColors.primary),
                      8.horizontalSpace,
                      Text(
                        'SKUs: $skuCount / $maxSkus max',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: skuExceeded ? Colors.redAccent : themeService.textColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 18.w, color: unitExceeded ? Colors.redAccent : AppColors.secondary),
                      8.horizontalSpace,
                      Text(
                        'Total Units: $unitCount / $maxUnits max',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: unitExceeded ? Colors.redAccent : themeService.textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          14.verticalSpace,

          // Add Product to Cart Button
          GestureDetector(
            onTap: _showProductPickerModal,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 22.w),
                      10.horizontalSpace,
                      Text(
                        'Tap to search & add products...',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text('Add Item', style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          16.verticalSpace,

          // Cart Items List
          Obx(() {
            final cart = controller.cart;
            if (cart.isEmpty) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(30.h),
                decoration: BoxDecoration(
                  color: themeService.cardColor,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: themeService.inputBorderColor, width: 0.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 48, color: themeService.subtextColor),
                    10.verticalSpace,
                    Text('Your POS Cart is Empty', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                    4.verticalSpace,
                    Text('Add products above to create customer invoice.', style: TextStyle(fontSize: 12.sp, color: themeService.subtextColor)),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cart Items (${cart.length})', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                    TextButton(
                      onPressed: () => controller.cart.clear(),
                      child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
                8.verticalSpace,
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cart.length,
                  separatorBuilder: (context, index) => 8.verticalSpace,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return _buildCartItemCard(item, index);
                  },
                ),
              ],
            );
          }),
          20.verticalSpace,

          // Payment Method Selector
          Text('Payment Method', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
          8.verticalSpace,
          Obx(() {
            final methods = ['Cash', 'bKash', 'Nagad', 'Card', 'Bank Transfer'];
            return Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: methods.map((m) {
                final isSelected = controller.selectedPaymentMethod.value == m;
                return ChoiceChip(
                  label: Text(m),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: themeService.cardColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : themeService.textColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (val) {
                    if (val) controller.selectedPaymentMethod.value = m;
                  },
                );
              }).toList(),
            );
          }),
          20.verticalSpace,

          // Summary & Checkout Box
          Obx(() {
            final gross = controller.cartGrossTotal;
            final disc = controller.cartDiscountTotal;
            final net = controller.cartNetTotal;

            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gross Line Sales:', style: TextStyle(fontSize: 13.sp, color: themeService.subtextColor)),
                      Text('৳${gross.toStringAsFixed(0)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                    ],
                  ),
                  if (disc > 0) ...[
                    6.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Authorized Discount:', style: TextStyle(fontSize: 13.sp, color: Colors.green)),
                        Text('-৳${disc.toStringAsFixed(0)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.green)),
                      ],
                    ),
                  ],
                  10.verticalSpace,
                  const Divider(height: 1),
                  10.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Payable Amount:', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                      Text('৳${net.toStringAsFixed(0)}', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ],
                  ),
                  16.verticalSpace,
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final success = controller.checkoutCart();
                        if (success && controller.lastCompletedSalesId.value != null) {
                          _showReceiptModal(context, controller.lastCompletedSalesId.value!);
                        }
                      },
                      icon: const Icon(Icons.print_rounded, color: Colors.white),
                      label: Text('Complete Sale & Print Receipt', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          80.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildCartItemCard(SaleCartItem item, int index) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: themeService.inputBorderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.displayName, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                4.verticalSpace,
                Text('Unit: ৳${item.unitPrice.toStringAsFixed(0)} • Total: ৳${item.netLineTotal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w600)),
                if (item.discount > 0)
                  Text('Discount: -৳${item.discount.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp, color: Colors.green)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                onPressed: () => controller.updateCartItemQuantity(index, item.quantity - 1),
              ),
              Text('${item.quantity}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                onPressed: () => controller.updateCartItemQuantity(index, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: SALES HISTORY & AUDIT TRAIL (Spec Section 5.1 & 6.2)
  // ===========================================================================
  Widget _buildSalesHistoryTab() {
    return Column(
      children: [
        // Filter Bar (All, Today, Week, Month)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Obx(() {
            final active = controller.selectedPeriodFilter.value;
            return Row(
              children: [
                _buildFilterPill('All', 'all', active),
                6.horizontalSpace,
                _buildFilterPill('Today', 'today', active),
                6.horizontalSpace,
                _buildFilterPill('This Week', 'week', active),
                6.horizontalSpace,
                _buildFilterPill('This Month', 'month', active),
              ],
            );
          }),
        ),

        // Sales List with Receipts, Refund and Exchange options
        Expanded(
          child: Obx(() {
            final salesList = controller.filteredSales;
            if (salesList.isEmpty) {
              return Center(child: Text('No sales found for this period.', style: TextStyle(color: themeService.subtextColor)));
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: salesList.length,
              separatorBuilder: (c, i) => 10.verticalSpace,
              itemBuilder: (context, index) {
                final sale = salesList[index];
                final dateStr = DateFormat('dd MMM, hh:mm a').format(sale.timestamp);
                final canRefund = perm.canResolveRefunds;

                return Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: themeService.inputBorderColor, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sale.productName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                                Text('ID: ${sale.id}', style: TextStyle(fontSize: 11.sp, color: themeService.subtextColor)),
                              ],
                            ),
                          ),
                          Text('৳${sale.totalPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                      8.verticalSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${sale.quantity}x @ ৳${sale.unitPrice.toStringAsFixed(0)} • $dateStr',
                              style: TextStyle(fontSize: 11.sp, color: themeService.subtextColor)),
                          if (!perm.isStaff)
                            Text('+৳${sale.profit.toStringAsFixed(0)} profit', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                        ],
                      ),
                      10.verticalSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Receipt Button
                          OutlinedButton.icon(
                            onPressed: () => _showReceiptModal(context, sale.id),
                            icon: const Icon(Icons.receipt, size: 14),
                            label: const Text('Receipt'),
                            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h)),
                          ),
                          if (canRefund) ...[
                            8.horizontalSpace,
                            ElevatedButton.icon(
                              onPressed: () => _showRefundExchangeDialog(context, sale),
                              icon: const Icon(Icons.replay, size: 14),
                              label: const Text('Return / Exchange'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              ),
                            ),
                          ],
                        ],
                      ),
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
              Text('Select Product for Cart', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
              12.verticalSpace,
              TextField(
                onChanged: (v) => searchFilter.value = v,
                style: TextStyle(color: themeService.textColor),
                decoration: InputDecoration(
                  hintText: 'Search brand or model...',
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
                                controller.addToCart(product);
                                Navigator.pop(ctx);
                              },
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20.w),
                        ),
                        title: Text(product.displayName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                        // Staff sees ONLY selling price per Spec Section 6.2 & 6.4!
                        subtitle: Text(
                          'Selling Price: ৳${product.sellingPrice.toStringAsFixed(0)}${!perm.isStaff ? " (Cost: ৳${product.pricePerPiece.toStringAsFixed(0)})" : ""}',
                          style: TextStyle(color: themeService.subtextColor, fontSize: 11.sp),
                        ),
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

  // --- Customer Sales Receipt Modal (Spec Section 7.2) ---
  void _showReceiptModal(BuildContext context, String salesId) {
    final saleLines = db.sales.where((s) => s.id == salesId).toList();
    if (saleLines.isEmpty) return;

    final first = saleLines.first;
    final totalPaid = saleLines.fold(0.0, (sum, s) => sum + s.totalPrice);
    final totalDiscounts = saleLines.fold(0.0, (sum, s) => sum + s.discountAmount);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(first.timestamp);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeService.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Column(
          children: [
            Icon(Icons.storefront_rounded, color: AppColors.primary, size: 36.w),
            6.verticalSpace,
            Text('StockMate Retail Receipt', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: themeService.textColor)),
            Text('Sales ID: $salesId', style: TextStyle(fontSize: 11.sp, color: themeService.subtextColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: $dateStr', style: TextStyle(fontSize: 11.sp, color: themeService.subtextColor)),
              Text('Served By: ${first.sellerName} (${first.sellerRole})', style: TextStyle(fontSize: 11.sp, color: themeService.subtextColor)),
              Text('Payment Method: ${first.paymentMethod}', style: TextStyle(fontSize: 11.sp, color: themeService.subtextColor)),
              12.verticalSpace,
              const Divider(height: 1),
              8.verticalSpace,
              ...saleLines.map((line) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${line.quantity}x ${line.productName}', style: TextStyle(fontSize: 12.sp, color: themeService.textColor))),
                        Text('৳${line.totalPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                      ],
                    ),
                  )),
              8.verticalSpace,
              const Divider(height: 1),
              8.verticalSpace,
              if (totalDiscounts > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discounts:', style: TextStyle(fontSize: 12.sp, color: Colors.green)),
                    Text('-৳${totalDiscounts.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.green)),
                  ],
                ),
              4.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount Paid:', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                  Text('৳${totalPaid.toStringAsFixed(0)}', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Get.snackbar('Receipt Printed', 'Sent to thermal printer / share sheet', snackPosition: SnackPosition.BOTTOM);
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print / Share'),
          ),
        ],
      ),
    );
  }

  // --- Refund & Exchange Resolution Modal (Spec Section 8) ---
  void _showRefundExchangeDialog(BuildContext context, Sale sale) {
    final qtyCtrl = TextEditingController(text: '${sale.quantity}');
    final reasonCtrl = TextEditingController();
    String mode = 'refund'; // 'refund' or 'exchange'
    Product? selectedReplacement;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: themeService.cardColor,
          title: Text('Resolve Return / Exchange', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original Item: ${sale.productName}', style: TextStyle(fontSize: 12.sp, color: themeService.subtextColor)),
                Text('Eligible Value: ৳${sale.totalPrice.toStringAsFixed(0)} (${sale.quantity} pcs)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                12.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => mode = 'refund'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                            color: mode == 'refund' ? AppColors.error : themeService.inputFillColor,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: mode == 'refund' ? AppColors.error : themeService.inputBorderColor),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Money Refund',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: mode == 'refund' ? Colors.white : themeService.textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => mode = 'exchange'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                            color: mode == 'exchange' ? AppColors.primary : themeService.inputFillColor,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: mode == 'exchange' ? AppColors.primary : themeService.inputBorderColor),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Item Exchange',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: mode == 'exchange' ? Colors.white : themeService.textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                8.verticalSpace,
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity to return'),
                ),
                8.verticalSpace,
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason for return/exchange'),
                ),
                if (mode == 'exchange') ...[
                  12.verticalSpace,
                  DropdownButtonFormField<Product>(
                    initialValue: selectedReplacement,
                    decoration: const InputDecoration(labelText: 'Replacement Item'),
                    items: db.products.where((p) => p.id != sale.productId && p.quantity > 0).map((p) {
                      return DropdownMenuItem(value: p, child: Text('${p.displayName} (৳${p.sellingPrice.toStringAsFixed(0)})'));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedReplacement = val),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                final user = auth.currentUser.value;
                if (qty <= 0) return;

                try {
                  if (mode == 'refund') {
                    db.resolveRefund(
                      originalSale: sale,
                      quantityToRefund: qty,
                      reason: reasonCtrl.text.trim(),
                      resolvedByRole: user?.role ?? 'Manager',
                      resolvedByUserId: user?.id ?? '',
                    );
                    Navigator.pop(ctx);
                    Get.snackbar('Refund Approved', 'Refund reversal committed to audit log.', snackPosition: SnackPosition.BOTTOM);
                  } else {
                    if (selectedReplacement == null) {
                      Get.snackbar('Missing Item', 'Please select replacement product for exchange.', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    db.resolveExchange(
                      originalSale: sale,
                      quantityReturned: qty,
                      replacementProduct: selectedReplacement!,
                      replacementQuantity: 1,
                      reason: reasonCtrl.text.trim(),
                      resolvedByRole: user?.role ?? 'Manager',
                      resolvedByUserId: user?.id ?? '',
                    );
                    Navigator.pop(ctx);
                    Get.snackbar('Exchange Completed', 'Exchange floor validated and committed.', snackPosition: SnackPosition.BOTTOM);
                  }
                } catch (e) {
                  Get.snackbar('Exchange Policy Rejected', e.toString().replaceAll('Exception: ', ''), snackPosition: SnackPosition.BOTTOM);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
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
              style: TextStyle(
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
