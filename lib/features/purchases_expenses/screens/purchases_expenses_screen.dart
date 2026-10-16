import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/purchases_expenses_controller.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../../../core/common/widgets/custom_text_field.dart';
import '../../../core/common/widgets/customize_filled_button.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';

class PurchasesExpensesScreen extends StatefulWidget {
  const PurchasesExpensesScreen({super.key});

  @override
  State<PurchasesExpensesScreen> createState() => _PurchasesExpensesScreenState();
}

class _PurchasesExpensesScreenState extends State<PurchasesExpensesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PurchasesExpensesController controller = Get.put(PurchasesExpensesController());
  final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();

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
          'nav_purchases_expenses'.tr,
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
            Tab(text: 'purchases_title'.tr),
            Tab(text: 'expenses_title'.tr),
          ],
        ),
        elevation: 0,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPurchasesTab(),
          _buildExpensesTab(),
        ],
      ),
    );
  }

  // --- TAB 1: Purchases (Restock) ---
  Widget _buildPurchasesTab() {
    return Column(
      children: [
        12.verticalSpace,
        // Purchase summary & Add button
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Stock Purchases', maxLines: 1, overflow: TextOverflow.ellipsis, style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor)),
                    4.verticalSpace,
                    Obx(() => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '৳${controller.totalPurchaseSum.toStringAsFixed(0)}',
                            style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        )),
                  ],
                ),
              ),
              8.horizontalSpace,
              ElevatedButton.icon(
                onPressed: _showAddPurchaseModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
                label: Text('add_purchase'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        12.verticalSpace,

        // Purchases List
        Expanded(
          child: Obx(() {
            final list = controller.purchases;
            if (list.isEmpty) {
              return Center(
                child: Text('No purchase records yet.', style: TextStyle(color: themeService.subtextColor)),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: list.length,
              separatorBuilder: (c, i) => 10.verticalSpace,
              itemBuilder: (context, index) {
                final purchase = list[index];
                final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(purchase.timestamp);

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
                              purchase.productName,
                              style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
                            ),
                          ),
                          Text(
                            '৳${purchase.totalAmount.toStringAsFixed(0)}',
                            style: getTextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                      4.verticalSpace,
                      Text(
                        'Restocked: ${purchase.quantity} units @ ৳${purchase.pricePerPiece.toStringAsFixed(0)}/pc',
                        style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.secondary),
                      ),
                      4.verticalSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                          ),
                          if (purchase.supplier.isNotEmpty)
                            Text(
                              'Supplier: ${purchase.supplier}',
                              style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor),
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
        80.verticalSpace,
      ],
    );
  }

  // --- TAB 2: Expenses ---
  Widget _buildExpensesTab() {
    return Column(
      children: [
        12.verticalSpace,
        // Summary & Add Button
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('total_expenses'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor)),
                    4.verticalSpace,
                    Obx(() => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '৳${controller.totalExpenseSum.toStringAsFixed(0)}',
                            style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.error),
                          ),
                        )),
                  ],
                ),
              ),
              8.horizontalSpace,
              ElevatedButton.icon(
                onPressed: () => _showAddEditExpenseModal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                label: Text('add_expense'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        12.verticalSpace,

        // Category Filter Chips
        SizedBox(
          height: 32.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            children: ['All', ...AppConstants.expenseCategories].map((cat) {
              return Obx(() {
                final isSelected = controller.selectedExpenseCategory.value == cat;
                return GestureDetector(
                  onTap: () => controller.selectedExpenseCategory.value = cat,
                  child: Container(
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.error : themeService.cardColor,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: isSelected ? AppColors.error : themeService.inputBorderColor),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: getTextStyle(
                          fontSize: 11.sp,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : themeService.textColor,
                        ),
                      ),
                    ),
                  ),
                );
              });
            }).toList(),
          ),
        ),
        12.verticalSpace,

        // Expenses List
        Expanded(
          child: Obx(() {
            final list = controller.filteredExpenses;
            if (list.isEmpty) {
              return Center(
                child: Text('No expenses recorded for this category.', style: TextStyle(color: themeService.subtextColor)),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: list.length,
              separatorBuilder: (c, i) => 10.verticalSpace,
              itemBuilder: (context, index) {
                final expense = list[index];
                final dateStr = DateFormat('dd MMM yyyy').format(expense.date);

                return Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(Icons.receipt_rounded, color: AppColors.error, size: 20.w),
                          ),
                          12.horizontalSpace,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.category,
                                style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
                              ),
                              2.verticalSpace,
                              Text(
                                '$dateStr • ${expense.notes.isEmpty ? 'No notes' : expense.notes}',
                                style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '৳${expense.amount.toStringAsFixed(0)}',
                            style: getTextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.error),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: themeService.subtextColor, size: 18.w),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showAddEditExpenseModal(expense: expense);
                              } else if (val == 'delete') {
                                controller.deleteExpense(expense.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                            ],
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
        80.verticalSpace,
      ],
    );
  }

  // --- Modal 1: Add Restock Purchase Modal ---
  void _showAddPurchaseModal() {
    Product? selectedProduct;
    final qtyController = TextEditingController(text: '10');
    final costController = TextEditingController();
    final supplierController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeService.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16.w, right: 16.w, top: 16.w),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: themeService.inputBorderColor, borderRadius: BorderRadius.circular(2.r)))),
                    12.verticalSpace,
                    Text('add_purchase'.tr, style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                    16.verticalSpace,

                    // Select Product
                    Text('Select Product to Restock', style: getTextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                    8.verticalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: themeService.inputFillColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: themeService.inputBorderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Product>(
                          isExpanded: true,
                          value: selectedProduct,
                          hint: Text('Select Product', style: TextStyle(color: themeService.subtextColor)),
                          dropdownColor: themeService.cardColor,
                          items: controller.db.products.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text('${p.displayName} (${p.quantity} pcs in stock)', style: TextStyle(color: themeService.textColor)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedProduct = val;
                              if (val != null) {
                                costController.text = val.pricePerPiece.toStringAsFixed(0);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    16.verticalSpace,

                    // Quantity & Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Purchase Quantity', style: getTextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                        8.horizontalSpace,
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildMiniQtyBtn('+5', () {
                                  int q = int.tryParse(qtyController.text) ?? 0;
                                  qtyController.text = (q + 5).toString();
                                }),
                                4.horizontalSpace,
                                _buildMiniQtyBtn('+10', () {
                                  int q = int.tryParse(qtyController.text) ?? 0;
                                  qtyController.text = (q + 10).toString();
                                }),
                                4.horizontalSpace,
                                _buildMiniQtyBtn('+50', () {
                                  int q = int.tryParse(qtyController.text) ?? 0;
                                  qtyController.text = (q + 50).toString();
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    8.verticalSpace,
                    CustomTextField(label: '', hintText: 'Quantity', controller: qtyController, keyboardType: TextInputType.number),
                    16.verticalSpace,

                    // Cost Price Per Piece
                    CustomTextField(label: 'cost_per_piece'.tr, hintText: '0', controller: costController, keyboardType: TextInputType.number),
                    16.verticalSpace,

                    // Supplier
                    CustomTextField(label: 'supplier_vendor'.tr, hintText: 'e.g. Official Importer Ltd.', controller: supplierController),
                    16.verticalSpace,

                    // Notes
                    CustomTextField(label: 'notes'.tr, hintText: 'Batch no., invoice ref, etc.', controller: notesController),
                    24.verticalSpace,

                    // Submit
                    CustomFilledButton(
                      text: 'Save Restock Purchase',
                      onPressed: () {
                        if (selectedProduct == null) {
                          Get.snackbar('Error', 'Please select a product');
                          return;
                        }
                        final qty = int.tryParse(qtyController.text) ?? 0;
                        final cost = double.tryParse(costController.text) ?? 0.0;
                        if (qty <= 0) {
                          Get.snackbar('Error', 'Quantity must be greater than 0');
                          return;
                        }

                        controller.addPurchase(
                          product: selectedProduct!,
                          quantity: qty,
                          pricePerPiece: cost,
                          supplier: supplierController.text.trim(),
                          notes: notesController.text.trim(),
                        );
                        Navigator.pop(ctx);
                      },
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Modal 2: Add/Edit Expense Modal ---
  void _showAddEditExpenseModal({Expense? expense}) {
    final isEdit = expense != null;
    String selectedCategory = expense?.category ?? AppConstants.expenseCategories.first;
    final amountController = TextEditingController(text: expense != null ? expense.amount.toStringAsFixed(0) : '');
    final notesController = TextEditingController(text: expense?.notes ?? '');
    DateTime selectedDate = expense?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeService.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16.w, right: 16.w, top: 16.w),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: themeService.inputBorderColor, borderRadius: BorderRadius.circular(2.r)))),
                    12.verticalSpace,
                    Text(isEdit ? 'edit_expense'.tr : 'add_expense'.tr, style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                    16.verticalSpace,

                    // Category Dropdown
                    Text('expense_category'.tr, style: getTextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: themeService.textColor)),
                    8.verticalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: themeService.inputFillColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: themeService.inputBorderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          dropdownColor: themeService.cardColor,
                          items: AppConstants.expenseCategories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: TextStyle(color: themeService.textColor)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                    16.verticalSpace,

                    // Amount
                    CustomTextField(
                      label: 'expense_amount'.tr,
                      hintText: '0.00',
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    16.verticalSpace,

                    // Notes
                    CustomTextField(
                      label: 'notes'.tr,
                      hintText: 'Electricity bill, Shop cleaner, etc.',
                      controller: notesController,
                    ),
                    24.verticalSpace,

                    // Submit
                    CustomFilledButton(
                      text: isEdit ? 'Save Changes' : 'Record Expense',
                      color: AppColors.error,
                      onPressed: () {
                        final amt = double.tryParse(amountController.text) ?? 0.0;
                        if (amt <= 0) {
                          Get.snackbar('Error', 'Enter a valid expense amount');
                          return;
                        }

                        if (isEdit) {
                          controller.updateExpense(Expense(
                            id: expense.id,
                            category: selectedCategory,
                            amount: amt,
                            notes: notesController.text.trim(),
                            date: selectedDate,
                            createdAt: expense.createdAt,
                          ));
                        } else {
                          controller.addExpense(
                            category: selectedCategory,
                            amount: amt,
                            date: selectedDate,
                            notes: notesController.text.trim(),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniQtyBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(label, style: TextStyle(color: AppColors.primary, fontSize: 11.sp, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
