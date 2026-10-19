import 'package:get/get.dart';
import '../../../core/models/branch_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/database_service.dart';

class BranchesController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();

  final RxString searchQuery = ''.obs;
  final RxString selectedSort = 'Valuation'.obs; // 'Valuation', 'Stock Units', 'SKUs', 'Name'
  final RxString selectedStatusFilter = 'All'.obs; // 'All', 'Active'

  // Network Totals
  int get totalNetworkStockUnits => db.totalStockPieces;
  double get totalNetworkValuation => db.totalStockValuation;
  int get totalNetworkSkus => db.products.length;
  int get totalBranchesCount => db.branches.length;

  // Filtered and Sorted Branches
  List<Branch> get filteredBranches {
    final query = searchQuery.value.trim().toLowerCase();

    final list = db.branches.where((branch) {
      final matchesSearch = query.isEmpty ||
          branch.name.toLowerCase().contains(query) ||
          branch.banglaName.toLowerCase().contains(query) ||
          branch.address.toLowerCase().contains(query) ||
          branch.managerName.toLowerCase().contains(query);

      final matchesStatus = selectedStatusFilter.value == 'All' ||
          (selectedStatusFilter.value == 'Active' && branch.isActive);

      return matchesSearch && matchesStatus;
    }).toList();

    // Sorting
    list.sort((a, b) {
      if (selectedSort.value == 'Valuation') {
        final valA = db.getBranchValuation(a.name);
        final valB = db.getBranchValuation(b.name);
        return valB.compareTo(valA);
      } else if (selectedSort.value == 'Stock Units') {
        final unitsA = db.getBranchUnitStocks(a.name);
        final unitsB = db.getBranchUnitStocks(b.name);
        return unitsB.compareTo(unitsA);
      } else if (selectedSort.value == 'SKUs') {
        final skusA = db.getBranchSkus(a.name);
        final skusB = db.getBranchSkus(b.name);
        return skusB.compareTo(skusA);
      } else {
        return a.name.compareTo(b.name);
      }
    });

    return list;
  }

  // Branch Specific Product List
  List<Product> getProductsForBranch(
    String branchName, {
    String query = '',
    String selectedBrand = 'All',
  }) {
    final branchProducts = db.getBranchProducts(branchName);
    return branchProducts.where((p) {
      final matchesQuery = query.isEmpty ||
          p.displayName.toLowerCase().contains(query.toLowerCase()) ||
          p.productCode.toLowerCase().contains(query.toLowerCase()) ||
          p.brandName.toLowerCase().contains(query.toLowerCase());

      final matchesBrand = selectedBrand == 'All' ||
          p.brandName.toLowerCase() == selectedBrand.toLowerCase();

      return matchesQuery && matchesBrand;
    }).toList();
  }

  // Stock Transfer
  bool transferBranchStock({
    required String productId,
    required String targetBranch,
    required int transferQty,
  }) {
    return db.transferStock(
      productId: productId,
      targetBranch: targetBranch,
      transferQty: transferQty,
    );
  }

  void adjustProductQuantity(String id, int delta) {
    db.adjustProductQuantity(id, delta);
  }
}
