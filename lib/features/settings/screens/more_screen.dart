import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../controllers/settings_controller.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/widgets/stockmate_components.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../routes/app_routes.dart';
import '../../notifications/controllers/notifications_controller.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());
    final NotificationsController notifController = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final AuthService auth = Get.find<AuthService>();
    final PermissionService perm = Get.find<PermissionService>();

    return Obx(() {
      final t = themeService.t;
      final user = auth.currentUser.value;

      return Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'More Options',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: t.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: t.accentLight,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: t.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_rounded, size: 14.w, color: t.accent),
                          6.horizontalSpace,
                          Text(
                            user?.role ?? 'Owner',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: t.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,

                // 1. User Profile & Quick Role Switcher Card
                RepaintBoundary(
                  child: _buildUserProfileCard(user, auth, perm, t),
                ),
                20.verticalSpace,

                // 2. Primary Operations & Reports (Grid of Featured Cards)
                _buildSectionTitle('Operational Modules & Financials', t),
                10.verticalSpace,
                RepaintBoundary(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Purchases & Expenses Card
                          Expanded(
                            child: _buildFeaturedCard(
                              title: 'Purchases &\nExpenses',
                              subtitle: 'Expenses & Stock In',
                              icon: Icons.receipt_long_rounded,
                              accentColor: t.warning,
                              bgColor: t.warningLight,
                              t: t,
                              onTap: () => context.push(AppRoute.purchasesExpensesScreen),
                            ),
                          ),
                          12.horizontalSpace,
                          // Financial Reports Card
                          Expanded(
                            child: _buildFeaturedCard(
                              title: 'Reports &\nP&L Engine',
                              subtitle: 'Full Statements',
                              icon: Icons.analytics_rounded,
                              accentColor: t.success,
                              bgColor: t.successLight,
                              t: t,
                              onTap: () => context.push(AppRoute.reportsScreen),
                            ),
                          ),
                        ],
                      ),
                      12.verticalSpace,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Business Analytics Card
                          Expanded(
                            child: _buildFeaturedCard(
                              title: 'Analytics &\nTrends',
                              subtitle: 'Annual KPIs',
                              icon: Icons.trending_up_rounded,
                              accentColor: t.purple,
                              bgColor: t.purpleLight,
                              t: t,
                              onTap: () => context.push(AppRoute.analyticsScreen),
                            ),
                          ),
                          12.horizontalSpace,
                          // Appearance & Theme Card (Themes Spec Section 7.1)
                          Expanded(
                            child: _buildThemeFeaturedCard(
                              themeService: themeService,
                              t: t,
                              onTap: () => context.push(AppRoute.themeScreen),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                24.verticalSpace,

                // 3. Governance & Business Controls (Manager & Owner)
                if (perm.isOwner || perm.isManager) ...[
                  _buildSectionTitle('Governance & Financial Controls', t),
                  10.verticalSpace,
                  RepaintBoundary(
                    child: _buildGovernanceCards(context, perm, t),
                  ),
                  24.verticalSpace,
                ] else ...[
                  // Staff Operational Notice Card
                  RepaintBoundary(
                    child: StockMateCard(
                      t: t,
                      padding: EdgeInsets.all(14.w),
                      child: Row(
                        children: [
                          Icon(Icons.lock_clock_rounded, color: t.warning, size: 28.w),
                          14.horizontalSpace,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Staff Terminal Access',
                                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: t.text),
                                ),
                                2.verticalSpace,
                                Text(
                                  'Executive governance, borrowing, and investor records are reserved for Managers and Owners.',
                                  style: TextStyle(fontSize: 11.sp, color: t.textSec),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  20.verticalSpace,
                ],

                // 4. Administration & System Security
                if (!perm.isStaff) ...[
                  _buildSectionTitle('Administration & Audit Security', t),
                  10.verticalSpace,
                  RepaintBoundary(
                    child: _buildAdminCards(context, perm, t),
                  ),
                  24.verticalSpace,
                ],

                // 5. Notifications & Operational Alerts (Spec Section 5)
                _buildSectionTitle('Notifications & Real-Time Alerts', t),
                10.verticalSpace,
                RepaintBoundary(
                  child: _buildNotificationCards(context, notifController, t),
                ),
                24.verticalSpace,

                // 6. System Preferences (Language & Currency)
                _buildSectionTitle('System Preferences', t),
                10.verticalSpace,
                RepaintBoundary(
                  child: _buildPreferencesCard(controller, themeService, t),
                ),
                24.verticalSpace,

                // 6. Log Out Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) {
                        context.go(AppRoute.loginScreen);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.danger,
                      side: BorderSide(color: t.danger),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Log Out & Switch User Role', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                20.verticalSpace,

                // App Tagline & Version Info
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${AppConstants.appName} v1.0.0 (Six-Theme Production Build)',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: t.textSec),
                      ),
                      3.verticalSpace,
                      Text(
                        AppConstants.appTagline,
                        style: TextStyle(fontSize: 10.sp, color: t.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // --- Header Section Title Helper ---
  Widget _buildSectionTitle(String title, ThemeTokens t) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: t.text,
      ),
    );
  }

  // --- Featured Action Card (Big Tile) ---
  Widget _buildFeaturedCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required ThemeTokens t,
    required VoidCallback onTap,
  }) {
    return _FeaturedActionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accentColor: accentColor,
      bgColor: bgColor,
      t: t,
      onTap: onTap,
    );
  }

  // --- Appearance & Theme Featured Card (Section 7.1) ---
  Widget _buildThemeFeaturedCard({
    required ThemeLanguageService themeService,
    required ThemeTokens t,
    required VoidCallback onTap,
  }) {
    return _ThemeFeaturedActionCard(
      themeService: themeService,
      t: t,
      onTap: onTap,
    );
  }

  // --- Governance Menu Cards ---
  Widget _buildGovernanceCards(BuildContext context, PermissionService perm, ThemeTokens t) {
    return StockMateCard(
      t: t,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.domain_add_rounded,
            title: 'Branch Management',
            subtitle: 'Add new outlets, managers & store quotas',
            color: t.accent,
            t: t,
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: t.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: t.warning.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: t.warning,
                ),
              ),
            ),
            onTap: () => context.push(AppRoute.branchManagementScreen),
          ),
          Divider(height: 1, color: t.border),
          _buildMenuRow(
            icon: Icons.gavel_rounded,
            title: 'Policy & Price Floor Controls',
            subtitle: 'Minimum price %, daily ceilings, exchange floor',
            color: t.accent,
            t: t,
            onTap: () => context.push(AppRoute.policyControlScreen),
          ),
          Divider(height: 1, color: t.border),
          _buildMenuRow(
            icon: Icons.discount_rounded,
            title: 'Discount Rules & Approvals',
            subtitle: 'Manager discount requests & Owner approval',
            color: t.purple,
            t: t,
            onTap: () => context.push(AppRoute.discountManagementScreen),
          ),
          Divider(height: 1, color: t.border),
          _buildMenuRow(
            icon: Icons.local_shipping_rounded,
            title: 'Supplier & Vendor Directory',
            subtitle: 'Manage vendor contacts and purchase orders',
            color: t.success,
            t: t,
            onTap: () => context.push(AppRoute.supplierManagementScreen),
          ),
          if (perm.isOwner) ...[
            Divider(height: 1, color: t.border),
            _buildMenuRow(
              icon: Icons.pie_chart_rounded,
              title: 'Investor Management Hub',
              subtitle: 'Cap table, equity %, profit distributions',
              color: t.warning,
              t: t,
              onTap: () => context.push(AppRoute.investorManagementScreen),
            ),
            Divider(height: 1, color: t.border),
            _buildMenuRow(
              icon: Icons.account_balance_rounded,
              title: 'Borrowed Loans (Liabilities)',
              subtitle: 'Principal repayment, interest & status',
              color: t.danger,
              t: t,
              onTap: () => context.push(AppRoute.loanManagementScreen),
            ),
            Divider(height: 1, color: t.border),
            _buildMenuRow(
              icon: Icons.handshake_rounded,
              title: 'Money Lent (Receivables)',
              subtitle: 'Debtor collection, pending balance & receipts',
              color: t.success,
              t: t,
              onTap: () => context.push(AppRoute.moneyLentScreen),
            ),
          ],
        ],
      ),
    );
  }

  // --- Admin Security Menu Cards ---
  Widget _buildAdminCards(BuildContext context, PermissionService perm, ThemeTokens t) {
    return StockMateCard(
      t: t,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (perm.isOwner) ...[
            _buildMenuRow(
              icon: Icons.manage_accounts_rounded,
              title: 'User & Role Management',
              subtitle: 'Configure staff permissions & approve devices',
              color: t.accent,
              t: t,
              onTap: () => context.push(AppRoute.userManagementScreen),
            ),
            Divider(height: 1, color: t.border),
          ],
          _buildMenuRow(
            icon: Icons.cloud_sync_rounded,
            title: 'Cloud Backup & Restore',
            subtitle: 'Export encrypted snapshots & state recovery',
            color: t.success,
            t: t,
            onTap: () => context.push(AppRoute.backupSyncScreen),
          ),
          Divider(height: 1, color: t.border),
          _buildMenuRow(
            icon: Icons.history_edu_rounded,
            title: 'Activity & Audit Trail',
            subtitle: '6-month chronological activity log',
            color: t.warning,
            t: t,
            onTap: () => context.push(AppRoute.activityLogsScreen),
          ),
        ],
      ),
    );
  }

  // --- Notifications Menu Cards (Spec Section 5) ---
  Widget _buildNotificationCards(
    BuildContext context,
    NotificationsController notifController,
    ThemeTokens t,
  ) {
    return StockMateCard(
      t: t,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications Inbox',
            subtitle: 'Real-time alerts, operational logs & confirmations',
            color: t.accent,
            t: t,
            trailing: Obx(() {
              final count = notifController.unreadCount;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: t.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: t.danger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$count new',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: t.danger,
                  ),
                ),
              );
            }),
            onTap: () => context.push(AppRoute.notificationsScreen),
          ),
          Divider(height: 1, color: t.border),
          _buildMenuRow(
            icon: Icons.tune_rounded,
            title: 'Notification Settings',
            subtitle: 'Role subscriptions, category toggles & quiet hours',
            color: t.purple,
            t: t,
            onTap: () => context.push(AppRoute.notificationSettingsScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ThemeTokens t,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: color, size: 20.w),
              ),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: t.textSec,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing,
                8.horizontalSpace,
              ],
              Icon(Icons.arrow_forward_ios_rounded, color: t.textSec, size: 14.w),
            ],
          ),
        ),
      ),
    );
  }

  // --- Preferences Card (Language & Currency) ---
  Widget _buildPreferencesCard(
    SettingsController controller,
    ThemeLanguageService themeService,
    ThemeTokens t,
  ) {
    return StockMateCard(
      t: t,
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Language & Localization',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: t.text),
          ),
          10.verticalSpace,
          Obx(() {
            final langCode = themeService.currentLocale.value.languageCode;
            return Row(
              children: [
                Expanded(
                  child: _buildChoiceChip(
                    label: 'English (US)',
                    isSelected: langCode == 'en',
                    onTap: () => controller.changeLanguage('en', 'US'),
                    t: t,
                  ),
                ),
                8.horizontalSpace,
                Expanded(
                  child: _buildChoiceChip(
                    label: 'বাংলা (BD)',
                    isSelected: langCode == 'bn',
                    onTap: () => controller.changeLanguage('bn', 'BD'),
                    t: t,
                  ),
                ),
              ],
            );
          }),
          14.verticalSpace,
          Text(
            'Currency Symbol',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: t.text),
          ),
          10.verticalSpace,
          Obx(() {
            final curr = themeService.currentCurrency.value;
            return Row(
              children: [
                Expanded(
                  child: _buildChoiceChip(
                    label: '\$ USD',
                    isSelected: curr == 'USD',
                    onTap: () => themeService.setCurrency('USD'),
                    t: t,
                  ),
                ),
                8.horizontalSpace,
                Expanded(
                  child: _buildChoiceChip(
                    label: '৳ BDT',
                    isSelected: curr == 'BDT',
                    onTap: () => themeService.setCurrency('BDT'),
                    t: t,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeTokens t,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? t.accent : t.surfaceAlt,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? t.accent : t.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : t.text,
          ),
        ),
      ),
    );
  }

  // --- User Profile Card ---
  Widget _buildUserProfileCard(
    AppUser? user,
    AuthService auth,
    PermissionService perm,
    ThemeTokens t,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: t.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26.w,
                backgroundColor: t.accent.withValues(alpha: 0.15),
                child: Icon(Icons.person_rounded, color: t.accent, size: 28.w),
              ),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Store Administrator',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: t.text,
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      user?.email ?? 'owner@stockmate.com',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: t.textSec,
                      ),
                    ),
                    6.verticalSpace,
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: t.accentLight,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            user?.role ?? AppConstants.roleOwner,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: t.accent,
                            ),
                          ),
                        ),
                        8.horizontalSpace,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: t.successLight,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_user_rounded, size: 11.w, color: t.success),
                              4.horizontalSpace,
                              Text(
                                '2FA Secure',
                                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: t.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Divider(color: t.border),
          8.verticalSpace,

          // Quick Role Switcher Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Switch Live Role:',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: t.textSec),
              ),
              Text(
                'Active: ${user?.role}',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: t.accent),
              ),
            ],
          ),
          8.verticalSpace,
          Row(
            children: [
              _buildRoleChip('Owner', AppConstants.roleOwner, user?.role == AppConstants.roleOwner, () {
                auth.switchUserRole(AppConstants.roleOwner);
              }, t),
              8.horizontalSpace,
              _buildRoleChip('Manager', AppConstants.roleManager, user?.role == AppConstants.roleManager, () {
                auth.switchUserRole(AppConstants.roleManager);
              }, t),
              8.horizontalSpace,
              _buildRoleChip('Staff', AppConstants.roleStaff, user?.role == AppConstants.roleStaff, () {
                auth.switchUserRole(AppConstants.roleStaff);
              }, t),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String roleValue, bool isSelected, VoidCallback onTap, ThemeTokens t) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? t.accent : t.surfaceAlt,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? t.accent : t.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : t.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final ThemeTokens t;
  final VoidCallback onTap;

  const _FeaturedActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.t,
    required this.onTap,
  });

  @override
  State<_FeaturedActionCard> createState() => _FeaturedActionCardState();
}

