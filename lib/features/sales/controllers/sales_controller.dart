import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/sale_model.dart';
import '../../../core/services/database_service.dart';

class SalesController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();

  // POS State
  final Rx<Product?> selectedProduct = Rx<Product?>(null);
  final TextEditingController searchController = TextEditingController();
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController notesController = TextEditingController();

  final RxDouble estimatedProfit = 0.0.obs;
  final RxDouble estimatedTotalRevenue = 0.0.obs;
  final RxString selectedPeriodFilter = 'all'.obs; // 'all', 'today', 'week', 'month'

  @override
  void onInit() {
    super.onInit();
    salePriceController.addListener(_calculateEstimates);
    quantityController.addListener(_calculateEstimates);
  }

  void selectProduct(Product product) {
    selectedProduct.value = product;
    // Suggest a default selling price (cost * 1.25)
    final suggested = (product.pricePerPiece * 1.25).roundToDouble();
    salePriceController.text = suggested.toStringAsFixed(0);
    quantityController.text = '1';
    _calculateEstimates();
  }

  void adjustQuantity(int delta) {
    int current = int.tryParse(quantityController.text) ?? 1;
    final maxStock = selectedProduct.value?.quantity ?? 9999;
    current = (current + delta).clamp(1, maxStock);
    quantityController.text = current.toString();
  }

  void _calculateEstimates() {
    if (selectedProduct.value == null) {
      estimatedTotalRevenue.value = 0.0;
      estimatedProfit.value = 0.0;
      return;
    }

    final qty = int.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(salePriceController.text) ?? 0.0;
    final cost = selectedProduct.value!.pricePerPiece;

    estimatedTotalRevenue.value = qty * price;
    estimatedProfit.value = (price - cost) * qty;
  }

  bool completeSale() {
    if (selectedProduct.value == null) {
      Get.snackbar('Error', 'Please select a product first', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    final qty = int.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(salePriceController.text) ?? 0.0;

    if (qty <= 0) {
      Get.snackbar('Invalid Quantity', 'Sale quantity must be greater than 0', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    if (qty > selectedProduct.value!.quantity) {
      Get.snackbar('Out of Stock', 'Available stock is only ${selectedProduct.value!.quantity} units', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    final success = db.recordSale(
      product: selectedProduct.value!,
      quantity: qty,
      salePrice: price,
      notes: notesController.text.trim(),
    );

    if (success) {
      Get.snackbar('Success', 'sale_success'.tr, snackPosition: SnackPosition.BOTTOM);
      // Reset form
      selectedProduct.value = null;
      salePriceController.clear();
      quantityController.text = '1';
      notesController.clear();
      _calculateEstimates();
      return true;
    }
    return false;
  }

  // Filtered sales history
  List<Sale> get filteredSales {
    final now = DateTime.now();
    return db.sales.where((s) {
      if (selectedPeriodFilter.value == 'today') {
        return s.timestamp.year == now.year && s.timestamp.month == now.month && s.timestamp.day == now.day;
      } else if (selectedPeriodFilter.value == 'week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return s.timestamp.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
      } else if (selectedPeriodFilter.value == 'month') {
        return s.timestamp.year == now.year && s.timestamp.month == now.month;
      }
      return true;
    }).toList();
  }

  double get filteredRevenue => filteredSales.fold(0.0, (sum, s) => sum + s.totalPrice);
  double get filteredProfit => filteredSales.fold(0.0, (sum, s) => sum + s.profit);

  @override
  void onClose() {
    searchController.dispose();
    salePriceController.dispose();
    quantityController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
