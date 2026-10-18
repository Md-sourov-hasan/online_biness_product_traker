import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/sale_model.dart';
import '../../../core/models/discount_rule_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/permission_service.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../notifications/models/notification_item.dart';

class SalesController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();
  final AuthService auth = Get.find<AuthService>();
  final PermissionService perm = Get.find<PermissionService>();

  // POS Multi-Item Cart
  final RxList<SaleCartItem> cart = <SaleCartItem>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxString selectedPaymentMethod = 'Cash'.obs;
  final RxString selectedPeriodFilter = 'all'.obs; // 'all', 'today', 'week', 'month'

  // Last Completed Sale for Printable Receipt
  final Rx<String?> lastCompletedSalesId = Rx<String?>(null);
  final RxList<Sale> lastCompletedSaleLines = <Sale>[].obs;

  // Single Item Direct Add / Selection State
  final Rx<Product?> selectedProduct = Rx<Product?>(null);
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController notesController = TextEditingController();

  final RxDouble estimatedProfit = 0.0.obs;
  final RxDouble estimatedTotalRevenue = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    salePriceController.addListener(_calculateEstimates);
    quantityController.addListener(_calculateEstimates);
  }

  // Cart Calculations
  int get distinctSkuCount => cart.map((i) => i.product.id).toSet().length;
  int get totalUnitCount => cart.fold(0, (sum, i) => sum + i.quantity);
  double get cartGrossTotal => cart.fold(0.0, (sum, i) => sum + i.grossLineTotal);
  double get cartDiscountTotal => cart.fold(0.0, (sum, i) => sum + i.discount);
  double get cartNetTotal => cart.fold(0.0, (sum, i) => sum + i.netLineTotal);

  void addToCart(Product product, {int qty = 1, double? unitPrice, double discount = 0.0}) {
    // Check distinct SKU limit (Spec Section 7.1: Max 10 SKUs)
    final existingIndex = cart.indexWhere((i) => i.product.id == product.id);
    if (existingIndex == -1) {
      if (distinctSkuCount >= db.policy.value.maxDistinctSkusPerSale) {
        Get.snackbar(
          'Limit Exceeded',
          'Maximum ${db.policy.value.maxDistinctSkusPerSale} distinct products allowed per sale. Create a second sale.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }
    }

    // Check Total Units Limit (Spec Section 7.1: Max 100 units)
    if (totalUnitCount + qty > db.policy.value.maxTotalUnitsPerSale) {
      Get.snackbar(
        'Limit Exceeded',
        'Maximum ${db.policy.value.maxTotalUnitsPerSale} total units allowed per transaction.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Check Active Discount Rule
    double applicableDiscount = discount;
    final activeRule = getActiveDiscountForProduct(product);
    if (activeRule != null && applicableDiscount == 0.0) {
      applicableDiscount = (product.sellingPrice * (activeRule.discountPercentage / 100.0)) * qty;
    }

    final price = unitPrice ?? product.sellingPrice;

    // Minimum Selling Price Floor Validation (Spec Section 4.2)
    final floor = product.sellingPrice * (db.policy.value.minimumPricePercentage / 100.0);
    if (price < floor - 0.01) {
      Get.snackbar(
        'Price Policy Rejected',
        'Price ৳${price.toStringAsFixed(0)} is below owner floor ৳${floor.toStringAsFixed(0)} (${db.policy.value.minimumPricePercentage}% of ৳${product.sellingPrice.toStringAsFixed(0)}).',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (existingIndex != -1) {
      cart[existingIndex].quantity += qty;
      cart.refresh();
    } else {
      cart.add(SaleCartItem(
        product: product,
        quantity: qty,
        unitPrice: price,
        discount: applicableDiscount,
      ));
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < cart.length) {
      cart.removeAt(index);
    }
  }

  void updateCartItemQuantity(int index, int newQty) {
    if (index >= 0 && index < cart.length) {
      if (newQty <= 0) {
        cart.removeAt(index);
      } else {
        // Check unit cap
        final otherUnits = totalUnitCount - cart[index].quantity;
        if (otherUnits + newQty > db.policy.value.maxTotalUnitsPerSale) {
          Get.snackbar('Unit Limit', 'Total units cannot exceed ${db.policy.value.maxTotalUnitsPerSale}', snackPosition: SnackPosition.BOTTOM);
          return;
        }
        cart[index].quantity = newQty;
        cart.refresh();
      }
    }
  }

  DiscountRule? getActiveDiscountForProduct(Product product) {
    return db.discountRules.firstWhereOrNull((r) {
      if (!r.isCurrentlyActive) return false;
      if (r.scope == 'all') return true;
      if (r.scope == 'brand' && r.targetValue.toLowerCase() == product.brandName.toLowerCase()) return true;
      if (r.scope == 'product' && (r.targetValue == product.id || r.targetValue.toLowerCase() == product.displayName.toLowerCase())) return true;
      return false;
    });
  }

  void selectProduct(Product product) {
    selectedProduct.value = product;
    salePriceController.text = product.sellingPrice.toStringAsFixed(0);
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

  // Complete checkout for Cart
  bool checkoutCart({BuildContext? context}) {
    if (cart.isEmpty) {
      Get.snackbar('Cart Empty', 'Please add products to cart before checkout', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    try {
      final user = auth.currentUser.value;
      final salesId = db.recordMultiItemSale(
        items: cart.toList(),
        paymentMethod: selectedPaymentMethod.value,
        sellerId: user?.id ?? '',
        sellerName: user?.name ?? 'Staff',
        sellerRole: user?.role ?? 'Staff',
      );

      // Save for receipt modal
      lastCompletedSalesId.value = salesId;
      lastCompletedSaleLines.assignAll(db.sales.where((s) => s.id == salesId).toList());

      cart.clear();
      Get.snackbar(
        'Sale Completed!',
        'Sales ID: $salesId recorded successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      final user = auth.currentUser.value;

      if (Get.isRegistered<NotificationsController>()) {
        final notifCtrl = Get.find<NotificationsController>();

        if (errorMsg.contains('Price Policy Violation')) {
          // SAL-04: Sale blocked by price floor (to Owner, and to Manager if Staff attempted)
          notifCtrl.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'SAL-04',
              title: 'Sale Blocked: Price Floor Policy 🚫',
              message: '${user?.name ?? "Staff"} attempted a sale below the minimum price floor: $errorMsg',
              timestamp: DateTime.now(),
              type: NotificationType.sale,
              priority: NotificationPriority.high,
              actorUserId: user?.id,
              actorRole: user?.role,
              actorName: user?.name,
              recipientRole: 'Owner',
            ),
          );

          if (user?.isStaff ?? false) {
            // STF-07: Sale blocked by Owner rule (to Staff)
            notifCtrl.dispatchNotification(
              AppNotificationItem(
                id: const Uuid().v4(),
                code: 'STF-07',
                title: 'Sale Blocked by Owner Rule ⚠️',
                message: 'This sale was not saved because the unit price is below the Owner’s configured minimum price floor.',
                timestamp: DateTime.now(),
                type: NotificationType.sale,
                priority: NotificationPriority.high,
                recipientRole: 'Staff',
                recipientUserId: user!.id,
                actorUserId: user.id,
                isSelfConfirmation: true,
              ),
            );
          }
        } else if (errorMsg.contains('Transaction Limit Exceeded')) {
          // SAL-05: Sale limit reached (to Owner, and to Manager if Staff attempted)
          notifCtrl.dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'SAL-05',
              title: 'Sale Limit Reached ⚠️',
              message: '${user?.name ?? "Staff"} sale exceeded limit: $errorMsg',
              timestamp: DateTime.now(),
              type: NotificationType.sale,
              priority: NotificationPriority.high,
              actorUserId: user?.id,
              actorRole: user?.role,
              actorName: user?.name,
              recipientRole: 'Owner',
            ),
          );

          if (user?.isStaff ?? false) {
            // STF-07: Sale blocked by Owner rule (to Staff)
            notifCtrl.dispatchNotification(
              AppNotificationItem(
                id: const Uuid().v4(),
                code: 'STF-07',
                title: 'Sale Blocked: Limit Reached ⚠️',
                message: 'This sale exceeds the allowed units or distinct products limit configured by the Owner.',
                timestamp: DateTime.now(),
                type: NotificationType.sale,
                priority: NotificationPriority.high,
                recipientRole: 'Staff',
                recipientUserId: user!.id,
                actorUserId: user.id,
                isSelfConfirmation: true,
              ),
            );
          }
        }
      }

      Get.snackbar('Checkout Error', errorMsg, snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // Direct Single Sale Complete
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

    addToCart(selectedProduct.value!, qty: qty, unitPrice: price);
    final success = checkoutCart();

    if (success) {
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