class _FeaturedActionCardState extends State<_FeaturedActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final accentColor = widget.accentColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        _scaleController.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(minHeight: 128.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: t.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: t.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(7.w),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(widget.icon, color: accentColor, size: 20.w),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: t.textSec, size: 12.w),
                ],
              ),
              10.verticalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                      height: 1.2,
                    ),
                  ),
                  3.verticalSpace,
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeFeaturedActionCard extends StatefulWidget {
  final ThemeLanguageService themeService;
  final ThemeTokens t;
  final VoidCallback onTap;

  const _ThemeFeaturedActionCard({
    required this.themeService,
    required this.t,
    required this.onTap,
  });

  @override
  State<_ThemeFeaturedActionCard> createState() => _ThemeFeaturedActionCardState();
}

class _ThemeFeaturedActionCardState extends State<_ThemeFeaturedActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        _scaleController.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(minHeight: 128.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: t.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ThemePreviewTile(
                    theme: t,
                    activeTheme: t,
                    variant: PreviewVariant.S,
                  ),
                  Row(
                    children: [
                      Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent)),
                      3.horizontalSpace,
                      Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: t.success)),
                      3.horizontalSpace,
                      Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: t.warning)),
                    ],
                  ),
                ],
              ),
              10.verticalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Appearance &\nTheme System',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                      height: 1.2,
                    ),
                  ),
                  3.verticalSpace,
                  Text(
                    t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: t.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
