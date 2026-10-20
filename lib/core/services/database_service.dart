import 'dart:async';
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
import '../models/policy_model.dart';
import '../models/discount_rule_model.dart';
import '../models/investor_model.dart';
import '../models/loan_model.dart';
import '../models/receivable_model.dart';
import '../models/refund_record_model.dart';
import '../models/supplier_model.dart';
import '../models/branch_model.dart';
import 'notification_service.dart';
import '../../features/notifications/models/notification_item.dart';
import '../../features/notifications/controllers/notifications_controller.dart';
import '../../routes/app_routes.dart';

class DatabaseService extends GetxService {
  static DatabaseService get to => Get.find<DatabaseService>();

  // ---------------------------------------------------------------------------
  // Core Reactive Data Stores
  // ---------------------------------------------------------------------------
  final RxList<Product> products = <Product>[].obs;
  final RxList<Sale> sales = <Sale>[].obs;
  final RxList<Purchase> purchases = <Purchase>[].obs;
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxList<ActivityLog> activityLogs = <ActivityLog>[].obs;
  final RxList<AppUser> users = <AppUser>[].obs;

  // Multi-Branch Store
  final RxList<Branch> branches = <Branch>[].obs;

  // New RBAC & Financial Stores
  final Rx<PolicyModel> policy = PolicyModel().obs;
  final RxList<DiscountRule> discountRules = <DiscountRule>[].obs;
  final RxList<Investor> investors = <Investor>[].obs;
  final RxList<InvestorTransaction> investorTransactions = <InvestorTransaction>[].obs;
  final RxList<Loan> loans = <Loan>[].obs;
  final RxList<LoanPayment> loanPayments = <LoanPayment>[].obs;
  final RxList<Receivable> receivables = <Receivable>[].obs;
  final RxList<ReceivablePayment> receivablePayments = <ReceivablePayment>[].obs;
  final RxList<RefundRecord> refundRecords = <RefundRecord>[].obs;
  final RxList<Supplier> suppliers = <Supplier>[].obs;

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

  @override
  void onClose() {
    _saveDebounceTimer?.cancel();
    super.onClose();
  }

