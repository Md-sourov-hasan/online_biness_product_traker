import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/purchase_model.dart';
import '../models/expense_model.dart';
import '../models/activity_log_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class DatabaseService extends GetxService {
  static DatabaseService get to => Get.find<DatabaseService>();

  // Reactive Data Stores
  final RxList<Product> products = <Product>[].obs;
  final RxList<Sale> sales = <Sale>[].obs;
  final RxList<Purchase> purchases = <Purchase>[].obs;
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxList<ActivityLog> activityLogs = <ActivityLog>[].obs;
  final RxList<AppUser> users = <AppUser>[].obs;

  // Cloud Sync State
  final RxBool isSyncing = false.obs;
  final RxBool isCloudSynced = true.obs;
  final Rx<DateTime> lastSyncTime = DateTime.now().obs;

  SharedPreferences? _prefs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initStorage();
  }

  Future<void> _initStorage() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await loadFromLocal();
    } catch (e) {
      debugPrint('Error initializing local database: $e');
      _seedDefaultData();
    }
  }

  // --- Calculations & Computed Metrics ---
  int get totalStockPieces => products.fold(0, (sum, p) => sum + p.quantity);
  double get totalStockValuation => products.fold(0.0, (sum, p) => sum + (p.quantity * p.pricePerPiece));
  List<Product> get lowStockProducts => products.where((p) => p.quantity <= p.lowStockThreshold).toList();
  List<String> get allBrands => products.map((p) => p.brandName).toSet().toList();

  // Revenue & Profit metrics
  double get totalRevenue => sales.fold(0.0, (sum, s) => sum + s.totalPrice);
  double get totalCOGS => sales.fold(0.0, (sum, s) => sum + (s.unitCost * s.quantity));
  double get totalGrossProfit => sales.fold(0.0, (sum, s) => sum + s.profit);
  double get totalExpenses => expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get netProfit => totalRevenue - totalCOGS - totalExpenses;

  // Daily / Weekly / Monthly Filters
  double getSalesForPeriod(String period) {
    final now = DateTime.now();
    return sales.where((s) {
      if (period == 'today') {
        return s.timestamp.year == now.year && s.timestamp.month == now.month && s.timestamp.day == now.day;
      } else if (period == 'week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return s.timestamp.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
      } else if (period == 'month') {
        return s.timestamp.year == now.year && s.timestamp.month == now.month;
      }
      return true;
    }).fold(0.0, (sum, s) => sum + s.totalPrice);
  }

  double getProfitForPeriod(String period) {
    final now = DateTime.now();
    return sales.where((s) {
      if (period == 'today') {
        return s.timestamp.year == now.year && s.timestamp.month == now.month && s.timestamp.day == now.day;
      } else if (period == 'week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return s.timestamp.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
      } else if (period == 'month') {
        return s.timestamp.year == now.year && s.timestamp.month == now.month;
      }
      return true;
    }).fold(0.0, (sum, s) => sum + s.profit);
  }

  // --- Product Operations ---
  void addProduct(Product product) {
    products.add(product);
    logActivity('product_add', 'Product Added', '${product.displayName} (Code: ${product.productCode}) added with ${product.quantity} pcs.');
    saveToLocal();
  }

  void updateProduct(Product product) {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      logActivity('product_update', 'Product Updated', '${product.displayName} updated.');
      saveToLocal();
    }
  }

  void deleteProduct(String id) {
    final p = products.firstWhereOrNull((item) => item.id == id);
    if (p != null) {
      products.removeWhere((item) => item.id == id);
      logActivity('product_delete', 'Product Deleted', '${p.displayName} was deleted.');
      saveToLocal();
    }
  }

  void adjustProductQuantity(String id, int delta) {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final p = products[index];
      final newQty = (p.quantity + delta).clamp(0, 999999);
      products[index] = p.copyWith(quantity: newQty);
      logActivity('stock_adjustment', 'Stock Adjusted', '${p.displayName} adjusted by $delta (Now: $newQty)');
      saveToLocal();
    }
  }

  // --- Sales Operations ---
  bool recordSale({
    required Product product,
    required int quantity,
    required double salePrice,
    String notes = '',
  }) {
    if (product.quantity < quantity) {
      return false;
    }

    // Deduct stock
    final productIndex = products.indexWhere((p) => p.id == product.id);
    if (productIndex != -1) {
      final updatedProduct = product.copyWith(
        quantity: product.quantity - quantity,
      );
      products[productIndex] = updatedProduct;

      // Low stock check
      if (updatedProduct.quantity <= updatedProduct.lowStockThreshold) {
        try {
          if (Get.isRegistered<NotificationService>()) {
            Get.find<NotificationService>().showLowStockNotification(
              updatedProduct.displayName,
              updatedProduct.quantity,
            );
          }
        } catch (_) {}
      }
    }

    final sale = Sale(
      id: const Uuid().v4(),
      productId: product.id,
      productName: product.displayName,
      brandName: product.brandName,
      catalogName: product.catalogName,
      productCode: product.productCode,
      quantity: quantity,
      unitCost: product.pricePerPiece,
      unitPrice: salePrice,
      totalPrice: quantity * salePrice,
      profit: (salePrice - product.pricePerPiece) * quantity,
      timestamp: DateTime.now(),
      notes: notes,
    );

    sales.insert(0, sale);
    logActivity('sale', 'Sale Completed', '${quantity}x ${product.displayName} sold for ৳${sale.totalPrice.toStringAsFixed(0)} (Profit: ৳${sale.profit.toStringAsFixed(0)})');
    saveToLocal();
    return true;
  }

  // --- Purchase Operations ---
  void recordPurchase({
    required Product product,
    required int quantity,
    required double pricePerPiece,
    String supplier = '',
    String notes = '',
  }) {
    // Increment stock
    final productIndex = products.indexWhere((p) => p.id == product.id);
    if (productIndex != -1) {
      final currentP = products[productIndex];
      products[productIndex] = currentP.copyWith(
        quantity: currentP.quantity + quantity,
        pricePerPiece: pricePerPiece, // Update latest cost
      );
    }

    final purchase = Purchase(
      id: const Uuid().v4(),
      productId: product.id,
      productName: product.displayName,
      brandName: product.brandName,
      catalogName: product.catalogName,
      productCode: product.productCode,
      quantity: quantity,
      pricePerPiece: pricePerPiece,
      totalAmount: quantity * pricePerPiece,
      timestamp: DateTime.now(),
      supplier: supplier,
      notes: notes,
    );

    purchases.insert(0, purchase);
    logActivity('purchase', 'Stock Restocked', 'Purchased ${quantity}x ${product.displayName} for ৳${purchase.totalAmount.toStringAsFixed(0)}');
    saveToLocal();
  }

  // --- Expense Operations ---
  void addExpense(Expense expense) {
    expenses.insert(0, expense);
    logActivity('expense', 'Expense Recorded', '${expense.category}: ৳${expense.amount.toStringAsFixed(0)} (${expense.notes})');
    saveToLocal();
  }

  void updateExpense(Expense expense) {
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      expenses[index] = expense;
      logActivity('expense', 'Expense Updated', '${expense.category}: ৳${expense.amount.toStringAsFixed(0)}');
      saveToLocal();
    }
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    logActivity('expense', 'Expense Deleted', 'Expense entry removed.');
    saveToLocal();
  }

  // --- User Approval Operations ---
  void updateUserApproval(String userId, String status) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      users[index] = users[index].copyWith(approvalStatus: status);
      logActivity('user', 'User Status Updated', '${users[index].name} marked as $status');
      saveToLocal();
    }
  }

  void updateUserRole(String userId, String role) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      users[index] = users[index].copyWith(role: role);
      logActivity('user', 'User Role Changed', '${users[index].name} role set to $role');
      saveToLocal();
    }
  }

  // --- Activity Logging ---
  void logActivity(String type, String title, String description) {
    activityLogs.insert(0, ActivityLog(
      id: const Uuid().v4(),
      type: type,
      title: title,
      description: description,
      timestamp: DateTime.now(),
    ));
    if (activityLogs.length > 200) {
      activityLogs.removeRange(200, activityLogs.length);
    }
  }

  // --- Cloud Sync Simulation / Action ---
  Future<void> triggerCloudSync() async {
    isSyncing.value = true;
    await Future.delayed(const Duration(milliseconds: 1200));
    lastSyncTime.value = DateTime.now();
    isCloudSynced.value = true;
    isSyncing.value = false;
    logActivity('backup', 'Cloud Sync', 'Database successfully synchronized with cloud.');
  }

  // --- Persistence (Local JSON Storage) ---
  Future<void> saveToLocal() async {
    try {
      if (_prefs == null) return;
      await _prefs!.setString('sm_products', jsonEncode(products.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_sales', jsonEncode(sales.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_purchases', jsonEncode(purchases.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_expenses', jsonEncode(expenses.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_logs', jsonEncode(activityLogs.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_users', jsonEncode(users.map((e) => e.toMap()).toList()));
    } catch (e) {
      debugPrint('Error saving database to local storage: $e');
    }
  }

  Future<void> loadFromLocal() async {
    if (_prefs == null) return;
    final productsStr = _prefs!.getString('sm_products');
    final salesStr = _prefs!.getString('sm_sales');
    final purchasesStr = _prefs!.getString('sm_purchases');
    final expensesStr = _prefs!.getString('sm_expenses');
    final logsStr = _prefs!.getString('sm_logs');
    final usersStr = _prefs!.getString('sm_users');

    if (productsStr != null && productsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(productsStr);
      products.assignAll(list.map((m) => Product.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    } else {
      _seedDefaultData();
      return;
    }

    if (salesStr != null && salesStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(salesStr);
      sales.assignAll(list.map((m) => Sale.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (purchasesStr != null && purchasesStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(purchasesStr);
      purchases.assignAll(list.map((m) => Purchase.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (expensesStr != null && expensesStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(expensesStr);
      expenses.assignAll(list.map((m) => Expense.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (logsStr != null && logsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(logsStr);
      activityLogs.assignAll(list.map((m) => ActivityLog.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (usersStr != null && usersStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(usersStr);
      users.assignAll(list.map((m) => AppUser.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    } else {
      _seedDefaultUsers();
    }
  }

  void _seedDefaultData() {
    products.assignAll([
      Product(
        id: '1',
        brandName: 'Samsung',
        catalogName: 'Galaxy Buds Pro',
        productCode: 'SM-8091',
        quantity: 24,
        pricePerPiece: 8500,
        buyingDate: DateTime.now().subtract(const Duration(days: 12)),
        notes: 'Original distributor stock',
        lowStockThreshold: 5,
      ),
      Product(
        id: '2',
        brandName: 'Apple',
        catalogName: 'AirPods Max',
        productCode: 'AP-4402',
        quantity: 8,
        pricePerPiece: 45000,
        buyingDate: DateTime.now().subtract(const Duration(days: 8)),
        notes: 'Space Gray and Silver',
        lowStockThreshold: 3,
      ),
      Product(
        id: '3',
        brandName: 'Walton',
        catalogName: 'Primo S8 Power Bank 20000mAh',
        productCode: 'WL-1029',
        quantity: 3, // Low stock
        pricePerPiece: 1400,
        buyingDate: DateTime.now().subtract(const Duration(days: 20)),
        notes: 'Fast charging model',
        lowStockThreshold: 5,
      ),
      Product(
        id: '4',
        brandName: 'Xiaomi',
        catalogName: 'Redmi Smart Band 2',
        productCode: 'XM-9011',
        quantity: 35,
        pricePerPiece: 2200,
        buyingDate: DateTime.now().subtract(const Duration(days: 5)),
        notes: 'Black & Blue straps',
        lowStockThreshold: 6,
      ),
      Product(
        id: '5',
        brandName: 'Apex',
        catalogName: 'Venturini Leather Wallet',
        productCode: 'APX-771',
        quantity: 18,
        pricePerPiece: 1100,
        buyingDate: DateTime.now().subtract(const Duration(days: 15)),
        notes: 'Brown genuine leather',
        lowStockThreshold: 4,
      ),
    ]);

    sales.assignAll([
      Sale(
        id: 's1',
        productId: '1',
        productName: 'Samsung Galaxy Buds Pro',
        brandName: 'Samsung',
        catalogName: 'Galaxy Buds Pro',
        productCode: 'SM-8091',
        quantity: 2,
        unitCost: 8500,
        unitPrice: 11500,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        notes: 'Customer: Fahim Ahmed',
      ),
      Sale(
        id: 's2',
        productId: '4',
        productName: 'Xiaomi Redmi Smart Band 2',
        brandName: 'Xiaomi',
        catalogName: 'Redmi Smart Band 2',
        productCode: 'XM-9011',
        quantity: 3,
        unitCost: 2200,
        unitPrice: 2900,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        notes: 'Online order',
      ),
      Sale(
        id: 's3',
        productId: '2',
        productName: 'Apple AirPods Max',
        brandName: 'Apple',
        catalogName: 'AirPods Max',
        productCode: 'AP-4402',
        quantity: 1,
        unitCost: 45000,
        unitPrice: 58000,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'VIP Client',
      ),
      Sale(
        id: 's4',
        productId: '5',
        productName: 'Apex Venturini Leather Wallet',
        brandName: 'Apex',
        catalogName: 'Venturini Leather Wallet',
        productCode: 'APX-771',
        quantity: 4,
        unitCost: 1100,
        unitPrice: 1750,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        notes: 'Retail walk-in',
      ),
    ]);

    purchases.assignAll([
      Purchase(
        id: 'p1',
        productId: '1',
        productName: 'Samsung Galaxy Buds Pro',
        brandName: 'Samsung',
        catalogName: 'Galaxy Buds Pro',
        productCode: 'SM-8091',
        quantity: 26,
        pricePerPiece: 8500,
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
        supplier: 'Samsung Official Distributor BD',
      ),
      Purchase(
        id: 'p2',
        productId: '2',
        productName: 'Apple AirPods Max',
        brandName: 'Apple',
        catalogName: 'AirPods Max',
        productCode: 'AP-4402',
        quantity: 9,
        pricePerPiece: 45000,
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
        supplier: 'iStore Wholesale Hub',
      ),
    ]);

    expenses.assignAll([
      Expense(
        id: 'e1',
        category: 'Rent',
        amount: 25000,
        notes: 'Store & Warehouse rent for current month',
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Expense(
        id: 'e2',
        category: 'Transport & Delivery',
        amount: 3200,
        notes: 'Courier delivery charges (Steadfast/Pathao)',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Expense(
        id: 'e3',
        category: 'Packaging',
        amount: 1800,
        notes: 'Custom branded poly bags & bubble wrap',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 'e4',
        category: 'Utilities',
        amount: 4500,
        notes: 'Electricity and high-speed Wi-Fi',
        date: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ]);

    activityLogs.assignAll([
      ActivityLog(
        id: 'l1',
        type: 'sale',
        title: 'Sale Completed',
        description: '2x Samsung Galaxy Buds Pro sold for ৳23,000 (Profit: ৳6,000)',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ActivityLog(
        id: 'l2',
        type: 'expense',
        title: 'Expense Added',
        description: 'Packaging: ৳1,800',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ActivityLog(
        id: 'l3',
        type: 'sale',
        title: 'High-Value Sale',
        description: '1x Apple AirPods Max sold for ৳58,000 (Profit: ৳13,000)',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ActivityLog(
        id: 'l4',
        type: 'product_add',
        title: 'New Product Added',
        description: 'Apex Venturini Leather Wallet registered with 18 units.',
        timestamp: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ]);

    _seedDefaultUsers();
    saveToLocal();
  }

  void _seedDefaultUsers() {
    users.assignAll([
      AppUser(
        id: 'u1',
        name: 'Sourov Hasan (Owner)',
        email: 'owner@stockmate.com',
        role: 'Super Admin (Owner)',
        approvalStatus: 'approved',
        deviceName: 'Primary Admin Device (PC/Phone)',
      ),
      AppUser(
        id: 'u2',
        name: 'Tanvir Ahmed',
        email: 'tanvir@stockmate.com',
        role: 'Manager',
        approvalStatus: 'approved',
        deviceName: 'Manager Terminal (Tab)',
      ),
      AppUser(
        id: 'u3',
        name: 'Sabbir Hossain',
        email: 'sabbir@stockmate.com',
        role: 'Staff',
        approvalStatus: 'pending',
        deviceName: 'Sales POS Handheld',
      ),
    ]);
  }
}
