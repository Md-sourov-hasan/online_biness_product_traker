import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../controllers/settings_controller.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.put(SettingsController());
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final AuthService auth = Get.find<AuthService>();
    final PermissionService perm = Get.find<PermissionService>();

    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'settings_title'.tr,
          style: getTextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile & Fast Role Switcher
            _buildUserProfileCard(auth, perm, themeService),
            20.verticalSpace,

            // 2. 3-Tier Theme Engine (Light, Dark, Midnight)
            _buildSectionHeader('theme_title'.tr, Icons.palette_rounded, themeService),
            8.verticalSpace,
            _buildThemeSelector(controller, themeService),
            20.verticalSpace,

            // 3. Language Selector (English / বাংলা)
            _buildSectionHeader('language_title'.tr, Icons.language_rounded, themeService),
            8.verticalSpace,
            _buildLanguageSelector(controller, themeService),
            20.verticalSpace,

            // 4. Owner & Manager Governance Hub (Spec Section 16 & RBAC)
            if (perm.isOwner || perm.isManager) ...[
              _buildSectionHeader('Owner & Management Control Hub', Icons.security_rounded, themeService),
              8.verticalSpace,
              _buildOwnerGovernanceMenu(context, perm, themeService),
              20.verticalSpace,
            ] else ...[
              // Staff Notice Banner
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 24.w),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Staff Operational Mode',
                            style: getTextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
                          ),
                          2.verticalSpace,
                          Text(
                            'Financial accounting, capital records, and administrative controls are restricted to Managers and Owners.',
                            style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              20.verticalSpace,
            ],

            // 5. Administration & Security (Backup & Audit)
            if (!perm.isStaff) ...[
              _buildSectionHeader('Administration & Security', Icons.admin_panel_settings_rounded, themeService),
              8.verticalSpace,
              _buildAdminMenu(context, controller, perm, themeService),
              24.verticalSpace,
            ],

            // 6. Log Out & Switch User Role (Accessible to all roles)
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
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log Out & Switch User Role', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            24.verticalSpace,

            // App Tagline & Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '${AppConstants.appName} v1.0.0 (Production Build)',
                    style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: themeService.subtextColor),
                  ),
                  4.verticalSpace,
                  Text(
                    AppConstants.appTagline,
                    style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                  ),
                ],
              ),
            ),
            80.verticalSpace,
          ],
        ),
      ),
    );
  }

  // --- 1. User Profile & Fast Role Switcher ---
  Widget _buildUserProfileCard(AuthService auth, PermissionService perm, ThemeLanguageService themeService) {
    return Obx(() {
      final user = auth.currentUser.value;
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28.w),
                ),
                14.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Store User',
                        style: getTextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: themeService.textColor,
                        ),
                      ),
                      2.verticalSpace,
                      Text(
                        user?.email ?? 'owner@stockmate.com',
                        style: getTextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: themeService.subtextColor,
                        ),
                      ),
                      6.verticalSpace,
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              user?.role ?? AppConstants.roleOwner,
                              style: getTextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          8.horizontalSpace,
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified_user_rounded, size: 12.w, color: AppColors.secondary),
                                4.horizontalSpace,
                                Text(
                                  '2FA Active',
                                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.secondary),
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
            Divider(color: themeService.inputBorderColor),
            8.verticalSpace,

            // Quick Role Switcher Chips for Demo / Testing (Spec 3-Tier Verification)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Role Switcher (RBAC Test):',
                      style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: themeService.subtextColor),
                    ),
                    Text(
                      'Active: ${user?.role}',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                8.verticalSpace,
                Row(
                  children: [
                    _buildRoleChip('Owner', AppConstants.roleOwner, user?.role == AppConstants.roleOwner, () {
                      auth.switchUserRole(AppConstants.roleOwner);
                    }),
                    8.horizontalSpace,
                    _buildRoleChip('Manager', AppConstants.roleManager, user?.role == AppConstants.roleManager, () {
                      auth.switchUserRole(AppConstants.roleManager);
                    }),
                    8.horizontalSpace,
                    _buildRoleChip('Staff', AppConstants.roleStaff, user?.role == AppConstants.roleStaff, () {
                      auth.switchUserRole(AppConstants.roleStaff);
                    }),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRoleChip(String label, String roleValue, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. 3-Tier Theme Selector ---
  Widget _buildThemeSelector(SettingsController controller, ThemeLanguageService themeService) {
    return Obx(() {
      final currentMode = themeService.currentThemeMode.value;
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            _buildThemeOption(
              label: 'theme_light'.tr,
              icon: Icons.wb_sunny_rounded,
              isSelected: currentMode == AppThemeMode.light,
              onTap: () => controller.changeTheme(AppThemeMode.light),
              color: const Color(0xFFF8FAFC),
              textColor: const Color(0xFF0F172A),
              themeService: themeService,
            ),
            8.horizontalSpace,
            _buildThemeOption(
              label: 'theme_dark'.tr,
              icon: Icons.dark_mode_rounded,
              isSelected: currentMode == AppThemeMode.dark,
              onTap: () => controller.changeTheme(AppThemeMode.dark),
              color: const Color(0xFF1E293B),
              textColor: Colors.white,
              themeService: themeService,
            ),
            8.horizontalSpace,
            _buildThemeOption(
              label: 'theme_midnight'.tr,
              icon: Icons.nightlight_round,
              isSelected: currentMode == AppThemeMode.midnight,
              onTap: () => controller.changeTheme(AppThemeMode.midnight),
              color: const Color(0xFF0E1626),
              textColor: const Color(0xFF38BDF8),
              themeService: themeService,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
    required ThemeLanguageService themeService,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : themeService.inputBorderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : textColor, size: 22.w),
              6.verticalSpace,
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: getTextStyle(
                    fontSize: 11.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. Language Selector ---
  Widget _buildLanguageSelector(SettingsController controller, ThemeLanguageService themeService) {
    return Obx(() {
      final locale = themeService.currentLocale.value;
      final isBangla = locale.languageCode == 'bn';

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.changeLanguage('en', 'US'),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: !isBangla ? AppColors.primary : themeService.inputFillColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      'lang_en'.tr,
                      style: getTextStyle(
                        fontSize: 13.sp,
                        fontWeight: !isBangla ? FontWeight.w700 : FontWeight.w500,
                        color: !isBangla ? Colors.white : themeService.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: GestureDetector(
                onTap: () => controller.changeLanguage('bn', 'BD'),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isBangla ? AppColors.primary : themeService.inputFillColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      'lang_bn'.tr,
                      style: getTextStyle(
                        fontSize: 13.sp,
                        fontWeight: isBangla ? FontWeight.w700 : FontWeight.w500,
                        color: isBangla ? Colors.white : themeService.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // --- 4. Owner & Manager Governance Hub ---
  Widget _buildOwnerGovernanceMenu(BuildContext context, PermissionService perm, ThemeLanguageService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.gavel_rounded,
            title: 'Policy & Price Floor Controls',
            subtitle: 'Minimum price %, max sales limits, exchange floor',
            iconColor: AppColors.primary,
            themeService: themeService,
            onTap: () => context.push(AppRoute.policyControlScreen),
          ),
          Divider(height: 1, color: themeService.inputBorderColor),
          _buildMenuItem(
            icon: Icons.local_offer_rounded,
            title: 'Discount Rules & Approvals',
            subtitle: 'Manager requests & Owner approval workflow',
            iconColor: const Color(0xFF8B5CF6),
            themeService: themeService,
            onTap: () => context.push(AppRoute.discountManagementScreen),
          ),
          Divider(height: 1, color: themeService.inputBorderColor),
          _buildMenuItem(
            icon: Icons.local_shipping_rounded,
            title: 'Supplier & Vendor Directory',
            subtitle: 'Manage supplier contacts and order histories',
            iconColor: AppColors.secondary,
            themeService: themeService,
            onTap: () => context.push(AppRoute.supplierManagementScreen),
          ),
          if (perm.isOwner) ...[
            Divider(height: 1, color: themeService.inputBorderColor),
            _buildMenuItem(
              icon: Icons.pie_chart_rounded,
              title: 'Investor Management',
              subtitle: 'Cap table, equity, profit distributions',
              iconColor: const Color(0xFFF59E0B),
              themeService: themeService,
              onTap: () => context.push(AppRoute.investorManagementScreen),
            ),
            Divider(height: 1, color: themeService.inputBorderColor),
            _buildMenuItem(
              icon: Icons.account_balance_rounded,
              title: 'Borrowed Loans (Liabilities)',
              subtitle: 'Principal repayment & interest expense',
              iconColor: const Color(0xFFEF4444),
              themeService: themeService,
              onTap: () => context.push(AppRoute.loanManagementScreen),
            ),
            Divider(height: 1, color: themeService.inputBorderColor),
            _buildMenuItem(
              icon: Icons.handshake_rounded,
              title: 'Money Lent (Receivables)',
              subtitle: 'Debtor tracking & interest earnings',
              iconColor: const Color(0xFF10B981),
              themeService: themeService,
              onTap: () => context.push(AppRoute.moneyLentScreen),
            ),
          ],
        ],
      ),
    );
  }

  // --- 5. Admin Menu (RBAC, Backup, Activity Logs) ---
  Widget _buildAdminMenu(
    BuildContext context,
    SettingsController controller,
    PermissionService perm,
    ThemeLanguageService themeService,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          if (perm.isOwner) ...[
            _buildMenuItem(
              icon: Icons.manage_accounts_rounded,
              title: 'user_management'.tr,
              subtitle: 'Manage roles and approve new devices',
              iconColor: AppColors.primary,
              themeService: themeService,
              onTap: () => context.push(AppRoute.userManagementScreen),
            ),
            Divider(height: 1, color: themeService.inputBorderColor),
          ],
          _buildMenuItem(
            icon: Icons.cloud_download_rounded,
            title: 'cloud_backup_restore'.tr,
            subtitle: 'Export JSON data & full state restore',
            iconColor: AppColors.secondary,
            themeService: themeService,
            onTap: () => context.push(AppRoute.backupSyncScreen),
          ),
          Divider(height: 1, color: themeService.inputBorderColor),
          _buildMenuItem(
            icon: Icons.history_edu_rounded,
            title: 'activity_logs'.tr,
            subtitle: 'Complete chronological 6-month audit trail',
            iconColor: AppColors.warning,
            themeService: themeService,
            onTap: () => context.push(AppRoute.activityLogsScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required ThemeLanguageService themeService,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: iconColor, size: 22.w),
      ),
      title: Text(
        title,
        style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeService.textColor),
      ),
      subtitle: Text(
        subtitle,
        style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: themeService.subtextColor, size: 20.w),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeLanguageService themeService) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: AppColors.primary),
        8.horizontalSpace,
        Text(
          title,
          style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
        ),
      ],
    );
  }
}
