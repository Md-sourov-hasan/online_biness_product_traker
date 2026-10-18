import 'dart:math';
import 'package:get/get.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/database_service.dart';

class ProductsController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();

  final RxString searchQuery = ''.obs;
  final RxString selectedBrandFilter = 'All'.obs;
  final RxBool isBrandView = true.obs; // Toggle between brand grouping and flat list

  // Getter for all products from DatabaseService
  RxList<Product> get products => db.products;
  List<Product> get lowStockProducts => db.lowStockProducts;
  double get totalStockValue => db.totalStockValuation;

  List<String> get brandList {
    final list = ['All', ...db.allBrands];
    return list;
  }

  // Filtered products list
  List<Product> get filteredProducts {
    return products.where((p) {
      final matchesSearch = searchQuery.value.isEmpty ||
          p.brandName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          p.catalogName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          p.productCode.toLowerCase().contains(searchQuery.value.toLowerCase());

      final matchesBrand = selectedBrandFilter.value == 'All' ||
          p.brandName.toLowerCase() == selectedBrandFilter.value.toLowerCase();

      return matchesSearch && matchesBrand;
    }).toList();
  }

  // Grouped products by brand map
  Map<String, List<Product>> get groupedByBrand {
    final Map<String, List<Product>> grouped = {};
    for (var p in filteredProducts) {
      if (!grouped.containsKey(p.brandName)) {
        grouped[p.brandName] = [];
      }
      grouped[p.brandName]!.add(p);
    }
    return grouped;
  }

  // Auto-generate Product Code (e.g. SM-4829)
  String generateProductCode([String? brandPrefix]) {
    final prefix = (brandPrefix != null && brandPrefix.trim().isNotEmpty)
        ? brandPrefix.trim().substring(0, min(3, brandPrefix.trim().length)).toUpperCase()
        : 'SM';
    final randomNum = 1000 + Random().nextInt(9000);
    return '$prefix-$randomNum';
  }

  void addProduct(Product product) {
    db.addProduct(product);
    Get.snackbar('Success', 'Product saved successfully', snackPosition: SnackPosition.BOTTOM);
  }

  void updateProduct(Product product) {
    db.updateProduct(product);
    Get.snackbar('Success', 'Product updated successfully', snackPosition: SnackPosition.BOTTOM);
  }

  void deleteProduct(String id) {
    db.deleteProduct(id);
    Get.snackbar('Deleted', 'Product removed from inventory', snackPosition: SnackPosition.BOTTOM);
  }

  void adjustQuantity(String id, int delta) {
    db.adjustProductQuantity(id, delta);
  }
}