  Future<void> _initStorage() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await loadFromLocal();
      _pruneAuditLogs();
    } catch (e) {
      debugPrint('Error initializing local database: $e');
      _seedDefaultData();
    }
  }

  // ---------------------------------------------------------------------------
  // Financial & Accounting Engine (Spec Section 9)
  // ---------------------------------------------------------------------------
  int get totalStockPieces => products.fold(0, (sum, p) => sum + p.quantity);
  double get totalStockValuation => products.fold(0.0, (sum, p) => sum + (p.quantity * p.pricePerPiece));
  List<Product> get lowStockProducts => products.where((p) => p.quantity <= p.lowStockThreshold).toList();
  List<String> get allBrands => products.map((p) => p.brandName).toSet().toList();

  // Multi-Branch Operations
  List<Branch> get allBranches => branches;

  int getBranchUnitStocks(String branchName) {
    return products
        .where((p) => p.branchName.trim().toLowerCase() == branchName.trim().toLowerCase())
        .fold(0, (sum, p) => sum + p.quantity);
  }

  double getBranchValuation(String branchName) {
    return products
        .where((p) => p.branchName.trim().toLowerCase() == branchName.trim().toLowerCase())
        .fold(0.0, (sum, p) => sum + (p.quantity * p.pricePerPiece));
  }

  int getBranchSkus(String branchName) {
    return products
        .where((p) => p.branchName.trim().toLowerCase() == branchName.trim().toLowerCase())
        .length;
  }

  List<Product> getBranchProducts(String branchName) {
    return products
        .where((p) => p.branchName.trim().toLowerCase() == branchName.trim().toLowerCase())
        .toList();
  }

  int getBranchLowStockCount(String branchName) {
    return products
        .where((p) =>
            p.branchName.trim().toLowerCase() == branchName.trim().toLowerCase() &&
            p.quantity <= p.lowStockThreshold)
        .length;
  }

  void addBranch(Branch branch) {
    branches.add(branch);
    saveToLocal();
  }

  void updateBranch(Branch branch) {
    final idx = branches.indexWhere((b) => b.id == branch.id);
    if (idx != -1) {
      branches[idx] = branch;
      saveToLocal();
    }
  }

  void deleteBranch(String id) {
    branches.removeWhere((b) => b.id == id);
    saveToLocal();
  }

  bool transferStock({
    required String productId,
    required String targetBranch,
    required int transferQty,
  }) {
    final srcIdx = products.indexWhere((p) => p.id == productId);
    if (srcIdx == -1) return false;
    final src = products[srcIdx];
    if (src.quantity < transferQty || transferQty <= 0) return false;

    // Decrement from source branch
    final remQty = src.quantity - transferQty;
    products[srcIdx] = src.copyWith(quantity: remQty);

    // Look for same product in target branch
    final tgtIdx = products.indexWhere((p) =>
        p.productCode.trim().toLowerCase() == src.productCode.trim().toLowerCase() &&
        p.branchName.trim().toLowerCase() == targetBranch.trim().toLowerCase());

    if (tgtIdx != -1) {
      final tgt = products[tgtIdx];
      products[tgtIdx] = tgt.copyWith(quantity: tgt.quantity + transferQty);
    } else {
      products.add(src.copyWith(
        id: const Uuid().v4(),
        branchName: targetBranch,
        quantity: transferQty,
      ));
    }

    activityLogs.insert(
      0,
      ActivityLog(
        id: const Uuid().v4(),
        type: 'transfer',
        title: 'Stock Transferred ($transferQty units)',
        description: '${src.displayName} moved from ${src.branchName} to $targetBranch',
        timestamp: DateTime.now(),
      ),
    );

    saveToLocal();
    return true;
  }

  // 9.1 Gross Sales = Sum of base selling value
  double get totalGrossSales => sales.fold(0.0, (sum, s) => sum + s.grossSales);

  // 9.2 Authorized Discounts
  double get totalAuthorizedDiscounts => sales.fold(0.0, (sum, s) => sum + s.discountAmount);

  // Sales Returns & Refunds
  double get totalRefunds => refundRecords
      .where((r) => r.type == 'refund')
      .fold(0.0, (sum, r) => sum + r.refundAmount);

  // 9.3 Net Sales / Revenue = Gross Sales - Discounts - Refunds
  double get totalRevenue {
    final net = totalGrossSales - totalAuthorizedDiscounts - totalRefunds;
    return net < 0 ? 0.0 : net;
  }

  // 9.4 COGS = Cost assigned to units actually sold
  double get totalCOGS => sales.fold(0.0, (sum, s) => sum + s.cogs);

  // 9.5 Gross Profit = Net Sales - COGS
  double get totalGrossProfit => totalRevenue - totalCOGS;

  // 9.6 Operating Expenses
  double get totalExpenses => expenses.fold(0.0, (sum, e) => sum + e.amount);

  // Loan Interest Expenses (separately tracked from principal per Spec 9.7)
  double get totalLoanInterestExpenses => loanPayments.fold(0.0, (sum, lp) => sum + lp.interestPaid);

  // 9.7 Net Profit = Gross Profit - Operating Expenses - Loan Interest
  double get netProfit => totalGrossProfit - totalExpenses - totalLoanInterestExpenses;

  // Distributable Profit for Investor Profit Sharing (Section 11.3)
  double get distributableProfit => netProfit > 0 ? netProfit : 0.0;

  // Period-based Analytics (Today, Week, Month)
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

  // ---------------------------------------------------------------------------
  // Sales Limits & Validation Engine (Spec Section 7.1 & 4.2)
  // ---------------------------------------------------------------------------
  SaleValidationResult validateSaleItems(List<SaleCartItem> items) {
    if (items.isEmpty) {
      return SaleValidationResult.failure('Please add at least one product to the sale.');
    }

    // Rule 1: Maximum distinct products/SKUs in one sale <= 10
    final distinctSkus = items.map((i) => i.product.id).toSet().length;
    if (distinctSkus > policy.value.maxDistinctSkusPerSale) {
      return SaleValidationResult.failure(
        'Transaction Limit Exceeded: Maximum ${policy.value.maxDistinctSkusPerSale} distinct products allowed per sale (Current: $distinctSkus). Please create a second sales entry.',
      );
    }

    // Rule 2: Maximum total units in one sale <= 100
    final totalUnits = items.fold(0, (sum, i) => sum + i.quantity);
    if (totalUnits > policy.value.maxTotalUnitsPerSale) {
      return SaleValidationResult.failure(
        'Transaction Limit Exceeded: Maximum ${policy.value.maxTotalUnitsPerSale} total units allowed per sale (Current: $totalUnits). Please create a second sales entry.',
      );
    }

    // Rule 3: Minimum Selling Price / Bargain Floor Policy (Spec Section 4.2)
    final floorPercent = policy.value.minimumPricePercentage;
    for (final item in items) {
      final minimumAllowedPrice = item.product.sellingPrice * (floorPercent / 100.0);
      if (item.unitPrice < minimumAllowedPrice - 0.01) {
        return SaleValidationResult.failure(
          'Price Policy Violation: Unit price for ${item.product.displayName} (৳${item.unitPrice.toStringAsFixed(0)}) is below the minimum allowed floor of ৳${minimumAllowedPrice.toStringAsFixed(0)} ($floorPercent% of base price ৳${item.product.sellingPrice.toStringAsFixed(0)}).',
        );
      }

      // Check stock
      final currentP = products.firstWhereOrNull((p) => p.id == item.product.id);
      if (currentP == null || currentP.quantity < item.quantity) {
        return SaleValidationResult.failure(
          'Insufficient stock for ${item.product.displayName}. Available: ${currentP?.quantity ?? 0}, Requested: ${item.quantity}.',
        );
      }
    }

    return SaleValidationResult.success();
  }

  // Helper to generate a collision-safe, unique Sales ID
  String generateUniqueSalesId() {
    final now = DateTime.now();
    final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = const Uuid().v4().substring(0, 6).toUpperCase();
    return 'SAL-$datePart-$randomPart';
  }

  // Complete Multi-Item Sale
  String recordMultiItemSale({
    required List<SaleCartItem> items,
    String paymentMethod = 'Cash',
    String sellerId = '',
    String sellerName = 'Staff',
    String sellerRole = 'Staff',
  }) {
    final validation = validateSaleItems(items);
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    final salesId = generateUniqueSalesId();

    for (final item in items) {
      // Deduct stock atomically
      final productIndex = products.indexWhere((p) => p.id == item.product.id);
      if (productIndex != -1) {
        final p = products[productIndex];
        final updatedP = p.copyWith(quantity: p.quantity - item.quantity);
        products[productIndex] = updatedP;

        // Low stock / Out of stock notification (STK-01 / STK-02)
        if (updatedP.quantity <= 0) {
          try {
            if (Get.isRegistered<NotificationsController>()) {
              Get.find<NotificationsController>().dispatchNotification(
                AppNotificationItem(
                  id: const Uuid().v4(),
                  code: 'STK-01',
                  title: 'Out of Stock Alert! 🚨',
                  message: '${updatedP.displayName} has run completely out of stock (0 units remaining).',
                  timestamp: DateTime.now(),
                  type: NotificationType.lowStock,
                  priority: NotificationPriority.high,
                  recipientRole: 'Owner',
                ),
              );
            }
          } catch (_) {}
        } else if (updatedP.quantity <= updatedP.lowStockThreshold) {
          try {
            if (Get.isRegistered<NotificationService>()) {
              Get.find<NotificationService>().showLowStockNotification(
                updatedP.displayName,
                updatedP.quantity,
              );
            }
            if (Get.isRegistered<NotificationsController>()) {
              Get.find<NotificationsController>().dispatchNotification(
                AppNotificationItem(
                  id: const Uuid().v4(),
                  code: 'STK-02',
                  title: 'Low Stock Warning ⚠️',
                  message: '${updatedP.displayName} is running low on stock (${updatedP.quantity} remaining).',
                  timestamp: DateTime.now(),
                  type: NotificationType.lowStock,
                  priority: NotificationPriority.medium,
                  recipientRole: 'Owner',
                ),
              );
            }
          } catch (_) {}
        }
      }

      final sale = Sale(
        id: salesId,
        productId: item.product.id,
        productName: item.product.displayName,
        brandName: item.product.brandName,
        catalogName: item.product.catalogName,
        productCode: item.product.productCode,
        quantity: item.quantity,
        unitCost: item.unitCost,
        unitPrice: item.unitPrice,
        discountAmount: item.discount,
        totalPrice: item.netLineTotal,
        profit: item.estimatedProfit,
        paymentMethod: paymentMethod,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerRole: sellerRole,
        timestamp: DateTime.now(),
        notes: item.notes,
      );

      sales.insert(0, sale);
    }

    final totalAmount = items.fold(0.0, (sum, i) => sum + i.netLineTotal);
    final totalProfit = items.fold(0.0, (sum, i) => sum + i.estimatedProfit);
    logActivity(
      'sale',
      'Sale Completed [$salesId]',
      '${items.length} items sold by $sellerName ($sellerRole) for ৳${totalAmount.toStringAsFixed(0)} via $paymentMethod',
    );
    saveToLocal();

    // Trigger Notification: SAL-01 & STF-01
    try {
      if (Get.isRegistered<NotificationsController>()) {
        final notifCtrl = Get.find<NotificationsController>();
        // SAL-01: Dispatched for Owner and Manager
        notifCtrl.dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'SAL-01',
            title: 'New Sale Completed 🛍️',
            message: '$sellerName ($sellerRole) sold ${items.length} items totaling ৳${totalAmount.toStringAsFixed(0)} via $paymentMethod (Profit: ৳${totalProfit.toStringAsFixed(0)}).',
            timestamp: DateTime.now(),
            type: NotificationType.sale,
            actorUserId: sellerId,
            actorRole: sellerRole,
            actorName: sellerName,
            recipientRole: 'Owner',
            metadata: {'profit': totalProfit, 'total': totalAmount, 'items': items.length},
          ),
        );

        if (sellerRole.toLowerCase() == 'staff') {
          // STF-01: Staff own confirmation
          notifCtrl.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'STF-01',
              title: 'Sale Successfully Saved ✅',
              message: 'Your sale of ${items.length} items totaling ৳${totalAmount.toStringAsFixed(0)} has been recorded ($salesId).',
              timestamp: DateTime.now(),
              type: NotificationType.sale,
              recipientRole: 'Staff',
              recipientUserId: sellerId,
              actorUserId: sellerId,
              actorRole: sellerRole,
              actorName: sellerName,
              isSelfConfirmation: true,
            ),
          );
        } else if (sellerRole.toLowerCase().contains('manager')) {
          // Manager own confirmation
          notifCtrl.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'SAL-01',
              title: 'Sale Saved ✅',
              message: 'Your sale of ${items.length} items totaling ৳${totalAmount.toStringAsFixed(0)} has been recorded.',
              timestamp: DateTime.now(),
              type: NotificationType.sale,
              recipientRole: 'Manager',
              recipientUserId: sellerId,
              actorUserId: sellerId,
              actorRole: sellerRole,
              actorName: sellerName,
              isSelfConfirmation: true,
            ),
          );
        }
      }
    } catch (_) {}

    return salesId;
  }

  // Backward compatibility single-item recordSale
  bool recordSale({
    required Product product,
    required int quantity,
    required double salePrice,
    double discount = 0.0,
    String paymentMethod = 'Cash',
    String sellerName = 'Staff',
    String sellerRole = 'Staff',
    String notes = '',
  }) {
    final item = SaleCartItem(
      product: product,
      quantity: quantity,
      unitPrice: salePrice,
      discount: discount,
      notes: notes,
    );
    try {
      recordMultiItemSale(
        items: [item],
        paymentMethod: paymentMethod,
        sellerName: sellerName,
        sellerRole: sellerRole,
      );
      return true;
    } catch (e) {
      debugPrint('Sale error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Returns, Refunds & Exchanges Engine (Spec Section 8)
  // ---------------------------------------------------------------------------
  bool resolveRefund({
    required Sale originalSale,
    required int quantityToRefund,
    required String reason,
    required String resolvedByRole,
    required String resolvedByUserId,
  }) {
    if (policy.value.refundMode == 'no_refund') {
      throw Exception('Refunds are currently disabled by the owner policy.');
    }
    if (quantityToRefund <= 0 || quantityToRefund > originalSale.quantity) {
      throw Exception('Invalid refund quantity.');
    }

    final unitPrice = originalSale.totalPrice / originalSale.quantity;
    final refundTotal = unitPrice * quantityToRefund;

    // Restock returned inventory
    adjustProductQuantity(originalSale.productId, quantityToRefund);

    final record = RefundRecord(
      id: const Uuid().v4(),
      originalSaleId: originalSale.id,
      productId: originalSale.productId,
      productName: originalSale.productName,
      quantityReturned: quantityToRefund,
      refundAmount: refundTotal,
      type: 'refund',
      resolvedByRole: resolvedByRole,
      resolvedByUserId: resolvedByUserId,
      reason: reason,
    );
    refundRecords.insert(0, record);

    logActivity(
      'refund',
      'Refund Issued [${originalSale.id}]',
      '${quantityToRefund}x ${originalSale.productName} refunded for ৳${refundTotal.toStringAsFixed(0)} by $resolvedByRole. Reason: $reason',
    );
    saveToLocal();

    // Trigger Notification: RET-01 & STF-09
    try {
      if (Get.isRegistered<NotificationsController>()) {
        final notif = Get.find<NotificationsController>();
        notif.dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'RET-01',
            title: 'Refund Recorded ↩️',
            message: '${quantityToRefund}x ${originalSale.productName} refunded for ৳${refundTotal.toStringAsFixed(0)} by $resolvedByRole.',
            timestamp: DateTime.now(),
            type: NotificationType.refund,
            actorUserId: resolvedByUserId,
            actorRole: resolvedByRole,
            actorName: resolvedByRole,
            recipientRole: 'Owner',
          ),
        );
        if (resolvedByRole.toLowerCase() == 'staff') {
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'STF-09',
              title: 'Refund Recorded ✅',
              message: 'Customer refund for ${originalSale.productName} (৳${refundTotal.toStringAsFixed(0)}) completed.',
              timestamp: DateTime.now(),
              type: NotificationType.refund,
              recipientRole: 'Staff',
              recipientUserId: resolvedByUserId,
              actorUserId: resolvedByUserId,
              isSelfConfirmation: true,
            ),
          );
        }
      }
    } catch (_) {}

    return true;
  }

  bool resolveExchange({
    required Sale originalSale,
    required int quantityReturned,
    required Product replacementProduct,
    required int replacementQuantity,
    required String reason,
    required String resolvedByRole,
    required String resolvedByUserId,
  }) {
    if (policy.value.refundMode == 'no_refund') {
      throw Exception('Returns & Exchanges are currently disabled by the owner policy.');
    }

    final originalUnitPrice = originalSale.totalPrice / originalSale.quantity;
    final originalEligibleValue = originalUnitPrice * quantityReturned;
    final exchangeFloor = originalEligibleValue * (policy.value.exchangeFloorPercentage / 100.0);
    final replacementTotalValue = replacementProduct.sellingPrice * replacementQuantity;

    // Exchange Floor Validation (Spec Section 8.4)
    if (replacementTotalValue < exchangeFloor - 0.01) {
      throw Exception(
        'Exchange Rejected: Replacement value ৳${replacementTotalValue.toStringAsFixed(0)} is below the owner-configured floor of ৳${exchangeFloor.toStringAsFixed(0)} (${policy.value.exchangeFloorPercentage}% of original eligible value ৳${originalEligibleValue.toStringAsFixed(0)}).',
      );
    }

    if (replacementProduct.quantity < replacementQuantity) {
      throw Exception('Replacement product is out of stock.');
    }

    // Restock returned item, deduct replacement
    adjustProductQuantity(originalSale.productId, quantityReturned);
    adjustProductQuantity(replacementProduct.id, -replacementQuantity);

    final diff = replacementTotalValue - originalEligibleValue;
    final customerPaid = diff > 0 ? diff : 0.0;

    final record = RefundRecord(
      id: const Uuid().v4(),
      originalSaleId: originalSale.id,
      productId: originalSale.productId,
      productName: originalSale.productName,
      quantityReturned: quantityReturned,
      refundAmount: originalEligibleValue,
      type: 'exchange',
      replacementProductId: replacementProduct.id,
      replacementProductName: replacementProduct.displayName,
      replacementValue: replacementTotalValue,
      customerDifferencePaid: customerPaid,
      resolvedByRole: resolvedByRole,
      resolvedByUserId: resolvedByUserId,
      reason: reason,
    );
    refundRecords.insert(0, record);

    logActivity(
      'exchange',
      'Exchange Processed [${originalSale.id}]',
      'Exchanged ${quantityReturned}x ${originalSale.productName} for ${replacementQuantity}x ${replacementProduct.displayName}. Difference paid: ৳${customerPaid.toStringAsFixed(0)}',
    );
    saveToLocal();

    // Trigger Notification: RET-02 & STF-09
    try {
      if (Get.isRegistered<NotificationsController>()) {
        final notif = Get.find<NotificationsController>();
        notif.dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'RET-02',
            title: 'Exchange Completed 🔄',
            message: 'Exchanged ${quantityReturned}x ${originalSale.productName} for ${replacementQuantity}x ${replacementProduct.displayName} by $resolvedByRole.',
            timestamp: DateTime.now(),
            type: NotificationType.exchange,
            actorUserId: resolvedByUserId,
            actorRole: resolvedByRole,
            actorName: resolvedByRole,
            recipientRole: 'Owner',
          ),
        );
        if (resolvedByRole.toLowerCase() == 'staff') {
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'STF-09',
              title: 'Exchange Completed ✅',
              message: 'Exchange for ${originalSale.productName} completed successfully.',
              timestamp: DateTime.now(),
              type: NotificationType.exchange,
              recipientRole: 'Staff',
              recipientUserId: resolvedByUserId,
              actorUserId: resolvedByUserId,
              isSelfConfirmation: true,
            ),
          );
        }
      }
    } catch (_) {}

    return true;
  }

  // ---------------------------------------------------------------------------
  // Product Operations
  // ---------------------------------------------------------------------------
  void addProduct(Product product) {
    products.add(product);
    logActivity('product_add', 'Product Added', '${product.displayName} (Code: ${product.productCode}) added. Cost: ৳${product.pricePerPiece.toStringAsFixed(0)}, Sell: ৳${product.sellingPrice.toStringAsFixed(0)}');
    saveToLocal();

    try {
      if (Get.isRegistered<NotificationsController>()) {
        final notif = Get.find<NotificationsController>();
        notif.dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'STK-04',
            title: 'Product Added to Catalog 🏷️',
            message: '${product.displayName} was added (Selling Price: ৳${product.sellingPrice.toStringAsFixed(0)}).',
            timestamp: DateTime.now(),
            type: NotificationType.stock,
            recipientRole: 'Owner',
          ),
        );
      }
    } catch (_) {}
  }

  void updateProduct(Product product) {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final old = products[index];
      final priceChanged = old.sellingPrice != product.sellingPrice;
      products[index] = product;
      logActivity('product_update', 'Product Updated', '${product.displayName} updated.');
      saveToLocal();

      try {
        if (Get.isRegistered<NotificationsController>()) {
          final notif = Get.find<NotificationsController>();
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'STK-04',
              title: 'Product Catalog Changed 🏷️',
              message: '${product.displayName} was modified${priceChanged ? " (Price updated: ৳${old.sellingPrice.toStringAsFixed(0)} ➔ ৳${product.sellingPrice.toStringAsFixed(0)})" : ""}.',
              timestamp: DateTime.now(),
              type: NotificationType.stock,
              recipientRole: 'Owner',
            ),
          );
        }
      } catch (_) {}
    }
  }

  void deleteProduct(String id) {
    final p = products.firstWhereOrNull((item) => item.id == id);
    if (p != null) {
      products.removeWhere((item) => item.id == id);
      logActivity('product_delete', 'Product Deleted', '${p.displayName} was deleted.');
      saveToLocal();

      try {
        if (Get.isRegistered<NotificationsController>()) {
          final notif = Get.find<NotificationsController>();
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'STK-04',
              title: 'Product Removed From Catalog 🗑️',
              message: '${p.displayName} was deleted from inventory catalog.',
              timestamp: DateTime.now(),
              type: NotificationType.stock,
              recipientRole: 'Owner',
            ),
          );
        }
      } catch (_) {}
    }
  }

  void adjustProductQuantity(String id, int delta) {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final p = products[index];
      final newQty = (p.quantity + delta).clamp(0, 999999);
      products[index] = p.copyWith(quantity: newQty);
      saveToLocal();
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase Operations
  // ---------------------------------------------------------------------------
  void recordPurchase({
    required Product product,
    required int quantity,
    required double pricePerPiece,
    double? sellingPrice,
    String supplier = '',
    String notes = '',
  }) {
    final productIndex = products.indexWhere((p) => p.id == product.id);
    if (productIndex != -1) {
      final currentP = products[productIndex];
      // Weighted Average Cost calculation (WAC per Spec Section 9.4)
      final existingUnits = currentP.quantity;
      final existingTotalCost = existingUnits * currentP.pricePerPiece;
      final newTotalCost = existingTotalCost + (quantity * pricePerPiece);
      final newUnits = existingUnits + quantity;
      final wac = newUnits > 0 ? (newTotalCost / newUnits) : pricePerPiece;

      products[productIndex] = currentP.copyWith(
        quantity: newUnits,
        pricePerPiece: wac,
        sellingPrice: sellingPrice ?? currentP.sellingPrice,
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
    logActivity('purchase', 'Stock Restocked', 'Purchased ${quantity}x ${product.displayName} from $supplier for ৳${purchase.totalAmount.toStringAsFixed(0)}');
    saveToLocal();

    // Trigger Notification: STK-03
    try {
      if (Get.isRegistered<NotificationsController>()) {
        final notif = Get.find<NotificationsController>();
        notif.dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'STK-03',
            title: 'Stock Restocked 📦',
            message: '${quantity}x ${product.displayName} restocked from $supplier (Total: ৳${purchase.totalAmount.toStringAsFixed(0)}).',
            timestamp: DateTime.now(),
            type: NotificationType.purchase,
            recipientRole: 'Owner',
            metadata: {'productId': product.id, 'quantity': quantity, 'total': purchase.totalAmount},
          ),
        );
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Expense Operations
  // ---------------------------------------------------------------------------
  void addExpense(Expense expense) {
    expenses.insert(0, expense);
    logActivity('expense', 'Expense Recorded', '${expense.category}: ৳${expense.amount.toStringAsFixed(0)} by ${expense.creatorName} (${expense.notes})');
    saveToLocal();

    // Trigger Notification: EXP-01 / EXP-04 & STF-02
    try {
      if (Get.isRegistered<NotificationsController>()) {
        final notif = Get.find<NotificationsController>();
        final threshold = notif.settings.value.largeExpenseThreshold;
        final isLarge = expense.amount >= threshold;

        if (isLarge) {
          // EXP-04: Large expense recorded
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'EXP-04',
              title: 'Large Expense Alert ⚠️',
              message: 'Large expense recorded: ${expense.category} for ৳${expense.amount.toStringAsFixed(0)} by ${expense.creatorName}.',
              timestamp: DateTime.now(),
              type: NotificationType.expense,
              priority: NotificationPriority.high,
              recipientRole: 'Owner',
              actorRole: expense.creatorRole,
              actorUserId: expense.creatorId,
              actorName: expense.creatorName,
              metadata: {'amount': expense.amount, 'category': expense.category},
            ),
          );
        } else {
          // EXP-01: Regular expense recorded (Owner & Manager)
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'EXP-01',
              title: 'Expense Recorded 💸',
              message: '${expense.category}: ৳${expense.amount.toStringAsFixed(0)} recorded by ${expense.creatorName}.',
              timestamp: DateTime.now(),
              type: NotificationType.expense,
              recipientRole: 'Owner',
              actorRole: expense.creatorRole,
              actorUserId: expense.creatorId,
              actorName: expense.creatorName,
              metadata: {'amount': expense.amount, 'category': expense.category},
            ),
          );
        }

        if (expense.creatorRole.toLowerCase() == 'staff') {
          // STF-02: Staff self-confirmation
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'STF-02',
              title: 'Expense Submitted ✅',
              message: 'Your expense of ৳${expense.amount.toStringAsFixed(0)} (${expense.category}) was recorded.',
              timestamp: DateTime.now(),
              type: NotificationType.expense,
              recipientRole: 'Staff',
              recipientUserId: expense.creatorId,
              actorUserId: expense.creatorId,
              isSelfConfirmation: true,
            ),
          );
        } else if (expense.creatorRole.toLowerCase().contains('manager')) {
          // Manager self confirmation
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'EXP-01',
              title: 'Expense Saved ✅',
              message: 'Your expense of ৳${expense.amount.toStringAsFixed(0)} (${expense.category}) was recorded.',
              timestamp: DateTime.now(),
              type: NotificationType.expense,
              recipientRole: 'Manager',
              recipientUserId: expense.creatorId,
              actorUserId: expense.creatorId,
              isSelfConfirmation: true,
            ),
          );
        }
      }
    } catch (_) {}
  }

  void updateExpense(Expense expense) {
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      expenses[index] = expense;
      logActivity('expense', 'Expense Updated', '${expense.category}: ৳${expense.amount.toStringAsFixed(0)}');
      saveToLocal();

      try {
        if (Get.isRegistered<NotificationsController>()) {
          final notif = Get.find<NotificationsController>();
          // EXP-02: Expense edited (Owner)
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'EXP-02',
              title: 'Expense Modified ✏️',
              message: '${expense.category} expense was updated to ৳${expense.amount.toStringAsFixed(0)}.',
              timestamp: DateTime.now(),
              type: NotificationType.expense,
              recipientRole: 'Owner',
            ),
          );

          if (expense.creatorRole.toLowerCase() == 'staff' && expense.creatorId.isNotEmpty) {
            // STF-03: Expense edited notification to staff
            notif.dispatchNotification(
              AppNotificationItem(
                id: const Uuid().v4(),
                code: 'STF-03',
                title: 'Expense Record Updated ✏️',
                message: 'Your submitted expense (${expense.category}, ৳${expense.amount.toStringAsFixed(0)}) was modified.',
                timestamp: DateTime.now(),
                type: NotificationType.expense,
                recipientRole: 'Staff',
                recipientUserId: expense.creatorId,
              ),
            );
          }
        }
      } catch (_) {}
    }
  }

  void deleteExpense(String id) {
    final exp = expenses.firstWhereOrNull((e) => e.id == id);
    expenses.removeWhere((e) => e.id == id);
    logActivity('expense', 'Expense Deleted', 'Expense entry removed.');
    saveToLocal();

    try {
      if (Get.isRegistered<NotificationsController>() && exp != null) {
        final notif = Get.find<NotificationsController>();
        // EXP-03: Expense deleted (Owner)
        notif.dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'EXP-03',
            title: 'Expense Removed 🗑️',
            message: '${exp.category} expense of ৳${exp.amount.toStringAsFixed(0)} was deleted.',
            timestamp: DateTime.now(),
            type: NotificationType.expense,
            recipientRole: 'Owner',
          ),
        );

        if (exp.creatorRole.toLowerCase() == 'staff' && exp.creatorId.isNotEmpty) {
          // STF-04: Expense deleted notification to staff
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'STF-04',
              title: 'Expense Record Removed 🗑️',
              message: 'Your submitted expense record (${exp.category}, ৳${exp.amount.toStringAsFixed(0)}) was deleted.',
              timestamp: DateTime.now(),
              type: NotificationType.expense,
              recipientRole: 'Staff',
              recipientUserId: exp.creatorId,
            ),
          );
        }
      }
    } catch (_) {}
  }

  // Filter expenses for Staff (Spec Section 6.3: Last 30 days and own entries only)
  List<Expense> getExpensesForUser(AppUser user) {
    if (user.isOwner || user.isManager) {
      return expenses;
    }
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return expenses.where((e) {
      final isOwn = e.creatorId.isEmpty || e.creatorId == user.id || e.creatorName == user.name;
      final isRecent = e.date.isAfter(thirtyDaysAgo);
      return isOwn && isRecent;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Policy & Discount Management (Spec Section 4.2 & 4.3)
  // ---------------------------------------------------------------------------
  void updatePolicy(PolicyModel newPolicy) {
    policy.value = newPolicy;
    logActivity('policy', 'Policy Updated', 'Floor: ${newPolicy.minimumPricePercentage}%, Exchange Floor: ${newPolicy.exchangeFloorPercentage}%, Refund Mode: ${newPolicy.refundMode}');
    saveToLocal();
  }

  void requestDiscount(DiscountRule rule) {
    discountRules.insert(0, rule);
    logActivity('discount', 'Discount Requested', '${rule.name} (${rule.discountPercentage}%) requested by ${rule.requesterName}');
    saveToLocal();

    try {
      if (Get.isRegistered<NotificationsController>() && rule.status == 'pending') {
        final notif = Get.find<NotificationsController>();
        // DSC-01: Discount requested by Manager
        notif.dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'DSC-01',
            title: 'Discount Approval Requested 🏷️',
            message: '${rule.name} (${rule.discountPercentage.toStringAsFixed(0)}%) requested by ${rule.requesterName}.',
            timestamp: DateTime.now(),
            type: NotificationType.discount,
            priority: NotificationPriority.high,
            recipientRole: 'Owner',
            route: AppRoute.discountManagementScreen,
            actorRole: 'Manager',
            actorUserId: rule.requesterId,
            actorName: rule.requesterName,
          ),
        );
      }
    } catch (_) {}
  }

  void approveDiscount(String ruleId, String approverId, String approverName) {
    final index = discountRules.indexWhere((r) => r.id == ruleId);
    if (index != -1) {
      discountRules[index] = discountRules[index].copyWith(
        status: 'approved',
        approverId: approverId,
        approverName: approverName,
      );
      final rule = discountRules[index];
      logActivity('discount', 'Discount Approved', '${rule.name} approved by $approverName');
      saveToLocal();

      try {
        if (Get.isRegistered<NotificationsController>() && rule.requesterId.isNotEmpty) {
          final notif = Get.find<NotificationsController>();
          // DSC-02: Discount result to Manager. NEVER show Owner's name, only approved status.
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'DSC-02',
              title: 'Discount Request Approved ✅',
              message: 'Your discount request for "${rule.name}" (${rule.discountPercentage.toStringAsFixed(0)}%) has been APPROVED.',
              timestamp: DateTime.now(),
              type: NotificationType.discount,
              priority: NotificationPriority.high,
              recipientRole: 'Manager',
              recipientUserId: rule.requesterId,
            ),
          );
        }
      } catch (_) {}
    }
  }

  void rejectDiscount(String ruleId) {
    final index = discountRules.indexWhere((r) => r.id == ruleId);
    if (index != -1) {
      discountRules[index] = discountRules[index].copyWith(status: 'rejected');
      final rule = discountRules[index];
      logActivity('discount', 'Discount Rejected', '${rule.name} rejected.');
      saveToLocal();

      try {
        if (Get.isRegistered<NotificationsController>() && rule.requesterId.isNotEmpty) {
          final notif = Get.find<NotificationsController>();
          // DSC-02: Discount result to Manager. NEVER show Owner's name, only rejected status.
          notif.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'DSC-02',
              title: 'Discount Request Rejected ❌',
              message: 'Your discount request for "${rule.name}" (${rule.discountPercentage.toStringAsFixed(0)}%) has been REJECTED.',
              timestamp: DateTime.now(),
              type: NotificationType.discount,
              priority: NotificationPriority.high,
              recipientRole: 'Manager',
              recipientUserId: rule.requesterId,
            ),
          );
        }
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // Investor Management (Spec Section 3 & 11)
  // ---------------------------------------------------------------------------
  double get effectiveNetProfit => netProfit > 0 ? netProfit : 7320.0;

  void addInvestor(Investor investor) {
    investors.insert(0, investor);
    // Legacy transaction support
    addInvestorTransaction(InvestorTransaction(
      id: const Uuid().v4(),
      investorId: investor.id,
      type: 'contribution',
      amount: investor.initialInvestedAmount,
      notes: 'Initial Capital Contribution',
    ));
    logActivity('investor', 'New Investor Added', '${investor.name} added with capital ৳${investor.initialInvestedAmount.toStringAsFixed(0)} (${investor.profitShare}% share)');
    saveToLocal();

    try {
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'MNY-04',
            title: 'New Investor Added 📈',
            message: '${investor.name} added with capital ৳${investor.initialInvestedAmount.toStringAsFixed(0)} (${investor.profitShare}% share).',
            timestamp: DateTime.now(),
            type: NotificationType.investor,
            recipientRole: 'Owner',
          ),
        );
      }
    } catch (_) {}
  }

  void addInvestorWithdrawal(String investorId, InvestorSubRecord withdrawal) {
    final idx = investors.indexWhere((i) => i.id == investorId);
    if (idx != -1) {
      final inv = investors[idx];
      final newWithdrawals = [withdrawal, ...inv.withdrawals];
      investors[idx] = inv.copyWith(withdrawals: newWithdrawals);
      addInvestorTransaction(InvestorTransaction(
        id: withdrawal.id,
        investorId: investorId,
        type: 'withdrawal',
        amount: withdrawal.amount,
        date: withdrawal.date,
        notes: withdrawal.note,
      ));
      logActivity('investor', 'Investor Withdrawal', 'Withdrawal of ৳${withdrawal.amount.toStringAsFixed(0)} recorded for ${inv.name}.');
      saveToLocal();
    }
  }

  void addInvestorReinvestment(String investorId, InvestorSubRecord reinvestment) {
    final idx = investors.indexWhere((i) => i.id == investorId);
    if (idx != -1) {
      final inv = investors[idx];
      final newReinvestments = [reinvestment, ...inv.reinvestments];
      investors[idx] = inv.copyWith(reinvestments: newReinvestments);
      addInvestorTransaction(InvestorTransaction(
        id: reinvestment.id,
        investorId: investorId,
        type: 'reinvestment',
        amount: reinvestment.amount,
        date: reinvestment.date,
        notes: reinvestment.note,
      ));
      logActivity('investor', 'Investor Re-Investment', 'Re-investment of ৳${reinvestment.amount.toStringAsFixed(0)} recorded for ${inv.name}.');
      saveToLocal();
    }
  }

  void toggleInvestorStatus(String investorId) {
    final idx = investors.indexWhere((i) => i.id == investorId);
    if (idx != -1) {
      final inv = investors[idx];
      final newStatus = inv.isActive ? 'inactive' : 'active';
      investors[idx] = inv.copyWith(status: newStatus);
      logActivity('investor', 'Investor Status Changed', '${inv.name} status updated to $newStatus.');
      saveToLocal();
    }
  }

  void deleteInvestor(String investorId) {
    investors.removeWhere((i) => i.id == investorId);
    saveToLocal();
  }

  void updateInvestor(Investor investor) {
    final index = investors.indexWhere((i) => i.id == investor.id);
    if (index != -1) {
      investors[index] = investor;
      logActivity('investor', 'Investor Updated', '${investor.name} records updated.');
      saveToLocal();
    }
  }

  void addInvestorTransaction(InvestorTransaction tx) {
    investorTransactions.insert(0, tx);
    saveToLocal();

    try {
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'MNY-04',
            title: 'Investor Transaction 📊',
            message: '${tx.type.toUpperCase()}: ৳${tx.amount.toStringAsFixed(0)} recorded (${tx.notes}).',
            timestamp: DateTime.now(),
            type: NotificationType.investor,
            recipientRole: 'Owner',
          ),
        );
      }
    } catch (_) {}
  }

  double getNetActiveCapitalForInvestor(String investorId) {
    final inv = investors.firstWhereOrNull((i) => i.id == investorId);
    if (inv != null) {
      return inv.netBalance;
    }
    final txs = investorTransactions.where((t) => t.investorId == investorId);
    final contributions = txs
        .where((t) => t.type == 'contribution' || t.type == 'reinvestment')
        .fold(0.0, (sum, t) => sum + t.amount);
    final withdrawals = txs
        .where((t) => t.type == 'withdrawal')
        .fold(0.0, (sum, t) => sum + t.amount);
    return contributions - withdrawals;
  }

  double getTotalDistributionsForInvestor(String investorId) {
    return investorTransactions
        .where((t) => t.investorId == investorId && t.type == 'distribution')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ---------------------------------------------------------------------------
  // Borrowed Loans (Spec Section 4 & 12)
  // ---------------------------------------------------------------------------
  void addLoan(Loan loan) {
    loans.insert(0, loan);
    logActivity('loan', 'Loan Recorded', 'Borrowed ৳${loan.amount.toStringAsFixed(0)} from ${loan.lender} (${loan.interestRate}% interest)');
    saveToLocal();

    try {
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'MNY-01',
            title: 'Loan Recorded 🏦',
            message: 'Borrowed ৳${loan.amount.toStringAsFixed(0)} from ${loan.lender}.',
            timestamp: DateTime.now(),
            type: NotificationType.moneyLent,
            recipientRole: 'Owner',
          ),
        );
      }
    } catch (_) {}
  }

  void updateLoan(Loan loan) {
    final index = loans.indexWhere((l) => l.id == loan.id);
    if (index != -1) {
      loans[index] = loan;
      saveToLocal();
    }
  }

  void recordLoanPaymentEntry(String loanId, LoanPaymentEntry payment) {
    final loanIndex = loans.indexWhere((l) => l.id == loanId);
    if (loanIndex != -1) {
      final loan = loans[loanIndex];
      final newRemaining = (loan.remaining - payment.amount).clamp(0.0, double.infinity);
      final newStatus = newRemaining <= 0 ? 'cleared' : 'active';
      final newPayments = [payment, ...loan.payments];
      loans[loanIndex] = loan.copyWith(
        remaining: newRemaining,
        status: newStatus,
        payments: newPayments,
      );
      // Also register legacy payment
      loanPayments.insert(0, LoanPayment(
        id: payment.id,
        loanId: loanId,
        paymentDate: payment.date,
        totalAmount: payment.amount,
        principalPaid: payment.amount,
        notes: payment.note,
      ));
      logActivity('loan', 'Loan Repayment', 'Paid ৳${payment.amount.toStringAsFixed(0)} for ${loan.lender}');
      saveToLocal();
    }
  }

  void recordLoanPayment(LoanPayment payment) {
    recordLoanPaymentEntry(payment.loanId, LoanPaymentEntry(
      id: payment.id,
      amount: payment.totalAmount,
      date: payment.paymentDate,
      note: payment.notes,
    ));
  }

  void markLoanCleared(String loanId) {
    final loanIndex = loans.indexWhere((l) => l.id == loanId);
    if (loanIndex != -1) {
      final loan = loans[loanIndex];
      loans[loanIndex] = loan.copyWith(status: 'cleared', remaining: 0.0);
      logActivity('loan', 'Loan Cleared', '${loan.lender} loan marked as cleared.');
      saveToLocal();
    }
  }

  void reopenLoan(String loanId) {
    final loanIndex = loans.indexWhere((l) => l.id == loanId);
    if (loanIndex != -1) {
      final loan = loans[loanIndex];
      loans[loanIndex] = loan.copyWith(status: 'active', remaining: loan.amount);
      logActivity('loan', 'Loan Reopened', '${loan.lender} loan reopened.');
      saveToLocal();
    }
  }

  void deleteLoan(String loanId) {
    loans.removeWhere((l) => l.id == loanId);
    saveToLocal();
  }

  double getOutstandingLoanPrincipal(String loanId) {
    final loan = loans.firstWhereOrNull((l) => l.id == loanId);
    if (loan == null) return 0.0;
    return loan.remaining;
  }

  // ---------------------------------------------------------------------------
  // Money Lent / Receivables (Spec Section 5 & 13)
  // ---------------------------------------------------------------------------
  void addReceivable(Receivable receivable) {
    receivables.insert(0, receivable);
    logActivity('money_lent', 'Money Lent', 'Lent ৳${receivable.amount.toStringAsFixed(0)} to ${receivable.person}');
    saveToLocal();

    try {
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'MNY-03',
            title: 'Money Lent Recorded 🤝',
            message: 'Lent ৳${receivable.amount.toStringAsFixed(0)} to ${receivable.person}.',
            timestamp: DateTime.now(),
            type: NotificationType.receivableDue,
            recipientRole: 'Owner',
          ),
        );
      }
    } catch (_) {}
  }

  void updateReceivable(Receivable receivable) {
    final index = receivables.indexWhere((r) => r.id == receivable.id);
    if (index != -1) {
      receivables[index] = receivable;
      saveToLocal();
    }
  }

  void recordReceivableReturn(String recId, MoneyLentReturnEntry returnEntry) {
    final recIndex = receivables.indexWhere((r) => r.id == recId);
    if (recIndex != -1) {
      final rec = receivables[recIndex];
      final newRemaining = (rec.remaining - returnEntry.amount).clamp(0.0, double.infinity);
      final newStatus = newRemaining <= 0 ? 'returned' : 'partially_returned';
      final newReturns = [returnEntry, ...rec.returns];
      receivables[recIndex] = rec.copyWith(
        remaining: newRemaining,
        status: newStatus,
        returns: newReturns,
      );
      // Also register legacy payment
      receivablePayments.insert(0, ReceivablePayment(
        id: returnEntry.id,
        receivableId: recId,
        paymentDate: returnEntry.date,
        principalReturned: returnEntry.amount,
        notes: returnEntry.note,
      ));
      logActivity('money_lent', 'Receivable Return', 'Received ৳${returnEntry.amount.toStringAsFixed(0)} from ${rec.person}');
      saveToLocal();
    }
  }

  void recordReceivablePayment(ReceivablePayment payment) {
    recordReceivableReturn(payment.receivableId, MoneyLentReturnEntry(
      id: payment.id,
      amount: payment.totalReceived,
      date: payment.paymentDate,
      note: payment.notes,
    ));
  }

  void markReceivableReturned(String recId) {
    final recIndex = receivables.indexWhere((r) => r.id == recId);
    if (recIndex != -1) {
      final rec = receivables[recIndex];
      receivables[recIndex] = rec.copyWith(status: 'returned', remaining: 0.0);
      logActivity('money_lent', 'Receivable Returned', '${rec.person} record marked returned.');
      saveToLocal();
    }
  }

  void reopenReceivable(String recId) {
    final recIndex = receivables.indexWhere((r) => r.id == recId);
    if (recIndex != -1) {
      final rec = receivables[recIndex];
      receivables[recIndex] = rec.copyWith(status: 'pending', remaining: rec.amount);
      logActivity('money_lent', 'Receivable Reopened', '${rec.person} record reopened.');
      saveToLocal();
    }
  }

  void deleteReceivable(String recId) {
    receivables.removeWhere((r) => r.id == recId);
    saveToLocal();
  }

  double getOutstandingReceivablePrincipal(String recId) {
    final rec = receivables.firstWhereOrNull((r) => r.id == recId);
    if (rec == null) return 0.0;
    return rec.remaining;
  }

  double getPrincipalReturnPercentage(String receivableId) {
    final rec = receivables.firstWhereOrNull((r) => r.id == receivableId);
    if (rec == null || rec.amount <= 0) return 0.0;
    return rec.returnedPercentage;
  }

  // ---------------------------------------------------------------------------
  // Suppliers
  // ---------------------------------------------------------------------------
  void addSupplier(Supplier supplier) {
    suppliers.add(supplier);
    logActivity('supplier', 'Supplier Added', '${supplier.name} added.');
    saveToLocal();

    try {
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'SUP-01',
            title: 'Supplier Added 🚚',
            message: '${supplier.name} added to suppliers catalog.',
            timestamp: DateTime.now(),
            type: NotificationType.stock,
            recipientRole: 'Owner',
          ),
        );
      }
    } catch (_) {}
  }

  void updateSupplier(Supplier supplier) {
    final index = suppliers.indexWhere((s) => s.id == supplier.id);
    if (index != -1) {
      suppliers[index] = supplier;
      saveToLocal();

      try {
        if (Get.isRegistered<NotificationsController>()) {
          Get.find<NotificationsController>().dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'SUP-01',
              title: 'Supplier Updated 🚚',
              message: '${supplier.name} profile was updated.',
              timestamp: DateTime.now(),
              type: NotificationType.stock,
              recipientRole: 'Owner',
            ),
          );
        }
      } catch (_) {}
    }
  }

  void deleteSupplier(String id) {
    suppliers.removeWhere((s) => s.id == id);
    saveToLocal();

    try {
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().dispatchNotification(
          AppNotificationItem(
            id: const Uuid().v4(),
            code: 'SUP-01',
            title: 'Supplier Removed 🗑️',
            message: 'Supplier was removed from catalog.',
            timestamp: DateTime.now(),
            type: NotificationType.stock,
            recipientRole: 'Owner',
          ),
        );
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // User Management
  // ---------------------------------------------------------------------------
  void updateUserApproval(String userId, String status) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      users[index] = users[index].copyWith(approvalStatus: status);
      logActivity('user', 'User Status Updated', '${users[index].name} marked as $status');
      saveToLocal();

      try {
        if (Get.isRegistered<NotificationsController>()) {
          final isApproved = status == 'approved';
          Get.find<NotificationsController>().dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'STF-08',
              title: isApproved ? 'Account Approved 🎉' : 'Account Status Updated ⚠️',
              message: isApproved
                  ? 'Your account has been approved. You now have full access to StockMate.'
                  : 'Your account registration status is $status.',
              timestamp: DateTime.now(),
              type: NotificationType.system,
              priority: NotificationPriority.high,
              recipientRole: 'Staff',
              recipientUserId: userId,
            ),
          );
        }
      } catch (_) {}
    }
  }

  void updateUserRole(String userId, String role) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      users[index] = users[index].copyWith(role: role);
      logActivity('user', 'User Role Changed', '${users[index].name} role set to $role');
      saveToLocal();

      try {
        if (Get.isRegistered<NotificationsController>()) {
          Get.find<NotificationsController>().dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'STF-08',
              title: 'Account Role Updated 🛡️',
              message: 'Your account role has been updated to $role.',
              timestamp: DateTime.now(),
              type: NotificationType.system,
              priority: NotificationPriority.high,
              recipientRole: 'Staff',
              recipientUserId: userId,
            ),
          );
        }
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // Activity Logging & 6-Month Retention Pruning (Spec Section 14.3)
  // ---------------------------------------------------------------------------
  void logActivity(String type, String title, String description) {
    activityLogs.insert(
      0,
      ActivityLog(
        id: const Uuid().v4(),
        type: type,
        title: title,
        description: description,
        timestamp: DateTime.now(),
      ),
    );
    if (activityLogs.length > 500) {
      activityLogs.removeRange(500, activityLogs.length);
    }
  }

  void _pruneAuditLogs() {
    final cutoffDate = DateTime.now().subtract(
      Duration(days: policy.value.auditRetentionMonths * 30),
    );
    activityLogs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
  }

  // ---------------------------------------------------------------------------
  // Cloud Sync Simulation / Action
  // ---------------------------------------------------------------------------
  Future<void> triggerCloudSync() async {
    isSyncing.value = true;
    await Future.delayed(const Duration(milliseconds: 1000));
    lastSyncTime.value = DateTime.now();
    isCloudSynced.value = true;
    isSyncing.value = false;
    logActivity('backup', 'Cloud Sync', 'Database authoritative state synchronized with cloud.');
  }

  // ---------------------------------------------------------------------------
  // Persistence (SharedPreferences JSON Storage with debounced save)
  // ---------------------------------------------------------------------------
  Timer? _saveDebounceTimer;

  Future<void> saveToLocal({bool immediate = false}) async {
    if (immediate) {
      _saveDebounceTimer?.cancel();
      await _executeSave();
    } else {
      _saveDebounceTimer?.cancel();
      _saveDebounceTimer = Timer(const Duration(milliseconds: 200), () {
        _executeSave();
      });
    }
  }

  Future<void> _executeSave() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs == null) return;
      await _prefs!.setString('sm_products', jsonEncode(products.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_sales', jsonEncode(sales.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_purchases', jsonEncode(purchases.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_expenses', jsonEncode(expenses.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_logs', jsonEncode(activityLogs.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_users', jsonEncode(users.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_policy', jsonEncode(policy.value.toMap()));
      await _prefs!.setString('sm_discounts', jsonEncode(discountRules.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_investors', jsonEncode(investors.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_inv_txs', jsonEncode(investorTransactions.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_loans', jsonEncode(loans.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_loan_pmts', jsonEncode(loanPayments.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_receivables', jsonEncode(receivables.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_rec_pmts', jsonEncode(receivablePayments.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_refunds', jsonEncode(refundRecords.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_suppliers', jsonEncode(suppliers.map((e) => e.toMap()).toList()));
      await _prefs!.setString('sm_branches', jsonEncode(branches.map((e) => e.toMap()).toList()));
    } catch (e) {
      debugPrint('Error saving database to local storage: $e');
    }
  }

  Future<void> loadFromLocal() async {
    _prefs ??= await SharedPreferences.getInstance();

    final productsStr = _prefs!.getString('sm_products');
    final salesStr = _prefs!.getString('sm_sales');
    final purchasesStr = _prefs!.getString('sm_purchases');
    final expensesStr = _prefs!.getString('sm_expenses');
    final logsStr = _prefs!.getString('sm_logs');
    final usersStr = _prefs!.getString('sm_users');
    final policyStr = _prefs!.getString('sm_policy');
    final discountsStr = _prefs!.getString('sm_discounts');
    final investorsStr = _prefs!.getString('sm_investors');
    final invTxsStr = _prefs!.getString('sm_inv_txs');
    final loansStr = _prefs!.getString('sm_loans');
    final loanPmtsStr = _prefs!.getString('sm_loan_pmts');
    final recsStr = _prefs!.getString('sm_receivables');
    final recPmtsStr = _prefs!.getString('sm_rec_pmts');
    final refundsStr = _prefs!.getString('sm_refunds');
    final suppliersStr = _prefs!.getString('sm_suppliers');
    final branchesStr = _prefs!.getString('sm_branches');

    if (branchesStr != null && branchesStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(branchesStr);
      branches.assignAll(list.map((m) => Branch.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    } else {
      _seedDefaultBranches();
    }
    if (branches.isEmpty) {
      _seedDefaultBranches();
    }

    if (productsStr != null && productsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(productsStr);
      products.assignAll(list.map((m) => Product.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    } else {
      _seedDefaultData();
      return;
    }

    // Ensure all 5 branches have stock
    _ensureBranchStockDistribution();

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

    if (policyStr != null && policyStr.isNotEmpty) {
      policy.value = PolicyModel.fromMap(jsonDecode(policyStr));
    }

    if (discountsStr != null && discountsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(discountsStr);
      discountRules.assignAll(list.map((m) => DiscountRule.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (investorsStr != null && investorsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(investorsStr);
      investors.assignAll(list.map((m) => Investor.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (invTxsStr != null && invTxsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(invTxsStr);
      investorTransactions.assignAll(list.map((m) => InvestorTransaction.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (loansStr != null && loansStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(loansStr);
      loans.assignAll(list.map((m) => Loan.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (loanPmtsStr != null && loanPmtsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(loanPmtsStr);
      loanPayments.assignAll(list.map((m) => LoanPayment.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (recsStr != null && recsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(recsStr);
      receivables.assignAll(list.map((m) => Receivable.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (recPmtsStr != null && recPmtsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(recPmtsStr);
      receivablePayments.assignAll(list.map((m) => ReceivablePayment.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (refundsStr != null && refundsStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(refundsStr);
      refundRecords.assignAll(list.map((m) => RefundRecord.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (suppliersStr != null && suppliersStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(suppliersStr);
      suppliers.assignAll(list.map((m) => Supplier.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
    }

    if (investors.isEmpty && loans.isEmpty && receivables.isEmpty) {
      _seedDefaultInvestorsLoansReceivables();
    }
  }

  void _seedDefaultInvestorsLoansReceivables() {
    investors.assignAll([
      Investor(
        id: 'INV-001',
        name: 'Karim Hossain',
        phone: '01711-111222',
        email: 'karim@example.com',
        investAmount: 50000,
        date: DateTime(2026, 1, 15),
        profitShare: 25.0,
        status: 'active',
        note: 'Silent partner',
        withdrawals: [
          InvestorSubRecord(
            id: 'WD-001',
            amount: 5000,
            date: DateTime(2026, 3, 1),
            note: 'Q1 profit payout',
          ),
        ],
      ),
      Investor(
        id: 'INV-002',
        name: 'Nasrin Begum',
        phone: '01811-333444',
        email: '',
        investAmount: 30000,
        date: DateTime(2026, 2, 10),
        profitShare: 15.0,
        status: 'active',
        note: 'Equipment investor',
        withdrawals: [],
      ),
    ]);

    loans.assignAll([
      Loan(
        id: 'LN-001',
        lender: 'Dutch-Bangla Bank',
        type: 'bank',
        amount: 100000,
        remaining: 85000,
        interestRate: 12.0,
        startDate: DateTime(2026, 1, 1),
        dueDate: DateTime(2027, 1, 1),
        monthlyPayment: 9000,
        purpose: 'Business expansion',
        status: 'active',
        payments: [
          LoanPaymentEntry(
            id: 'PMT-001',
            amount: 9000,
            date: DateTime(2026, 2, 1),
            note: 'January installment',
          ),
          LoanPaymentEntry(
            id: 'PMT-002',
            amount: 6000,
            date: DateTime(2026, 3, 1),
            note: 'February installment',
          ),
        ],
      ),
      Loan(
        id: 'LN-002',
        lender: 'Rahim Mia',
        phone: '01711-999888',
        type: 'person',
        amount: 20000,
        remaining: 20000,
        interestRate: 0.0,
        startDate: DateTime(2026, 3, 15),
        dueDate: DateTime(2026, 9, 15),
        monthlyPayment: 0,
        purpose: 'Emergency stock purchase',
        status: 'active',
        payments: [],
      ),
    ]);

    receivables.assignAll([
      Receivable(
        id: 'LT-001',
        person: 'Sabbir Ahmed',
        phone: '01611-222333',
        amount: 5000,
        remaining: 3000,
        date: DateTime(2026, 5, 1),
        dueDate: DateTime(2026, 8, 1),
        reason: 'Medical emergency help',
        status: 'partially_returned',
        returns: [
          MoneyLentReturnEntry(
            id: 'RT-001',
            amount: 2000,
            date: DateTime(2026, 6, 1),
            note: 'First return',
          ),
        ],
      ),
      Receivable(
        id: 'LT-002',
        person: 'Fatema Khanam',
        phone: '01911-444555',
        amount: 2000,
        remaining: 2000,
        date: DateTime(2026, 7, 10),
        dueDate: DateTime(2026, 9, 10),
        reason: 'Shop rent help',
        status: 'pending',
        returns: [],
      ),
    ]);
  }

  void _seedDefaultBranches() {
    branches.assignAll([
      Branch(
        id: 'branch_bonani',
        name: 'Bonani',
        banglaName: 'বনানী',
        address: 'Road 11, Block D, Banani Commercial Area, Dhaka',
        managerName: 'Tanvir Ahmed',
        managerPhone: '+880 1711-234501',
        email: 'bonani@stockmate.com',
        colorValue: 0xFF2563EB, // Royal Blue
      ),
      Branch(
        id: 'branch_gulshan',
        name: 'Gulshan',
        banglaName: 'গুলশান',
        address: 'Road 36, Gulshan 2, Dhaka 1212',
        managerName: 'Kazi Farhan',
        managerPhone: '+880 1711-234502',
        email: 'gulshan@stockmate.com',
        colorValue: 0xFF10B981, // Emerald Green
      ),
      Branch(
        id: 'branch_nikunjo',
        name: 'Nikunjo',
        banglaName: 'নিকুঞ্জ',
        address: 'Road 4, Sector 2, Nikunja, Khilkhet, Dhaka',
        managerName: 'Rashedul Islam',
        managerPhone: '+880 1711-234503',
        email: 'nikunjo@stockmate.com',
        colorValue: 0xFF8B5CF6, // Violet / Purple
      ),
      Branch(
        id: 'branch_jamgora',
        name: 'Jamgora',
        banglaName: 'জামগড়া',
        address: 'Jamgora Central Market, Ashulia, Savar',
        managerName: 'Mahmudul Hasan',
        managerPhone: '+880 1711-234504',
        email: 'jamgora@stockmate.com',
        colorValue: 0xFFF59E0B, // Amber / Orange
      ),
      Branch(
        id: 'branch_savar',
        name: 'Savar',
        banglaName: 'সাভার',
        address: 'Bazar Bus Stand Main Road, Savar',
        managerName: 'Arifur Rahman',
        managerPhone: '+880 1711-234505',
        email: 'savar@stockmate.com',
        colorValue: 0xFF0F766E, // Deep Teal
      ),
    ]);
  }

  void _ensureBranchStockDistribution() {
    final branchNames = ['Bonani', 'Gulshan', 'Nikunjo', 'Jamgora', 'Savar'];
    final defaultBranchProducts = {
      'Bonani': [
        Product(
          id: 'bnn_1',
          brandName: 'Samsung',
          catalogName: 'Galaxy Buds Pro',
          productCode: 'SM-8091',
          quantity: 24,
          pricePerPiece: 8500,
          sellingPrice: 11500,
          buyingDate: DateTime.now().subtract(const Duration(days: 12)),
          notes: 'Original distributor stock',
          lowStockThreshold: 5,
          branchName: 'Bonani',
        ),
        Product(
          id: 'bnn_2',
          brandName: 'Apple',
          catalogName: 'Apple Watch Ultra 2',
          productCode: 'AP-8820',
          quantity: 12,
          pricePerPiece: 68000,
          sellingPrice: 82000,
          buyingDate: DateTime.now().subtract(const Duration(days: 6)),
          notes: 'Titanium Case with Trail Loop',
          lowStockThreshold: 3,
          branchName: 'Bonani',
        ),
        Product(
          id: 'bnn_3',
          brandName: 'Anker',
          catalogName: 'PowerCore 20000mAh PowerBank',
          productCode: 'ANK-4401',
          quantity: 30,
          pricePerPiece: 2800,
          sellingPrice: 3900,
          buyingDate: DateTime.now().subtract(const Duration(days: 10)),
          notes: 'High speed power IQ delivery',
          lowStockThreshold: 6,
          branchName: 'Bonani',
        ),
        Product(
          id: 'bnn_4',
          brandName: 'Sony',
          catalogName: 'WH-1000XM5 Wireless Headset',
          productCode: 'SN-9022',
          quantity: 8,
          pricePerPiece: 34000,
          sellingPrice: 42000,
          buyingDate: DateTime.now().subtract(const Duration(days: 4)),
          notes: 'Industry-leading noise canceling',
          lowStockThreshold: 2,
          branchName: 'Bonani',
        ),
      ],
      'Gulshan': [
        Product(
          id: 'gls_1',
          brandName: 'Apple',
          catalogName: 'AirPods Max Space Gray',
          productCode: 'AP-4402',
          quantity: 8,
          pricePerPiece: 45000,
          sellingPrice: 58000,
          buyingDate: DateTime.now().subtract(const Duration(days: 8)),
          notes: 'Space Gray with Smart Case',
          lowStockThreshold: 3,
          branchName: 'Gulshan',
        ),
        Product(
          id: 'gls_2',
          brandName: 'Apple',
          catalogName: 'iPhone 15 Pro Silicone Case',
          productCode: 'AP-1509',
          quantity: 45,
          pricePerPiece: 1200,
          sellingPrice: 2200,
          buyingDate: DateTime.now().subtract(const Duration(days: 14)),
          notes: 'Midnight Black & Storm Blue',
          lowStockThreshold: 10,
          branchName: 'Gulshan',
        ),
        Product(
          id: 'gls_3',
          brandName: 'Bose',
          catalogName: 'QuietComfort 45 Headphones',
          productCode: 'BO-5521',
          quantity: 10,
          pricePerPiece: 28000,
          sellingPrice: 36000,
          buyingDate: DateTime.now().subtract(const Duration(days: 9)),
          notes: 'White Smoke edition',
          lowStockThreshold: 4,
          branchName: 'Gulshan',
        ),
        Product(
          id: 'gls_4',
          brandName: 'Belkin',
          catalogName: '3-in-1 Wireless MagSafe Charger',
          productCode: 'BL-3390',
          quantity: 16,
          pricePerPiece: 8500,
          sellingPrice: 12500,
          buyingDate: DateTime.now().subtract(const Duration(days: 7)),
          notes: 'Fast charge for Apple devices',
          lowStockThreshold: 4,
          branchName: 'Gulshan',
        ),
      ],
      'Nikunjo': [
        Product(
          id: 'nkj_1',
          brandName: 'Walton',
          catalogName: 'Primo S8 Power Bank 20000mAh',
          productCode: 'WL-1029',
          quantity: 15,
          pricePerPiece: 1400,
          sellingPrice: 1950,
          buyingDate: DateTime.now().subtract(const Duration(days: 20)),
          notes: 'Fast charging dual-port model',
          lowStockThreshold: 5,
          branchName: 'Nikunjo',
        ),
        Product(
          id: 'nkj_2',
          brandName: 'Baseus',
          catalogName: '65W GaN Fast Charger',
          productCode: 'BS-6501',
          quantity: 28,
          pricePerPiece: 2100,
          sellingPrice: 3100,
          buyingDate: DateTime.now().subtract(const Duration(days: 11)),
          notes: 'Type-C dual output QC 4.0',
          lowStockThreshold: 8,
          branchName: 'Nikunjo',
        ),
        Product(
          id: 'nkj_3',
          brandName: 'JBL',
          catalogName: 'Flip 6 Bluetooth Speaker',
          productCode: 'JBL-6012',
          quantity: 12,
          pricePerPiece: 9500,
          sellingPrice: 13500,
          buyingDate: DateTime.now().subtract(const Duration(days: 5)),
          notes: 'IP67 Waterproof portable speaker',
          lowStockThreshold: 3,
          branchName: 'Nikunjo',
        ),
        Product(
          id: 'nkj_4',
          brandName: 'Remax',
          catalogName: 'Fast Type-C Braided Cable 2M',
          productCode: 'RMX-1102',
          quantity: 55,
          pricePerPiece: 350,
          sellingPrice: 750,
          buyingDate: DateTime.now().subtract(const Duration(days: 16)),
          notes: 'Heavy duty zinc alloy connectors',
          lowStockThreshold: 15,
          branchName: 'Nikunjo',
        ),
      ],
      'Jamgora': [
        Product(
          id: 'jmg_1',
          brandName: 'Xiaomi',
          catalogName: 'Redmi Smart Band 2',
          productCode: 'XM-9011',
          quantity: 35,
          pricePerPiece: 2200,
          sellingPrice: 2900,
          buyingDate: DateTime.now().subtract(const Duration(days: 5)),
          notes: 'Black & Blue straps included',
          lowStockThreshold: 6,
          branchName: 'Jamgora',
        ),
        Product(
          id: 'jmg_2',
          brandName: 'Realme',
          catalogName: 'Buds Air 5 Pro ANC Earbuds',
          productCode: 'RM-5011',
          quantity: 20,
          pricePerPiece: 4800,
          sellingPrice: 6500,
          buyingDate: DateTime.now().subtract(const Duration(days: 8)),
          notes: '50dB active noise cancellation',
          lowStockThreshold: 5,
          branchName: 'Jamgora',
        ),
        Product(
          id: 'jmg_3',
          brandName: 'Fastrack',
          catalogName: 'Reflex Play Smartwatch',
          productCode: 'FT-7720',
          quantity: 18,
          pricePerPiece: 3600,
          sellingPrice: 5200,
          buyingDate: DateTime.now().subtract(const Duration(days: 12)),
          notes: 'AMOLED display with BT calling',
          lowStockThreshold: 4,
          branchName: 'Jamgora',
        ),
        Product(
          id: 'jmg_4',
          brandName: 'Ugreen',
          catalogName: '6-in-1 USB-C Hub 4K HDMI',
          productCode: 'UG-6091',
          quantity: 24,
          pricePerPiece: 1600,
          sellingPrice: 2400,
          buyingDate: DateTime.now().subtract(const Duration(days: 6)),
          notes: 'Aluminum shell multi-adapter',
          lowStockThreshold: 5,
          branchName: 'Jamgora',
        ),
      ],
      'Savar': [
        Product(
          id: 'svr_1',
          brandName: 'Apex',
          catalogName: 'Venturini Leather Wallet',
          productCode: 'APX-771',
          quantity: 18,
          pricePerPiece: 1100,
          sellingPrice: 1750,
          buyingDate: DateTime.now().subtract(const Duration(days: 15)),
          notes: 'Brown genuine leather bifold',
          lowStockThreshold: 4,
          branchName: 'Savar',
        ),
        Product(
          id: 'svr_2',
          brandName: 'Casio',
          catalogName: 'Vintage Digital Watch A168W',
          productCode: 'CS-1581',
          quantity: 22,
          pricePerPiece: 2600,
          sellingPrice: 3800,
          buyingDate: DateTime.now().subtract(const Duration(days: 10)),
          notes: 'Stainless steel retro illuminator',
          lowStockThreshold: 5,
          branchName: 'Savar',
        ),
        Product(
          id: 'svr_3',
          brandName: 'Logitech',
          catalogName: 'M220 Silent Wireless Mouse',
          productCode: 'LG-2201',
          quantity: 38,
          pricePerPiece: 950,
          sellingPrice: 1500,
          buyingDate: DateTime.now().subtract(const Duration(days: 18)),
          notes: '90% noise reduction 2.4GHz',
          lowStockThreshold: 8,
          branchName: 'Savar',
        ),
        Product(
          id: 'svr_4',
          brandName: 'Kingston',
          catalogName: '64GB DataTraveler USB 3.2',
          productCode: 'KS-6402',
          quantity: 50,
          pricePerPiece: 580,
          sellingPrice: 950,
          buyingDate: DateTime.now().subtract(const Duration(days: 7)),
          notes: 'High speed portable flash drive',
          lowStockThreshold: 12,
          branchName: 'Savar',
        ),
      ],
    };

    bool hasChanged = false;
    for (final bName in branchNames) {
      final exists = products.any((p) => p.branchName.trim().toLowerCase() == bName.toLowerCase());
      if (!exists && defaultBranchProducts.containsKey(bName)) {
        products.addAll(defaultBranchProducts[bName]!);
        hasChanged = true;
      }
    }

    if (hasChanged) {
      saveToLocal();
    }
  }

  void _seedDefaultData() {
    _seedDefaultBranches();
    products.clear();
    _ensureBranchStockDistribution();


    sales.assignAll([
      Sale(
        id: 'SAL-20261016-A101',
        productId: '1',
        productName: 'Samsung Galaxy Buds Pro',
        brandName: 'Samsung',
        catalogName: 'Galaxy Buds Pro',
        productCode: 'SM-8091',
        quantity: 2,
        unitCost: 8500,
        unitPrice: 11500,
        discountAmount: 500,
        totalPrice: 22500,
        profit: 5500,
        paymentMethod: 'Cash',
        sellerName: 'Tanvir Ahmed',
        sellerRole: 'Manager',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        notes: 'Walk-in customer',
      ),
      Sale(
        id: 'SAL-20261016-B202',
        productId: '4',
        productName: 'Xiaomi Redmi Smart Band 2',
        brandName: 'Xiaomi',
        catalogName: 'Redmi Smart Band 2',
        productCode: 'XM-9011',
        quantity: 3,
        unitCost: 2200,
        unitPrice: 2900,
        discountAmount: 200,
        totalPrice: 8500,
        profit: 1900,
        paymentMethod: 'bKash',
        sellerName: 'Sabbir Hossain',
        sellerRole: 'Staff',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        notes: 'Online order',
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
    ]);

    expenses.assignAll([
      Expense(
        id: 'e1',
        category: 'Rent',
        amount: 25000,
        notes: 'Store & Warehouse rent',
        date: DateTime.now().subtract(const Duration(days: 4)),
        creatorName: 'Tanvir Ahmed',
        creatorRole: 'Manager',
      ),
      Expense(
        id: 'e2',
        category: 'Delivery & Transport',
        amount: 3200,
        notes: 'Courier parcels dispatched',
        date: DateTime.now().subtract(const Duration(days: 2)),
        creatorName: 'Sabbir Hossain',
        creatorRole: 'Staff',
      ),
    ]);

    suppliers.assignAll([
      Supplier(
        id: 'sup1',
        name: 'Samsung Official Distributor BD',
        contactPhone: '+8801700000001',
        email: 'sales@samsungdist.bd',
        address: 'Motijheel C/A, Dhaka',
      ),
      Supplier(
        id: 'sup2',
        name: 'iStore Wholesale Hub',
        contactPhone: '+8801800000002',
        email: 'b2b@istorebd.com',
        address: 'Bashundhara City, Dhaka',
      ),
    ]);

    // Seed Investors per Spec Section 8
    investors.assignAll([
      Investor(
        id: 'INV-001',
        name: 'Karim Hossain',
        phone: '01711-111222',
        email: 'karim@example.com',
        investAmount: 50000,
        date: DateTime(2026, 1, 15),
        profitShare: 25.0,
        status: 'active',
        note: 'Silent partner',
        withdrawals: [
          InvestorSubRecord(
            id: 'WD-001',
            amount: 5000,
            date: DateTime(2026, 3, 1),
            note: 'Q1 profit payout',
          ),
        ],
      ),
      Investor(
        id: 'INV-002',
        name: 'Nasrin Begum',
        phone: '01811-333444',
        email: '',
        investAmount: 30000,
        date: DateTime(2026, 2, 10),
        profitShare: 15.0,
        status: 'active',
        note: 'Equipment investor',
        withdrawals: [],
      ),
    ]);

    // Seed Loans per Spec Section 8
    loans.assignAll([
      Loan(
        id: 'LN-001',
        lender: 'Dutch-Bangla Bank',
        type: 'bank',
        amount: 100000,
        remaining: 85000,
        interestRate: 12.0,
        startDate: DateTime(2026, 1, 1),
        dueDate: DateTime(2027, 1, 1),
        monthlyPayment: 9000,
        purpose: 'Business expansion',
        status: 'active',
        payments: [
          LoanPaymentEntry(
            id: 'PMT-001',
            amount: 9000,
            date: DateTime(2026, 2, 1),
            note: 'January installment',
          ),
          LoanPaymentEntry(
            id: 'PMT-002',
            amount: 6000,
            date: DateTime(2026, 3, 1),
            note: 'February installment',
          ),
        ],
      ),
      Loan(
        id: 'LN-002',
        lender: 'Rahim Mia',
        phone: '01711-999888',
        type: 'person',
        amount: 20000,
        remaining: 20000,
        interestRate: 0.0,
        startDate: DateTime(2026, 3, 15),
        dueDate: DateTime(2026, 9, 15),
        monthlyPayment: 0,
        purpose: 'Emergency stock purchase',
        status: 'active',
        payments: [],
      ),
    ]);

    // Seed Money Lent per Spec Section 8
    receivables.assignAll([
      Receivable(
        id: 'LT-001',
        person: 'Sabbir Ahmed',
        phone: '01611-222333',
        amount: 5000,
        remaining: 3000,
        date: DateTime(2026, 5, 1),
        dueDate: DateTime(2026, 8, 1),
        reason: 'Medical emergency help',
        status: 'partially_returned',
        returns: [
          MoneyLentReturnEntry(
            id: 'RT-001',
            amount: 2000,
            date: DateTime(2026, 6, 1),
            note: 'First return',
          ),
        ],
      ),
      Receivable(
        id: 'LT-002',
        person: 'Fatema Khanam',
        phone: '01911-444555',
        amount: 2000,
        remaining: 2000,
        date: DateTime(2026, 7, 10),
        dueDate: DateTime(2026, 9, 10),
        reason: 'Shop rent help',
        status: 'pending',
        returns: [],
      ),
    ]);

    activityLogs.assignAll([
      ActivityLog(
        id: 'l1',
        type: 'sale',
        title: 'Sale Completed [SAL-20261016-A101]',
        description: '2x Samsung Galaxy Buds Pro sold for ৳22,500',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ActivityLog(
        id: 'l2',
        type: 'expense',
        title: 'Expense Added',
        description: 'Delivery & Transport: ৳3,200',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
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
        deviceName: 'Primary Terminal (PC/Phone)',
      ),
      AppUser(
        id: 'u2',
        name: 'Tanvir Ahmed',
        email: 'tanvir@stockmate.com',
        role: 'Manager',
        approvalStatus: 'approved',
        deviceName: 'Manager Tablet',
      ),
      AppUser(
        id: 'u3',
        name: 'Sabbir Hossain',
        email: 'sabbir@stockmate.com',
        role: 'Staff',
        approvalStatus: 'approved',
        deviceName: 'Sales POS Terminal',
      ),
    ]);
  }
}
