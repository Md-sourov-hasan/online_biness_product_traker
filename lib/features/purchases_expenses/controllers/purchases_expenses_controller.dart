import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/purchase_model.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/permission_service.dart';

class PurchasesExpensesController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();
  final AuthService auth = Get.find<AuthService>();
  final PermissionService perm = Get.find<PermissionService>();

  // Expense Filter
  final RxString selectedExpenseCategory = 'All'.obs;

  // Purchases list
  RxList<Purchase> get purchases => db.purchases;
  RxList<Expense> get expenses => db.expenses;

  // Filtered expenses based on category and role
  List<Expense> get filteredExpenses {
    final all = perm.isStaff ? staffRecentExpenses : expenses;
    if (selectedExpenseCategory.value == 'All') {
      return all;
    }
    return all.where((e) => e.category == selectedExpenseCategory.value).toList();
  }

  // Spec Section 6: Staff can only view their own expense submissions in the last 30 days
  List<Expense> get staffRecentExpenses {
    final currentUserId = auth.currentUser.value?.id ?? '';
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return expenses.where((e) {
      final matchesUser = e.creatorId.isEmpty || e.creatorId == currentUserId;
      final isRecent = e.date.isAfter(thirtyDaysAgo);
      return matchesUser && isRecent;
    }).toList();
  }

  double get totalExpenseSum => filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
  double get totalPurchaseSum => purchases.fold(0.0, (sum, p) => sum + p.totalAmount);

  // Record a stock purchase / restock (Manager / Owner only)
  void addPurchase({
    required Product product,
    required int quantity,
    required double pricePerPiece,
    String supplier = '',
    String notes = '',
  }) {
    if (!perm.canManageInventory) {
      Get.snackbar('Access Denied', 'Staff members cannot record stock purchases.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    db.recordPurchase(
      product: product,
      quantity: quantity,
      pricePerPiece: pricePerPiece,
      supplier: supplier,
      notes: notes,
    );
    Get.snackbar('Success', 'purchase_success'.tr, snackPosition: SnackPosition.BOTTOM);
  }

  // Add Expense with creator metadata
  void addExpense({
    required String category,
    required double amount,
    required DateTime date,
    String notes = '',
  }) {
    final user = auth.currentUser.value;
    final expense = Expense(
      id: const Uuid().v4(),
      category: category,
      amount: amount,
      notes: notes,
      date: date,
      creatorId: user?.id ?? '',
      creatorName: user?.name ?? 'Store Staff',
      creatorRole: user?.role ?? 'Staff',
      createdAt: DateTime.now(),
    );
    db.addExpense(expense);
    Get.snackbar('Success', 'expense_success'.tr, snackPosition: SnackPosition.BOTTOM);
  }

  void updateExpense(Expense expense) {
    if (perm.isStaff && expense.creatorId != (auth.currentUser.value?.id ?? '')) {
      Get.snackbar('Access Denied', 'You can only edit your own submissions.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    db.updateExpense(expense);
    Get.snackbar('Success', 'Expense updated', snackPosition: SnackPosition.BOTTOM);
  }

  void deleteExpense(String id) {
    if (perm.isStaff) {
      Get.snackbar('Access Denied', 'Staff cannot delete submitted expense records.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    db.deleteExpense(id);
    Get.snackbar('Deleted', 'Expense record removed', snackPosition: SnackPosition.BOTTOM);
  }
}
