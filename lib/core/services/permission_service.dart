import 'package:get/get.dart';
import 'auth_service.dart';

class PermissionService extends GetxService {
  static PermissionService get to => Get.find<PermissionService>();

  final AuthService auth = Get.find<AuthService>();

  // Role Checks
  bool get isOwner => auth.isSuperAdmin;
  bool get isManager => auth.isManager;
  bool get isStaff => auth.isStaff;

  // ---------------------------------------------------------------------------
  // Financial & Operational Visibility (Spec Section 2 & 16)
  // ---------------------------------------------------------------------------
  bool get canViewFinancialMetrics => isOwner; // Gross Profit, Net Profit, COGS, Distributable Profit
  bool get canViewOperationalAnalytics => isOwner || isManager; // Units sold, stock movements, procurement
  bool get canViewPurchaseCost => isOwner || isManager; // Staff cannot see acquisition cost
  bool get canViewStockValuation => isOwner || isManager; // Staff cannot see total stock value

  // ---------------------------------------------------------------------------
  // Product, Pricing & Inventory Permissions
  // ---------------------------------------------------------------------------
  bool get canManageInventory => isOwner || isManager;
  bool get canCreateProduct => isOwner || isManager;
  bool get canRestockInventory => isOwner || isManager;
  bool get canChangeSellingPrice => isOwner || isManager;
  bool get canConfigureMinimumPriceFloor => isOwner; // Owner-only minimum bargain floor
  bool get canExportReports => isOwner || isManager;

  // ---------------------------------------------------------------------------
  // Discounts & Approvals (Spec Section 4.3 & 17.1)
  // ---------------------------------------------------------------------------
  bool get canRequestDiscount => isManager;
  bool get canApproveDiscount => isOwner;

  // ---------------------------------------------------------------------------
  // Sales & Receipts (Spec Section 5.1 & 6.2)
  // ---------------------------------------------------------------------------
  bool get canCreateSale => true;
  bool get canCorrectSale => isOwner || isManager;
  bool get canDeleteSale => isOwner; // Audited

  // ---------------------------------------------------------------------------
  // Expenses (Spec Section 6.3 & 9.6)
  // ---------------------------------------------------------------------------
  bool get canCreateExpense => true;
  bool get canEditDeleteExpense => isOwner || isManager;
  bool get canViewAllExpenses => isOwner || isManager; // Staff sees only own expenses in last 30 days

  // ---------------------------------------------------------------------------
  // Returns, Refunds & Exchanges (Spec Section 8)
  // ---------------------------------------------------------------------------
  bool get canResolveRefunds => isOwner || isManager;
  bool get canOverrideExchangeFloor => isOwner;

  // ---------------------------------------------------------------------------
  // Suppliers (Spec Section 5.3)
  // ---------------------------------------------------------------------------
  bool get canManageSuppliers => isOwner || isManager;

  // ---------------------------------------------------------------------------
  // Owner-Exclusive Financial Modules (Spec Section 11, 12, 13)
  // ---------------------------------------------------------------------------
  bool get canManageInvestors => isOwner;
  bool get canManageBorrowedLoans => isOwner;
  bool get canManageMoneyLent => isOwner;

  // ---------------------------------------------------------------------------
  // Administration, Audit & Cloud Sync
  // ---------------------------------------------------------------------------
  bool get canViewCompleteAuditLogs => isOwner;
  bool get canBackupRestore => isOwner;
  bool get canConfigurePolicies => isOwner;

  // Helper method to guard programmatic execution
  void assertCan(bool condition, String actionDescription) {
    if (!condition) {
      throw Exception('Access Denied: You do not have permission to $actionDescription.');
    }
  }
}
