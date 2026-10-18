import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../controllers/orders_controller.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/common/widgets/custom_text_field.dart';
import '../../../core/common/widgets/customize_filled_button.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  late final OrdersController controller;
  late final DatabaseService db;

  final TextEditingController customerNameController = TextEditingController();
  final RxList<OrderItem> selectedItems = <OrderItem>[].obs;
  Product? selectedProduct;
  final TextEditingController quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<OrdersController>()
        ? Get.find<OrdersController>()
        : Get.put(OrdersController());
    db = Get.find<DatabaseService>();
  }

  void _addItem() {
    if (selectedProduct == null) return;

    int qty = int.tryParse(quantityController.text) ?? 0;
    if (qty <= 0) {
      Get.snackbar('Error', 'Quantity must be at least 1');
      return;
    }
    if (qty > selectedProduct!.quantity) {
      Get.snackbar('Error', 'Not enough stock available');
      return;
    }

    final salePrice = selectedProduct!.pricePerPiece * 1.25;
    selectedItems.add(OrderItem(
      productId: selectedProduct!.id,
      productName: selectedProduct!.displayName,
      quantity: qty,
      priceAtSale: salePrice,
    ));

    setState(() {
      selectedProduct = null;
      quantityController.text = '1';
    });
  }

  void _placeOrder() {
    if (customerNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Customer name is required');
      return;
    }
    controller.addOrder(customerNameController.text.trim(), selectedItems.toList());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeLanguageService theme = Get.find<ThemeLanguageService>();

    return Obx(() {
      final t = theme.t;

      return CommonBackgroundScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Create Order',
            style: getTextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.text),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Customer Name',
                hintText: 'e.g. Alice Smith',
                controller: customerNameController,
              ),
              24.verticalSpace,
              Text(
                'Add Products',
                style: getTextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: t.text,
                ),
              ),
              8.verticalSpace,
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: t.input,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: t.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Product>(
                          isExpanded: true,
                          dropdownColor: t.card,
                          value: selectedProduct,
                          hint: Text(
                            'Select a product',
                            style: getTextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: t.textSec,
                            ),
                          ),
                          items: db.products.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                '${p.displayName} - ${p.quantity} left',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: t.text),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedProduct = val),
                        ),
                      ),
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      label: '',
                      hintText: 'Qty',
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  12.horizontalSpace,
                  IconButton(
                    icon: Icon(Icons.add_circle, color: t.accent, size: 36.w),
                    onPressed: _addItem,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              16.verticalSpace,
              Divider(color: t.border, height: 1),
              16.verticalSpace,
              Expanded(
                child: Obx(() {
                  if (selectedItems.isEmpty) {
                    return Center(
                      child: Text(
                        'No items added yet',
                        style: TextStyle(color: t.textSec),
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = selectedItems[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          title: Text(item.productName, style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${item.quantity} x ৳${item.priceAtSale.toStringAsFixed(0)}',
                            style: TextStyle(color: t.textSec),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () => selectedItems.removeAt(index),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              Obx(() {
                double total = selectedItems.fold(0, (sum, item) => sum + (item.quantity * item.priceAtSale));
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: t.text)),
                        Text('৳${total.toStringAsFixed(2)}', style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: t.accent)),
                      ],
                    ),
                    16.verticalSpace,
                    CustomFilledButton(
                      text: 'Place Order',
                      onPressed: selectedItems.isEmpty ? () {} : _placeOrder,
                      color: selectedItems.isEmpty ? t.textMuted : t.accent,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}
