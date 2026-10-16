import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/purchase_model.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/services/database_service.dart';

class PurchasesExpensesController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();

  // Expense Filter
  final RxString selectedExpenseCategory = 'All'.obs;

  // Purchases list
  RxList<Purchase> get purchases => db.purchases;
  RxList<Expense> get expenses => db.expenses;

  // Filtered expenses
  List<Expense> get filteredExpenses {
    if (selectedExpenseCategory.value == 'All') {
      return expenses;
    }
    return expenses.where((e) => e.category == selectedExpenseCategory.value).toList();
  }

  double get totalExpenseSum => filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
  double get totalPurchaseSum => purchases.fold(0.0, (sum, p) => sum + p.totalAmount);

  // Record a stock purchase / restock
  void addPurchase({
    required Product product,
    required int quantity,
    required double pricePerPiece,
    String supplier = '',
    String notes = '',
  }) {
    db.recordPurchase(
      product: product,
      quantity: quantity,
      pricePerPiece: pricePerPiece,
      supplier: supplier,
      notes: notes,
    );
    Get.snackbar('Success', 'purchase_success'.tr, snackPosition: SnackPosition.BOTTOM);
  }

  // Add / Edit / Delete Expense
  void addExpense({
    required String category,
    required double amount,
    required DateTime date,
    String notes = '',
  }) {
    final expense = Expense(
      id: const Uuid().v4(),
      category: category,
      amount: amount,
      notes: notes,
      date: date,
    );
    db.addExpense(expense);
    Get.snackbar('Success', 'expense_success'.tr, snackPosition: SnackPosition.BOTTOM);
  }

  void updateExpense(Expense expense) {
    db.updateExpense(expense);
    Get.snackbar('Success', 'Expense updated', snackPosition: SnackPosition.BOTTOM);
  }

  void deleteExpense(String id) {
    db.deleteExpense(id);
    Get.snackbar('Deleted', 'Expense record removed', snackPosition: SnackPosition.BOTTOM);
  }
}
