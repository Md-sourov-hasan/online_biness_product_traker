import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/stock_movement_model.dart';

class ProductsController extends GetxController {
  final RxList<Product> products = <Product>[].obs;
  final RxList<StockMovement> movements = <StockMovement>[].obs;
  
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDummyData();
  }

  void _loadDummyData() {
    products.addAll([
      Product(
        id: '1',
        name: 'Wireless Earbuds',
        sku: 'WE-001',
        category: 'Electronics',
        costPrice: 800,
        sellingPrice: 1500,
        stockQuantity: 15,
        lowStockThreshold: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Product(
        id: '2',
        name: 'Phone Case',
        sku: 'PC-002',
        category: 'Accessories',
        costPrice: 200,
        sellingPrice: 500,
        stockQuantity: 2, // Low stock
        lowStockThreshold: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ]);
  }

  List<Product> get lowStockProducts => products.where((p) => p.stockQuantity <= p.lowStockThreshold).toList();
  
  double get totalStockValue => products.fold(0, (sum, item) => sum + (item.costPrice * item.stockQuantity));

  void addProduct(Product product) {
    products.add(product);
    // Add initial stock movement
    if (product.stockQuantity > 0) {
      movements.add(StockMovement(
        id: const Uuid().v4(),
        productId: product.id,
        type: 'restock',
        quantity: product.stockQuantity,
        timestamp: DateTime.now(),
      ));
    }
    Get.back();
    Get.snackbar('Success', 'Product added successfully', snackPosition: SnackPosition.BOTTOM);
  }

  void updateProduct(Product product) {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final oldProduct = products[index];
      products[index] = product;
      
      // Track manual stock adjustment
      if (oldProduct.stockQuantity != product.stockQuantity) {
        final difference = product.stockQuantity - oldProduct.stockQuantity;
        movements.add(StockMovement(
          id: const Uuid().v4(),
          productId: product.id,
          type: difference > 0 ? 'restock' : 'adjustment',
          quantity: difference,
          timestamp: DateTime.now(),
        ));
      }
      Get.back();
      Get.snackbar('Success', 'Product updated successfully', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void deleteProduct(String id) {
    products.removeWhere((p) => p.id == id);
    Get.snackbar('Success', 'Product deleted successfully', snackPosition: SnackPosition.BOTTOM);
  }

  void restockProduct(String id, int quantity) {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1 && quantity > 0) {
      final product = products[index];
      products[index] = product.copyWith(
        stockQuantity: product.stockQuantity + quantity,
      );
      movements.add(StockMovement(
        id: const Uuid().v4(),
        productId: id,
        type: 'restock',
        quantity: quantity,
        timestamp: DateTime.now(),
      ));
      Get.snackbar('Restocked', 'Added $quantity units to ${product.name}', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
