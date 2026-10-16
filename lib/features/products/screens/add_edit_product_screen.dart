import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../controllers/products_controller.dart';
import '../../../core/models/product_model.dart';
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

  late TextEditingController brandController;
  late TextEditingController catalogController;
  late TextEditingController codeController;
  late TextEditingController qtyController;
  late TextEditingController costController;
  late TextEditingController notesController;
  late TextEditingController thresholdController;

  late DateTime selectedDate;
  double autoTotalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ProductsController>()
        ? Get.find<ProductsController>()
        : Get.put(ProductsController());
    themeService = Get.find<ThemeLanguageService>();

    final p = widget.product;
    brandController = TextEditingController(text: p?.brandName ?? '');
    catalogController = TextEditingController(text: p?.catalogName ?? '');
    codeController = TextEditingController(text: p?.productCode ?? controller.generateProductCode());
    qtyController = TextEditingController(text: (p?.quantity ?? 1).toString());
    costController = TextEditingController(text: p?.pricePerPiece != null ? p!.pricePerPiece.toStringAsFixed(0) : '');
    notesController = TextEditingController(text: p?.notes ?? '');
    thresholdController = TextEditingController(text: (p?.lowStockThreshold ?? 3).toString());
    selectedDate = p?.buyingDate ?? DateTime.now();

    _calculateTotalPrice();

    qtyController.addListener(_calculateTotalPrice);
    costController.addListener(_calculateTotalPrice);
  }

  void _calculateTotalPrice() {
    final qty = int.tryParse(qtyController.text) ?? 0;
    final cost = double.tryParse(costController.text) ?? 0.0;
    setState(() {
      autoTotalPrice = qty * cost;
    });
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
    notesController.dispose();
    thresholdController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final qty = int.tryParse(qtyController.text) ?? 0;
      final cost = double.tryParse(costController.text) ?? 0.0;

      final newProduct = Product(
        id: widget.product?.id ?? const Uuid().v4(),
        brandName: brandController.text.trim(),
        catalogName: catalogController.text.trim(),
        productCode: codeController.text.trim(),
        quantity: qty,
        pricePerPiece: cost,
        totalPrice: autoTotalPrice,
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
            child: Text('delete'.tr, style: const TextStyle(color: Colors.white)),
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
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: _confirmDelete,
            ),
          12.horizontalSpace,
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
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

              // Price Per Piece & Auto Total Price
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
                          'total_price'.tr,
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
