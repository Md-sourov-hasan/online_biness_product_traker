import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../routes/app_routes.dart';
import '../controllers/notifications_controller.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationsController controller = Get.find<NotificationsController>();
    final AuthService auth = Get.find<AuthService>();
    final PermissionService perm = Get.find<PermissionService>();
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();

    return CommonBackgroundScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, themeService),
            Expanded(
              child: Obx(() {
                final user = auth.currentUser.value;
                final isOwner = perm.isOwner;
                final isManager = perm.isManager;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role banner
                      _buildRoleBanner(user?.role ?? 'Owner', themeService),
                      16.verticalSpace,

                      if (isOwner)
                        _buildOwnerSettings(context, controller, themeService)
                      else if (isManager)
                        _buildManagerSettings(context, controller, themeService)
                      else
                        _buildStaffSettings(context, controller, themeService),

                      20.verticalSpace,

                      // Test Notification Action
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            controller.sendTestNotification();
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('Send Test Notification'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                      30.verticalSpace,
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header App Bar ---
  Widget _buildAppBar(BuildContext context, ThemeLanguageService themeService) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: themeService.t.border),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16.w,
                    color: themeService.textColor,
                  ),
                ),
              ),
              12.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Settings',
                    style: getTextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: themeService.textColor,
                    ),
                  ),
                  2.verticalSpace,
                  Text(
                    'Triggers, delivery & channel preferences',
                    style: getTextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: themeService.subtextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: themeService.textColor),
            onPressed: () {
              final controller = Get.find<NotificationsController>();
              controller.refreshAll();
              Get.snackbar('Refreshed', 'Notification preferences synchronized',
                  snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
            },
          ),
        ],
      ),
    );
  }

  // --- Role Badge Banner ---
  Widget _buildRoleBanner(String role, ThemeLanguageService themeService) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.primary, size: 20.w),
          10.horizontalSpace,
          Expanded(
            child: Text(
              'Configuring alerts for: $role',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: themeService.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. OWNER SETTINGS (Spec Section 5)
  // ===========================================================================
  Widget _buildOwnerSettings(
    BuildContext context,
    NotificationsController controller,
    ThemeLanguageService theme,
  ) {
    final s = controller.settings.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Master Switch Card
        _buildSectionCard(
          theme: theme,
          title: 'Master Control',
          subtitle: 'Global toggle for all operational notifications',
          icon: Icons.power_settings_new_rounded,
          iconColor: AppColors.primary,
          child: SwitchListTile(
            title: Text('Enable Push & Inbox Alerts', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
            subtitle: Text('Receive notifications across all assigned modules', style: TextStyle(color: theme.subtextColor, fontSize: 11.sp)),
            value: s.masterSwitch,
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              s.masterSwitch = val;
              controller.settings.refresh();
              controller.saveSettings();
            },
          ),
        ),
        16.verticalSpace,

        // Recipient Filter
        _buildSectionCard(
          theme: theme,
          title: 'Actor Filter',
          subtitle: 'Control which team actions notify you',
          icon: Icons.filter_alt_rounded,
          iconColor: AppColors.secondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notify me about actions from:', style: TextStyle(color: theme.subtextColor, fontSize: 11.sp)),
              8.verticalSpace,
              Wrap(
                spacing: 8.w,
                children: [
                  _buildFilterChip('Everyone', 'everyone', s.recipientFilter, (v) {
                    s.recipientFilter = v;
                    controller.settings.refresh();
                    controller.saveSettings();
                  }, theme),
                  _buildFilterChip('Manager Only', 'manager_only', s.recipientFilter, (v) {
                    s.recipientFilter = v;
                    controller.settings.refresh();
                    controller.saveSettings();
                  }, theme),
                  _buildFilterChip('Staff Only', 'staff_only', s.recipientFilter, (v) {
                    s.recipientFilter = v;
                    controller.settings.refresh();
                    controller.saveSettings();
                  }, theme),
                ],
              ),
            ],
          ),
        ),
        16.verticalSpace,

        // Category Groups
        _buildSectionCard(
          theme: theme,
          title: 'Category Channels',
          subtitle: 'Granular subscriptions per operational domain',
          icon: Icons.tune_rounded,
          iconColor: AppColors.warning,
          child: Column(
            children: [
              _buildSwitchRow(
                'Sales & Returns',
                'SAL-01, SAL-04, SAL-05, RET-01, RET-02, RET-03',
                s.salesAndReturns,
                (v) {
                  s.salesAndReturns = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
              const Divider(height: 16),
              _buildSwitchRow(
                'Expenses & Outflows',
                'EXP-01, EXP-02, EXP-03, EXP-04',
                s.expenses,
                (v) {
                  s.expenses = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
              const Divider(height: 16),
              _buildSwitchRow(
                'Stock & Suppliers',
                'STK-01, STK-02, STK-03, STK-04, SUP-01',
                s.stockAndSuppliers,
                (v) {
                  s.stockAndSuppliers = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
              const Divider(height: 16),
              _buildSwitchRow(
                'Money Records (Loans & Debt)',
                'MNY-01, MNY-02, MNY-03 (Owner exclusive)',
                s.moneyRecords,
                (v) {
                  s.moneyRecords = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
              const Divider(height: 16),
              _buildSwitchRow(
                'Users & Security Approvals',
                'USR-01: Device & role authorization requests',
                s.usersAndSecurity,
                (v) {
                  s.usersAndSecurity = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
              const Divider(height: 16),
              _buildSwitchRow(
                'Reports & System Summaries',
                'SYS-01 (Daily summary), SYS-02 (Backup reminder)',
                s.reportsAndSystem,
                (v) {
                  s.reportsAndSystem = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
            ],
          ),
        ),
        16.verticalSpace,

        // Large Expense Threshold (Spec Section 5)
        _buildSectionCard(
          theme: theme,
          title: 'Large-Expense Alert Threshold',
          subtitle: 'EXP-04: Alert when an expense reaches this amount',
          icon: Icons.payments_rounded,
          iconColor: Colors.deepOrangeAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trigger Amount:', style: TextStyle(color: theme.subtextColor, fontSize: 12.sp)),
                  Text(
                    '৳${s.largeExpenseThreshold.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                    ),
                  ),
                ],
              ),
              Slider(
                value: s.largeExpenseThreshold.clamp(1000.0, 50000.0),
                min: 1000.0,
                max: 50000.0,
                divisions: 49,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  s.largeExpenseThreshold = val;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
              ),
            ],
          ),
        ),
        16.verticalSpace,

        // Quiet Hours Section
        _buildSectionCard(
          theme: theme,
          title: 'Quiet Hours',
          subtitle: 'Mute non-critical push notifications during rest hours',
          icon: Icons.bedtime_rounded,
          iconColor: Colors.purpleAccent,
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Enable Quiet Hours', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                value: s.quietHoursEnabled,
                activeThumbColor: Colors.purpleAccent,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  s.quietHoursEnabled = val;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
              ),
              if (s.quietHoursEnabled) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeTile('Start', s.quietHoursStart, () async {
                        final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 0));
                        if (time != null) {
                          s.quietHoursStart = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          controller.settings.refresh();
                          controller.saveSettings();
                        }
                      }, theme),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: _buildTimeTile('End', s.quietHoursEnd, () async {
                        final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
                        if (time != null) {
                          s.quietHoursEnd = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          controller.settings.refresh();
                          controller.saveSettings();
                        }
                      }, theme),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        16.verticalSpace,

        // Link to Owner Policy Controls
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: theme.t.border),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20.w, color: AppColors.primary),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  'Price floor, sale limits, and low-stock limits are configured on the Owner Policy screen. Notification triggers automatically sync with those settings.',
                  style: TextStyle(color: theme.subtextColor, fontSize: 11.sp),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoute.policyControlScreen),
                child: const Text('Policies'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. MANAGER SETTINGS (Spec Section 5)
  // ===========================================================================
  Widget _buildManagerSettings(
    BuildContext context,
    NotificationsController controller,
    ThemeLanguageService theme,
  ) {
    final s = controller.settings.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          theme: theme,
          title: 'Manager Alert Subscriptions',
          subtitle: 'Configure alerts for operations under your management',
          icon: Icons.manage_accounts_rounded,
          iconColor: AppColors.secondary,
          child: Column(
            children: [
              _buildSwitchRow(
                'My Actions',
                'Confirmation alerts for sales, purchases, expenses & refunds you perform',
                s.myActions,
                (v) {
                  s.myActions = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
              const Divider(height: 16),
              _buildSwitchRow(
                'Staff Sales & Returns',
                'Alerts for sales completed (SAL-01), blocked sales (SAL-04/05), and returns (RET-01/02/03)',
                s.staffSalesAndReturns,
                (v) {
                  s.staffSalesAndReturns = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
              const Divider(height: 16),
              _buildSwitchRow(
                'Staff Expenses',
                'Alerts when Staff submit or edit operating expenses (EXP-01, EXP-02)',
                s.staffExpenses,
                (v) {
                  s.staffExpenses = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
              const Divider(height: 16),
              _buildSwitchRow(
                'Stock & Inventory Alerts',
                'Low stock warnings (STK-01) and out-of-stock notices (STK-02)',
                s.stockAlerts,
                (v) {
                  s.stockAlerts = v;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
                theme,
              ),
              const Divider(height: 16),
              // DSC-02: Discount Result (Always Enabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Discount Request Result (DSC-02)', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                subtitle: Text('Results of your discount approval requests to Owner', style: TextStyle(color: theme.subtextColor, fontSize: 11.sp)),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text('Always Active', style: TextStyle(color: AppColors.success, fontSize: 10.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        16.verticalSpace,

        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: theme.t.border),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 20.w, color: theme.subtextColor),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  'Privacy Note: The Manager does not receive Owner actions, loans, money lent, investor changes, policy modifications, user approvals, daily summaries, or backup reminders.',
                  style: TextStyle(color: theme.subtextColor, fontSize: 11.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. STAFF SETTINGS (Spec Section 5)
  // ===========================================================================
  Widget _buildStaffSettings(
    BuildContext context,
    NotificationsController controller,
    ThemeLanguageService theme,
  ) {
    final s = controller.settings.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          theme: theme,
          title: 'Terminal Notifications',
          subtitle: 'Alerts relevant to your POS sales terminal',
          icon: Icons.point_of_sale_rounded,
          iconColor: AppColors.teal,
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Terminal Notifications', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                subtitle: Text('Receive confirmations and terminal updates', style: TextStyle(color: theme.subtextColor, fontSize: 11.sp)),
                value: s.staffMasterSwitch,
                activeThumbColor: AppColors.teal,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  s.staffMasterSwitch = val;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
              ),
              const Divider(height: 16),
              SwitchListTile(
                title: Text('End-of-Day Reminder (STF-06)', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                subtitle: Text('Reminder alert if no daily expenses have been logged', style: TextStyle(color: theme.subtextColor, fontSize: 11.sp)),
                value: s.endOfDayReminder,
                activeThumbColor: AppColors.teal,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  s.endOfDayReminder = val;
                  controller.settings.refresh();
                  controller.saveSettings();
                },
              ),
            ],
          ),
        ),
        16.verticalSpace,

        // Supported Staff Notifications List (Read-Only per Spec Section 5)
        _buildSectionCard(
          theme: theme,
          title: 'Supported Staff Notifications',
          subtitle: 'The explicit list of notifications designed for Staff terminals',
          icon: Icons.checklist_rounded,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStaffNotificationInfo('STF-01', 'Sale Saved', 'Immediate confirmation after completing a customer sale.', theme),
              _buildStaffNotificationInfo('STF-02', 'Expense Saved', 'Confirmation after submitting an operating expense.', theme),
              _buildStaffNotificationInfo('STF-03', 'Entry Corrected', 'Alert when Owner or Manager corrects your expense entry.', theme),
              _buildStaffNotificationInfo('STF-04', 'Entry Removed', 'Alert when Owner or Manager removes your expense entry.', theme),
              _buildStaffNotificationInfo('STF-05', 'Out of Stock', 'In-app notification if stock runs out during a transaction.', theme),
              _buildStaffNotificationInfo('STF-06', 'End-of-Day Reminder', 'Reminder to record expenses before store closing.', theme),
              _buildStaffNotificationInfo('STF-07', 'Sale Blocked', 'Notice when price floor or per-sale limits block an item.', theme),
              _buildStaffNotificationInfo('STF-08', 'Account Update', 'Notice when your account/device is approved or role changes.', theme),
              _buildStaffNotificationInfo('STF-09', 'Return/Exchange Result', 'Result of processed return or customer exchange.', theme),
            ],
          ),
        ),
        16.verticalSpace,

        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: theme.t.border),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 20.w, color: AppColors.teal),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  'Confidentiality Guard: Staff terminals never display profit, purchase cost, loans, investors, or entries created by other staff.',
                  style: TextStyle(color: theme.subtextColor, fontSize: 11.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helpers ---
  Widget _buildSectionCard({
    required ThemeLanguageService theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: iconColor, size: 20.w),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
                    Text(subtitle, style: getTextStyle(fontSize: 11.sp, color: theme.subtextColor)),
                  ],
                ),
              ),
            ],
          ),
          14.verticalSpace,
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeLanguageService theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 13.sp)),
              2.verticalSpace,
              Text(subtitle, style: TextStyle(color: theme.subtextColor, fontSize: 10.sp)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String selectedValue,
    ValueChanged<String> onSelected,
    ThemeLanguageService theme,
  ) {
    final isSelected = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.primary,
      backgroundColor: theme.t.surfaceAlt,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.textColor,
        fontSize: 11.sp,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildTimeTile(String label, String value, VoidCallback onTap, ThemeLanguageService theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: theme.t.surfaceAlt,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: theme.t.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: theme.subtextColor, fontSize: 12.sp)),
            Text(value, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700, fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffNotificationInfo(String code, String title, String desc, ThemeLanguageService theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(code, style: TextStyle(color: AppColors.teal, fontSize: 10.sp, fontWeight: FontWeight.w800)),
          ),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 12.sp)),
                Text(desc, style: TextStyle(color: theme.subtextColor, fontSize: 10.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
