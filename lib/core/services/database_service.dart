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
import 'notification_service.dart';

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

        // Low stock notification
        if (updatedP.quantity <= updatedP.lowStockThreshold) {
          try {
            if (Get.isRegistered<NotificationService>()) {
              Get.find<NotificationService>().showLowStockNotification(
                updatedP.displayName,
                updatedP.quantity,
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
    logActivity(
      'sale',
      'Sale Completed [$salesId]',
      '${items.length} items sold by $sellerName ($sellerRole) for ৳${totalAmount.toStringAsFixed(0)} via $paymentMethod',
    );
    saveToLocal();
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
    return true;
  }

  // ---------------------------------------------------------------------------
  // Product Operations
  // ---------------------------------------------------------------------------
  void addProduct(Product product) {
    products.add(product);
    logActivity('product_add', 'Product Added', '${product.displayName} (Code: ${product.productCode}) added. Cost: ৳${product.pricePerPiece.toStringAsFixed(0)}, Sell: ৳${product.sellingPrice.toStringAsFixed(0)}');
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
  }

  // ---------------------------------------------------------------------------
  // Expense Operations
  // ---------------------------------------------------------------------------
  void addExpense(Expense expense) {
    expenses.insert(0, expense);
    logActivity('expense', 'Expense Recorded', '${expense.category}: ৳${expense.amount.toStringAsFixed(0)} by ${expense.creatorName} (${expense.notes})');
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
  }

  void approveDiscount(String ruleId, String approverId, String approverName) {
    final index = discountRules.indexWhere((r) => r.id == ruleId);
    if (index != -1) {
      discountRules[index] = discountRules[index].copyWith(
        status: 'approved',
        approverId: approverId,
        approverName: approverName,
      );
      logActivity('discount', 'Discount Approved', '${discountRules[index].name} approved by $approverName');
      saveToLocal();
    }
  }

  void rejectDiscount(String ruleId) {
    final index = discountRules.indexWhere((r) => r.id == ruleId);
    if (index != -1) {
      discountRules[index] = discountRules[index].copyWith(status: 'rejected');
      logActivity('discount', 'Discount Rejected', '${discountRules[index].name} rejected.');
      saveToLocal();
    }
  }

  // ---------------------------------------------------------------------------
  // Investor Management (Spec Section 11)
  // ---------------------------------------------------------------------------
  void addInvestor(Investor investor) {
    investors.add(investor);
    // Initial contribution transaction
    addInvestorTransaction(InvestorTransaction(
      id: const Uuid().v4(),
      investorId: investor.id,
      type: 'contribution',
      amount: investor.initialInvestedAmount,
      notes: 'Initial Capital Contribution',
    ));
    logActivity('investor', 'New Investor Added', '${investor.name} added with capital ৳${investor.initialInvestedAmount.toStringAsFixed(0)} (${investor.ownershipPercentage}% equity)');
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
  }

  double getNetActiveCapitalForInvestor(String investorId) {
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
  // Borrowed Loans (Spec Section 12)
  // ---------------------------------------------------------------------------
  void addLoan(Loan loan) {
    loans.add(loan);
    logActivity('loan', 'Loan Recorded', 'Borrowed ৳${loan.principalBorrowed.toStringAsFixed(0)} from ${loan.lenderName} (${loan.interestRate}% ${loan.interestRateUnit})');
    saveToLocal();
  }

  void updateLoan(Loan loan) {
    final index = loans.indexWhere((l) => l.id == loan.id);
    if (index != -1) {
      loans[index] = loan;
      saveToLocal();
    }
  }

  void recordLoanPayment(LoanPayment payment) {
    loanPayments.insert(0, payment);
    final loanIndex = loans.indexWhere((l) => l.id == payment.loanId);
    if (loanIndex != -1) {
      final rem = getOutstandingLoanPrincipal(payment.loanId);
      if (rem <= 0) {
        loans[loanIndex] = loans[loanIndex].copyWith(status: 'paid');
      }
    }
    logActivity('loan', 'Loan Repayment', 'Paid ৳${payment.totalAmount.toStringAsFixed(0)} (Principal: ৳${payment.principalPaid.toStringAsFixed(0)}, Interest: ৳${payment.interestPaid.toStringAsFixed(0)})');
    saveToLocal();
  }

  double getOutstandingLoanPrincipal(String loanId) {
    final loan = loans.firstWhereOrNull((l) => l.id == loanId);
    if (loan == null) return 0.0;
    final totalPrincipalPaid = loanPayments
        .where((p) => p.loanId == loanId)
        .fold(0.0, (sum, p) => sum + p.principalPaid);
    final rem = loan.principalBorrowed - totalPrincipalPaid;
    return rem < 0 ? 0.0 : rem;
  }

  // ---------------------------------------------------------------------------
  // Money Lent / Receivables (Spec Section 13)
  // ---------------------------------------------------------------------------
  void addReceivable(Receivable receivable) {
    receivables.add(receivable);
    logActivity('money_lent', 'Money Lent', 'Lent ৳${receivable.amountLent.toStringAsFixed(0)} to ${receivable.borrower}');
    saveToLocal();
  }

  void updateReceivable(Receivable receivable) {
    final index = receivables.indexWhere((r) => r.id == receivable.id);
    if (index != -1) {
      receivables[index] = receivable;
      saveToLocal();
    }
  }

  void recordReceivablePayment(ReceivablePayment payment) {
    receivablePayments.insert(0, payment);
    final recIndex = receivables.indexWhere((r) => r.id == payment.receivableId);
    if (recIndex != -1) {
      final rem = getOutstandingReceivablePrincipal(payment.receivableId);
      if (rem <= 0) {
        receivables[recIndex] = receivables[recIndex].copyWith(status: 'returned');
      } else {
        receivables[recIndex] = receivables[recIndex].copyWith(status: 'partial');
      }
    }
    logActivity('money_lent', 'Receivable Repayment', 'Received ৳${payment.totalReceived.toStringAsFixed(0)} from borrower (Principal: ৳${payment.principalReturned.toStringAsFixed(0)}, Interest Income: ৳${payment.interestReceived.toStringAsFixed(0)})');
    saveToLocal();
  }

  double getOutstandingReceivablePrincipal(String receivableId) {
    final rec = receivables.firstWhereOrNull((r) => r.id == receivableId);
    if (rec == null) return 0.0;
    final principalReturned = receivablePayments
        .where((p) => p.receivableId == receivableId)
        .fold(0.0, (sum, p) => sum + p.principalReturned);
    final rem = rec.amountLent - principalReturned;
    return rem < 0 ? 0.0 : rem;
  }

  double getPrincipalReturnPercentage(String receivableId) {
    final rec = receivables.firstWhereOrNull((r) => r.id == receivableId);
    if (rec == null || rec.amountLent <= 0) return 0.0;
    final principalReturned = receivablePayments
        .where((p) => p.receivableId == receivableId)
        .fold(0.0, (sum, p) => sum + p.principalReturned);
    return (principalReturned / rec.amountLent) * 100.0;
  }

  // ---------------------------------------------------------------------------
  // Suppliers
  // ---------------------------------------------------------------------------
  void addSupplier(Supplier supplier) {
    suppliers.add(supplier);
    logActivity('supplier', 'Supplier Added', '${supplier.name} added.');
    saveToLocal();
  }

  void updateSupplier(Supplier supplier) {
    final index = suppliers.indexWhere((s) => s.id == supplier.id);
    if (index != -1) {
      suppliers[index] = supplier;
      saveToLocal();
    }
  }

  void deleteSupplier(String id) {
    suppliers.removeWhere((s) => s.id == id);
    saveToLocal();
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
  // Persistence (SharedPreferences JSON Storage)
  // ---------------------------------------------------------------------------
  Future<void> saveToLocal() async {
    try {
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
        sellingPrice: 11500,
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
        sellingPrice: 58000,
        buyingDate: DateTime.now().subtract(const Duration(days: 8)),
        notes: 'Space Gray and Silver',
        lowStockThreshold: 3,
      ),
      Product(
        id: '3',
        brandName: 'Walton',
        catalogName: 'Primo S8 Power Bank 20000mAh',
        productCode: 'WL-1029',
        quantity: 3,
        pricePerPiece: 1400,
        sellingPrice: 1950,
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
        sellingPrice: 2900,
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
        sellingPrice: 1750,
        buyingDate: DateTime.now().subtract(const Duration(days: 15)),
        notes: 'Brown genuine leather',
        lowStockThreshold: 4,
      ),
    ]);

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

    // Seed Investors per Spec Section 11 & 22.3
    final defaultInvestor = Investor(
      id: 'inv1',
      name: 'Rahim Chowdhury (Equity Partner)',
      investmentDate: DateTime.now().subtract(const Duration(days: 60)),
      investmentType: 'Equity Partner',
      initialInvestedAmount: 50000,
      ownershipPercentage: 45.0,
      profitSharePercentage: 45.0,
      notes: 'Strategic business angel investor',
    );
    investors.assignAll([defaultInvestor]);
    investorTransactions.assignAll([
      InvestorTransaction(
        id: 'itx1',
        investorId: 'inv1',
        type: 'contribution',
        amount: 50000,
        date: DateTime.now().subtract(const Duration(days: 60)),
        notes: 'Capital contribution for expansion',
      ),
    ]);

    // Seed Loans per Spec Section 12 & 22.4
    final defaultLoan = Loan(
      id: 'loan1',
      lenderType: 'Bank',
      lenderName: 'City Bank SME Loan',
      purpose: 'Emergency stock procurement',
      principalBorrowed: 10000,
      interestRate: 12.0,
      interestRateUnit: 'Annual',
      interestMethod: 'Simple',
      startDate: DateTime.now().subtract(const Duration(days: 45)),
      dueDate: DateTime.now().add(const Duration(days: 320)),
      installmentAmount: 933,
    );
    loans.assignAll([defaultLoan]);
    loanPayments.assignAll([
      LoanPayment(
        id: 'lp1',
        loanId: 'loan1',
        paymentDate: DateTime.now().subtract(const Duration(days: 15)),
        totalAmount: 933,
        principalPaid: 833, // Liability reduction
        interestPaid: 100, // Operating interest expense
        paymentMethod: 'Bank Transfer',
        notes: 'Month 1 installment',
      ),
    ]);

    // Seed Money Lent per Spec Section 13 & 22.5
    final defaultReceivable = Receivable(
      id: 'rec1',
      borrower: 'Kamal Trading Corp',
      amountLent: 5000,
      interestAgreement: 'Percentage',
      interestRate: 5.0,
      interestRateUnit: 'Yearly',
      purpose: 'Short-term bridge finance',
      dateLent: DateTime.now().subtract(const Duration(days: 30)),
      dueDate: DateTime.now().add(const Duration(days: 60)),
    );
    receivables.assignAll([defaultReceivable]);
    receivablePayments.assignAll([
      ReceivablePayment(
        id: 'rp1',
        receivableId: 'rec1',
        paymentDate: DateTime.now().subtract(const Duration(days: 5)),
        principalReturned: 2000, // Receivable reduction
        interestReceived: 125, // Interest income
        paymentMethod: 'Cash',
        notes: 'Partial principal and interest return',
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
