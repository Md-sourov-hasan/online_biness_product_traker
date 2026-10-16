class AppConstants {
  static const String appName = 'StockMate';
  static const String appTagline = 'Smart Inventory & Business Management';
  static const String defaultCurrency = '৳';
  static const String currencyName = 'BDT';

  // Expense Categories
  static const List<String> expenseCategories = [
    'Rent',
    'Utilities',
    'Transport & Delivery',
    'Packaging',
    'Salary & Wages',
    'Marketing & Ads',
    'Maintenance',
    'Office Supplies',
    'Others',
  ];

  // User Roles
  static const String roleOwner = 'Super Admin (Owner)';
  static const String roleManager = 'Manager';
  static const String roleStaff = 'Staff';

  static const List<String> userRoles = [
    roleOwner,
    roleManager,
    roleStaff,
  ];

  // Approval Statuses
  static const String statusApproved = 'approved';
  static const String statusPending = 'pending';
  static const String statusRejected = 'rejected';
}
