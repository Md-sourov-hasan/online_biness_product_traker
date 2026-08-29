import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../controllers/products_controller.dart';
import '../../../core/models/product_model.dart';
import '../../../core/common/widgets/custom_text_field.dart';
import '../../../core/common/widgets/customize_filled_button.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product; // If null, adding a new product

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductsController controller = Get.find<ProductsController>();

  late TextEditingController nameController;
  late TextEditingController skuController;
  late TextEditingController categoryController;
  late TextEditingController costController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController thresholdController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product?.name ?? '');
    skuController = TextEditingController(text: widget.product?.sku ?? '');
    categoryController = TextEditingController(text: widget.product?.category ?? '');
    costController = TextEditingController(text: widget.product?.costPrice.toString() ?? '');
    priceController = TextEditingController(text: widget.product?.sellingPrice.toString() ?? '');
    stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '0');
    thresholdController = TextEditingController(text: widget.product?.lowStockThreshold.toString() ?? '3');
  }

  @override
  void dispose() {
    nameController.dispose();
    skuController.dispose();
    categoryController.dispose();
    costController.dispose();
    priceController.dispose();
    stockController.dispose();
    thresholdController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: widget.product?.id ?? const Uuid().v4(),
        name: nameController.text.trim(),
        sku: skuController.text.trim(),
        category: categoryController.text.trim(),
        costPrice: double.tryParse(costController.text) ?? 0.0,
        sellingPrice: double.tryParse(priceController.text) ?? 0.0,
        stockQuantity: int.tryParse(stockController.text) ?? 0,
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        title: Text(
          isEditing ? 'Edit Product' : 'Add Product',
          style: getTextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: 'Product Name',
                  hintText: 'e.g. Wireless Earbuds',
                  controller: nameController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                16.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'SKU (Optional)',
                        hintText: 'e.g. WE-001',
                        controller: skuController,
                      ),
                    ),
                    16.horizontalSpace,
                    Expanded(
                      child: CustomTextField(
                        label: 'Category',
                        hintText: 'e.g. Electronics',
                        controller: categoryController,
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Cost Price (৳)',
                        hintText: '0.00',
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    16.horizontalSpace,
                    Expanded(
                      child: CustomTextField(
                        label: 'Selling Price (৳)',
                        hintText: '0.00',
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Current Stock',
                        hintText: '0',
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    16.horizontalSpace,
                    Expanded(
                      child: CustomTextField(
                        label: 'Low Stock Alert At',
                        hintText: '3',
                        controller: thresholdController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                32.verticalSpace,
                CustomFilledButton(
                  text: isEditing ? 'Update Product' : 'Save Product',
                  onPressed: _saveProduct,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
