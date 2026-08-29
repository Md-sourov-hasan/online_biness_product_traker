import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/stock_movement_model.dart';
import '../../products/controllers/products_controller.dart';
import '../../../core/services/notification_service.dart';

class OrdersController extends GetxController {
  final RxList<AppOrder> orders = <AppOrder>[].obs;
  late final ProductsController productsController;

  @override
  void onInit() {
    super.onInit();
    productsController = Get.isRegistered<ProductsController>()
        ? Get.find<ProductsController>()
        : Get.put(ProductsController());
    _loadDummyOrders();
  }

  void _loadDummyOrders() {
    orders.addAll([
      AppOrder(
        id: '1',
        customerName: 'John Doe',
        items: [
          OrderItem(productId: '1', productName: 'Wireless Earbuds', quantity: 1, priceAtSale: 1500),
        ],
        totalAmount: 1500,
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  List<AppOrder> get completedOrders => orders.where((o) => o.status == 'completed').toList();
  List<AppOrder> get pendingOrders => orders.where((o) => o.status == 'pending').toList();

  double get totalRevenue => completedOrders.fold(0, (sum, order) => sum + order.totalAmount);
  int get totalUnitsSold => completedOrders.fold(0, (sum, order) {
    return sum + order.items.fold(0, (itemSum, item) => itemSum + item.quantity);
  });

  void addOrder(String customerName, List<OrderItem> items) {
    if (items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one product', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    double total = items.fold(0, (sum, item) => sum + (item.quantity * item.priceAtSale));

    final newOrder = AppOrder(
      id: const Uuid().v4(),
      customerName: customerName,
      items: items,
      totalAmount: total,
      status: 'completed', // For simplicity, mark as completed directly, could be pending
      createdAt: DateTime.now(),
    );

    // Deduct stock for each item
    for (var item in items) {
      final productIndex = productsController.products.indexWhere((p) => p.id == item.productId);
      if (productIndex != -1) {
        final p = productsController.products[productIndex];
        final newStock = p.stockQuantity - item.quantity;
        
        productsController.products[productIndex] = p.copyWith(
          stockQuantity: newStock,
        );
        // Record stock movement (sale)
        productsController.movements.add(
          StockMovement(
            id: const Uuid().v4(),
            productId: p.id,
            type: 'sale',
            quantity: -item.quantity,
            timestamp: DateTime.now(),
          )
        );
        
        // Trigger notification if stock drops to or below threshold
        if (newStock <= p.lowStockThreshold) {
           final notificationService = Get.find<NotificationService>();
           notificationService.showLowStockNotification(p.name, newStock);
        }
      }
    }

    orders.add(newOrder);
    Get.back();
    Get.snackbar('Success', 'Order placed successfully', snackPosition: SnackPosition.BOTTOM);
  }
}
