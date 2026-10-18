import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../controllers/products_controller.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/common/widgets/custom_text_field.dart';
import '../../../core/common/widgets/customize_filled_button.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProductsController controller;
  late final ThemeLanguageService themeService;
  late final DatabaseService db;
  late final PermissionService perm;

  late TextEditingController brandController;
  late TextEditingController catalogController;
  late TextEditingController codeController;
  late TextEditingController qtyController;
  late TextEditingController costController;
  late TextEditingController sellingPriceController;
  late TextEditingController markupController;
  late TextEditingController marginController;
  late TextEditingController notesController;
  late TextEditingController thresholdController;

  late DateTime selectedDate;
  double autoTotalPrice = 0.0;
  bool _isInternalPriceUpdate = false;
  bool _isMarkupPricingMode = true; // true: Markup on Cost %, false: Margin on Selling Price %

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ProductsController>()
        ? Get.find<ProductsController>()
        : Get.put(ProductsController());
    themeService = Get.find<ThemeLanguageService>();
    db = Get.find<DatabaseService>();
    perm = Get.find<PermissionService>();

    final p = widget.product;
    brandController = TextEditingController(text: p?.brandName ?? '');
    catalogController = TextEditingController(text: p?.catalogName ?? '');
    codeController = TextEditingController(text: p?.productCode ?? controller.generateProductCode());
    qtyController = TextEditingController(text: (p?.quantity ?? 1).toString());
    
    final cost = p?.pricePerPiece ?? 0.0;
    final selling = p?.sellingPrice ?? (cost > 0 ? cost * 1.25 : 0.0);
    
    costController = TextEditingController(text: cost > 0 ? cost.toStringAsFixed(0) : '');
    sellingPriceController = TextEditingController(text: selling > 0 ? selling.toStringAsFixed(0) : '');
    
    // Initial Markup and Margin
    final initialMarkup = cost > 0 ? ((selling - cost) / cost) * 100 : 25.0;
    final initialMargin = selling > 0 ? ((selling - cost) / selling) * 100 : 20.0;
    markupController = TextEditingController(text: initialMarkup.toStringAsFixed(1));
    marginController = TextEditingController(text: initialMargin.toStringAsFixed(1));

    notesController = TextEditingController(text: p?.notes ?? '');
    thresholdController = TextEditingController(text: (p?.lowStockThreshold ?? 3).toString());
    selectedDate = p?.buyingDate ?? DateTime.now();

    _calculateTotalPrice();

    qtyController.addListener(_calculateTotalPrice);
    costController.addListener(_onCostChanged);
    sellingPriceController.addListener(_onSellingPriceChanged);
  }

  void _calculateTotalPrice() {
    final qty = int.tryParse(qtyController.text) ?? 0;
    final cost = double.tryParse(costController.text) ?? 0.0;
    setState(() {
      autoTotalPrice = qty * cost;
    });
  }

  void _onCostChanged() {
    _calculateTotalPrice();
    if (_isInternalPriceUpdate) return;
    final cost = double.tryParse(costController.text) ?? 0.0;
    if (cost <= 0) return;

    _isInternalPriceUpdate = true;
    if (_isMarkupPricingMode) {
      final markup = double.tryParse(markupController.text) ?? 25.0;
      final newSelling = cost * (1 + (markup / 100));
      sellingPriceController.text = newSelling.toStringAsFixed(0);
      final margin = newSelling > 0 ? ((newSelling - cost) / newSelling) * 100 : 0.0;
      marginController.text = margin.toStringAsFixed(1);
    } else {
      final margin = double.tryParse(marginController.text) ?? 20.0;
      if (margin < 100) {
        final newSelling = cost / (1 - (margin / 100));
        sellingPriceController.text = newSelling.toStringAsFixed(0);
        final markup = cost > 0 ? ((newSelling - cost) / cost) * 100 : 0.0;
        markupController.text = markup.toStringAsFixed(1);
      }
    }
    _isInternalPriceUpdate = false;
    setState(() {});
  }

  void _onSellingPriceChanged() {
    if (_isInternalPriceUpdate) return;
    final cost = double.tryParse(costController.text) ?? 0.0;
    final selling = double.tryParse(sellingPriceController.text) ?? 0.0;
    if (cost <= 0 || selling <= 0) return;

    _isInternalPriceUpdate = true;
    final markup = ((selling - cost) / cost) * 100;
    final margin = ((selling - cost) / selling) * 100;
    markupController.text = markup.toStringAsFixed(1);
    marginController.text = margin.toStringAsFixed(1);
    _isInternalPriceUpdate = false;
    setState(() {});
  }

  void _applyMarkup(double markupPercent) {
    final cost = double.tryParse(costController.text) ?? 0.0;
    if (cost <= 0) return;
    _isInternalPriceUpdate = true;
    markupController.text = markupPercent.toStringAsFixed(1);
    final newSelling = cost * (1 + (markupPercent / 100));
    sellingPriceController.text = newSelling.toStringAsFixed(0);
    final margin = newSelling > 0 ? ((newSelling - cost) / newSelling) * 100 : 0.0;
    marginController.text = margin.toStringAsFixed(1);
    _isInternalPriceUpdate = false;
    setState(() {});
  }

  void _applyMargin(double marginPercent) {
    final cost = double.tryParse(costController.text) ?? 0.0;
    if (cost <= 0 || marginPercent >= 100) return;
    _isInternalPriceUpdate = true;
    marginController.text = marginPercent.toStringAsFixed(1);
    final newSelling = cost / (1 - (marginPercent / 100));
    sellingPriceController.text = newSelling.toStringAsFixed(0);
    final markup = cost > 0 ? ((newSelling - cost) / cost) * 100 : 0.0;
    markupController.text = markup.toStringAsFixed(1);
    _isInternalPriceUpdate = false;
    setState(() {});
  }

  void _adjustQuantity(int delta) {
    int current = int.tryParse(qtyController.text) ?? 0;
    current = (current + delta).clamp(0, 999999);
    qtyController.text = current.toString();
  }

  @override
  void dispose() {
    brandController.dispose();
    catalogController.dispose();
    codeController.dispose();
    qtyController.dispose();
    costController.dispose();
    sellingPriceController.dispose();
    markupController.dispose();
    marginController.dispose();
    notesController.dispose();
    thresholdController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final qty = int.tryParse(qtyController.text) ?? 0;
      final cost = double.tryParse(costController.text) ?? 0.0;
      final selling = double.tryParse(sellingPriceController.text) ?? (cost * 1.25);

      final policy = db.policy.value;
      final minFloorPrice = cost * (policy.minimumSellingPriceFloorPercent / 100);

      if (selling < minFloorPrice && !perm.isOwner) {
        Get.snackbar(
          'Policy Violation',
          'Selling price (৳${selling.toStringAsFixed(0)}) cannot be below floor ৳${minFloorPrice.toStringAsFixed(0)} (${policy.minimumSellingPriceFloorPercent}% of cost) without Owner approval.',
          backgroundColor: AppColors.error.withValues(alpha: 0.15),
          colorText: AppColors.error,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final newProduct = Product(
        id: widget.product?.id ?? const Uuid().v4(),
        brandName: brandController.text.trim(),
        catalogName: catalogController.text.trim(),
        productCode: codeController.text.trim(),
        quantity: qty,
        pricePerPiece: cost,
        totalPrice: autoTotalPrice,
        sellingPrice: selling,
        buyingDate: selectedDate,
        notes: notesController.text.trim(),
        lowStockThreshold: int.tryParse(thresholdController.text) ?? 3,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      if (widget.product == null) {
        controller.addProduct(newProduct);
      } else {
        controller.updateProduct(newProduct);
      }
      if (mounted) {
        context.pop();
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text('delete_product'.tr, style: TextStyle(color: themeService.textColor)),
        content: Text('delete_confirm'.tr, style: TextStyle(color: themeService.subtextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr, style: TextStyle(color: themeService.subtextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteProduct(widget.product!.id);
              context.pop();
            },
            child: Text('delete'.tr, style: const TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final cost = double.tryParse(costController.text) ?? 0.0;
    final selling = double.tryParse(sellingPriceController.text) ?? 0.0;
    final unitProfit = selling - cost;
    final policy = db.policy.value;
    final minFloorPrice = cost * (policy.minimumSellingPriceFloorPercent / 100);
    final isBelowFloor = cost > 0 && selling > 0 && selling < minFloorPrice;

    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          isEditing ? 'edit_product'.tr : 'add_product'.tr,
          style: getTextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: themeService.textColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isEditing && perm.canManageInventory)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: _confirmDelete,
            ),
          12.horizontalSpace,
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand & Catalog
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'brand_name'.tr,
                      hintText: 'e.g. Samsung, Apple',
                      controller: brandController,
                      validator: (v) => v!.trim().isEmpty ? 'required'.tr : null,
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: CustomTextField(
                      label: 'catalog_name'.tr,
                      hintText: 'e.g. Galaxy Buds 2',
                      controller: catalogController,
                      validator: (v) => v!.trim().isEmpty ? 'required'.tr : null,
                    ),
                  ),
                ],
              ),
              16.verticalSpace,

              // Product Code with Auto-generation
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'product_code'.tr,
                      hintText: 'e.g. SM-1001',
                      controller: codeController,
                      validator: (v) => v!.trim().isEmpty ? 'required'.tr : null,
                    ),
                  ),
                  8.horizontalSpace,
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        codeController.text = controller.generateProductCode(brandController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      icon: Icon(Icons.auto_awesome_rounded, size: 16.w),
                      label: Text('Generate', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              16.verticalSpace,

              // Quantity & Quick Quantity [-10] [-1] [+1] [+10]
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'quantity'.tr,
                        style: getTextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: themeService.textColor,
                        ),
                      ),
                      8.horizontalSpace,
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildQtyChip('-10', () => _adjustQuantity(-10)),
                              4.horizontalSpace,
                              _buildQtyChip('-1', () => _adjustQuantity(-1)),
                              4.horizontalSpace,
                              _buildQtyChip('+1', () => _adjustQuantity(1)),
                              4.horizontalSpace,
                              _buildQtyChip('+10', () => _adjustQuantity(10)),
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
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? 'Invalid quantity' : null,
                  ),
                ],
              ),
              16.verticalSpace,

              // Cost Per Piece & Auto Total Cost
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'cost_per_piece'.tr,
                      hintText: '0',
                      controller: costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'required'.tr : null,
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'total_cost'.tr.isNotEmpty ? 'total_cost'.tr : 'Total Stock Cost',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: getTextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: themeService.textColor,
                          ),
                        ),
                        8.verticalSpace,
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: themeService.inputFillColor,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: themeService.inputBorderColor),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '৳${autoTotalPrice.toStringAsFixed(0)}',
                              style: getTextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              16.verticalSpace,

              // Customer Selling Price Field
              CustomTextField(
                label: 'Selling Price (Customer POS Price ৳)',
                hintText: '0',
                controller: sellingPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (double.tryParse(v ?? '') ?? -1) <= 0 ? 'Selling price required' : null,
              ),
              12.verticalSpace,

              // Dual Pricing Helper Section (Markup on Cost % vs Margin on Selling Price %)
              _buildPricingHelperCard(cost, selling, unitProfit, isBelowFloor, minFloorPrice),
              16.verticalSpace,

              // Buying Date & Low Stock Threshold
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'buying_date'.tr,
                          style: getTextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: themeService.textColor,
                          ),
                        ),
                        8.verticalSpace,
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              color: themeService.inputFillColor,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: themeService.inputBorderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(selectedDate),
                                  style: getTextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: themeService.textColor,
                                  ),
                                ),
                                Icon(Icons.calendar_today_rounded, size: 16.w, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: CustomTextField(
                      label: 'low_stock_threshold'.tr,
                      hintText: '3',
                      controller: thresholdController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              16.verticalSpace,

              // Notes
              CustomTextField(
                label: 'notes'.tr,
                hintText: 'Additional product notes...',
                controller: notesController,
                maxLines: 2,
              ),
              32.verticalSpace,

              // Submit Button
              CustomFilledButton(
                text: isEditing ? 'update_product'.tr : 'save_product'.tr,
                onPressed: _save,
              ),
              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  // --- Dual Pricing Helper UI (Spec Section 7.3) ---
  Widget _buildPricingHelperCard(
    double cost,
    double selling,
    double unitProfit,
    bool isBelowFloor,
    double minFloorPrice,
  ) {
    final markup = cost > 0 && selling > 0 ? ((selling - cost) / cost) * 100 : 0.0;
    final margin = selling > 0 ? ((selling - cost) / selling) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isBelowFloor ? AppColors.error : AppColors.primary.withValues(alpha: 0.2),
          width: isBelowFloor ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate_rounded, color: AppColors.primary, size: 18.w),
                  6.horizontalSpace,
                  Text(
                    'Dual Pricing Calculator',
                    style: getTextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
                  ),
                ],
              ),
              // Pricing Mode Switcher
              Container(
                decoration: BoxDecoration(
                  color: themeService.inputFillColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    _buildModeToggleBtn('Markup %', _isMarkupPricingMode, () {
                      setState(() => _isMarkupPricingMode = true);
                    }),
                    _buildModeToggleBtn('Margin %', !_isMarkupPricingMode, () {
                      setState(() => _isMarkupPricingMode = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
          10.verticalSpace,

          // Quick preset buttons
          if (_isMarkupPricingMode) ...[
            Text('Quick Markup on Cost % [Selling = Cost × (1 + M/100)]:',
                style: getTextStyle(fontSize: 11.sp, color: themeService.subtextColor)),
            6.verticalSpace,
            Row(
              children: [
                _buildPresetBtn('15%', () => _applyMarkup(15)),
                6.horizontalSpace,
                _buildPresetBtn('20%', () => _applyMarkup(20)),
                6.horizontalSpace,
                _buildPresetBtn('25%', () => _applyMarkup(25)),
                6.horizontalSpace,
                _buildPresetBtn('35%', () => _applyMarkup(35)),
                6.horizontalSpace,
                _buildPresetBtn('50%', () => _applyMarkup(50)),
              ],
            ),
          ] else ...[
            Text('Quick Margin on Selling % [Selling = Cost ÷ (1 - M/100)]:',
                style: getTextStyle(fontSize: 11.sp, color: themeService.subtextColor)),
            6.verticalSpace,
            Row(
              children: [
                _buildPresetBtn('10%', () => _applyMargin(10)),
                6.horizontalSpace,
                _buildPresetBtn('15%', () => _applyMargin(15)),
                6.horizontalSpace,
                _buildPresetBtn('20%', () => _applyMargin(20)),
                6.horizontalSpace,
                _buildPresetBtn('30%', () => _applyMargin(30)),
                6.horizontalSpace,
                _buildPresetBtn('40%', () => _applyMargin(40)),
              ],
            ),
          ],
          12.verticalSpace,

          // Live Metrics Pill Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: themeService.inputFillColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('Markup', '${markup.toStringAsFixed(1)}%', AppColors.primary),
                Container(height: 24.h, width: 1, color: themeService.inputBorderColor),
                _buildMetricCol('Margin', '${margin.toStringAsFixed(1)}%', AppColors.secondary),
                Container(height: 24.h, width: 1, color: themeService.inputBorderColor),
                _buildMetricCol(
                  'Profit/pc',
                  '৳${unitProfit.toStringAsFixed(0)}',
                  unitProfit >= 0 ? AppColors.secondary : AppColors.error,
                ),
              ],
            ),
          ),

          // Floor Alert Warning if below policy floor
          if (isBelowFloor) ...[
            8.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16.w),
                  6.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Floor Alert: Selling price is below Owner floor ৳${minFloorPrice.toStringAsFixed(0)} (${db.policy.value.minimumSellingPriceFloorPercent}%). Requires Owner override.',
                      style: getTextStyle(fontSize: 11.sp, color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.white : themeService.subtextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 5.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: getTextStyle(fontSize: 10.sp, color: themeService.subtextColor)),
        2.verticalSpace,
        Text(value, style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildQtyChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: getTextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
