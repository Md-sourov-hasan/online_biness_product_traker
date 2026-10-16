import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/database_service.dart';

class OrdersController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();
  final RxList<AppOrder> orders = <AppOrder>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromDatabase();
  }

  void _loadFromDatabase() {
    orders.assignAll(db.sales.map((s) => AppOrder(
      id: s.id,
      customerName: s.notes.isNotEmpty ? s.notes : 'Walk-in Customer',
      items: [
        OrderItem(
          productId: s.productId,
          productName: s.productName,
          quantity: s.quantity,
          priceAtSale: s.unitPrice,
        ),
      ],
      totalAmount: s.totalPrice,
      status: 'completed',
      createdAt: s.timestamp,
    )).toList());
  }

  List<AppOrder> get completedOrders => orders;
  double get totalRevenue => db.totalRevenue;
  int get totalUnitsSold => db.sales.fold(0, (sum, s) => sum + s.quantity);

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
      status: 'completed',
      createdAt: DateTime.now(),
    );

    for (var item in items) {
      final p = db.products.firstWhereOrNull((p) => p.id == item.productId);
      if (p != null) {
        db.recordSale(
          product: p,
          quantity: item.quantity,
          salePrice: item.priceAtSale,
          notes: 'Customer: $customerName',
        );
      }
    }

    orders.insert(0, newOrder);
    Get.back();
    Get.snackbar('Success', 'Order placed successfully', snackPosition: SnackPosition.BOTTOM);
  }
}
