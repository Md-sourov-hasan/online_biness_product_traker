import 'dart:convert';

class NotificationSettingsModel {
  // --- Owner Settings ---
  bool masterSwitch;
  bool salesAndReturns;
  bool expenses;
  bool stockAndSuppliers;
  bool moneyRecords;
  bool usersAndSecurity;
  bool reportsAndSystem;
  String recipientFilter; // 'everyone', 'manager_only', 'staff_only'
  bool quietHoursEnabled;
  String quietHoursStart; // '22:00'
  String quietHoursEnd; // '07:00'
  double largeExpenseThreshold;

  // --- Manager Settings ---
  bool myActions;
  bool staffSalesAndReturns;
  bool staffExpenses;
  bool stockAlerts;
  // DSC-02: Discount result is ALWAYS on and cannot be disabled

  // --- Staff Settings ---
  bool staffMasterSwitch;
  bool endOfDayReminder;

  NotificationSettingsModel({
    this.masterSwitch = true,
    this.salesAndReturns = true,
    this.expenses = true,
    this.stockAndSuppliers = true,
    this.moneyRecords = true,
    this.usersAndSecurity = true,
    this.reportsAndSystem = true,
    this.recipientFilter = 'everyone',
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.largeExpenseThreshold = 5000.0,
    this.myActions = true,
    this.staffSalesAndReturns = true,
    this.staffExpenses = true,
    this.stockAlerts = true,
    this.staffMasterSwitch = true,
    this.endOfDayReminder = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'masterSwitch': masterSwitch,
      'salesAndReturns': salesAndReturns,
      'expenses': expenses,
      'stockAndSuppliers': stockAndSuppliers,
      'moneyRecords': moneyRecords,
      'usersAndSecurity': usersAndSecurity,
      'reportsAndSystem': reportsAndSystem,
      'recipientFilter': recipientFilter,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'largeExpenseThreshold': largeExpenseThreshold,
      'myActions': myActions,
      'staffSalesAndReturns': staffSalesAndReturns,
      'staffExpenses': staffExpenses,
      'stockAlerts': stockAlerts,
      'staffMasterSwitch': staffMasterSwitch,
      'endOfDayReminder': endOfDayReminder,
    };
  }

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      masterSwitch: map['masterSwitch'] ?? true,
      salesAndReturns: map['salesAndReturns'] ?? true,
      expenses: map['expenses'] ?? true,
      stockAndSuppliers: map['stockAndSuppliers'] ?? true,
      moneyRecords: map['moneyRecords'] ?? true,
      usersAndSecurity: map['usersAndSecurity'] ?? true,
      reportsAndSystem: map['reportsAndSystem'] ?? true,
      recipientFilter: map['recipientFilter'] ?? 'everyone',
      quietHoursEnabled: map['quietHoursEnabled'] ?? false,
      quietHoursStart: map['quietHoursStart'] ?? '22:00',
      quietHoursEnd: map['quietHoursEnd'] ?? '07:00',
      largeExpenseThreshold: (map['largeExpenseThreshold'] ?? 5000.0).toDouble(),
      myActions: map['myActions'] ?? true,
      staffSalesAndReturns: map['staffSalesAndReturns'] ?? true,
      staffExpenses: map['staffExpenses'] ?? true,
      stockAlerts: map['stockAlerts'] ?? true,
      staffMasterSwitch: map['staffMasterSwitch'] ?? true,
      endOfDayReminder: map['endOfDayReminder'] ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory NotificationSettingsModel.fromJson(String source) =>
      NotificationSettingsModel.fromMap(jsonDecode(source));
}
