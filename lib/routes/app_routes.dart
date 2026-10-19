import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash_screen/screen/splash_screen.dart';
import '../features/bottom_navigation/screens/bottom_navigation_screen.dart';
import '../features/products/screens/add_edit_product_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/user_management_screen.dart';
import '../features/settings/screens/backup_restore_screen.dart';
import '../features/settings/screens/activity_logs_screen.dart';
import '../features/owner_controls/screens/investor_management_screen.dart';
import '../features/owner_controls/screens/loan_management_screen.dart';
import '../features/owner_controls/screens/money_lent_screen.dart';
import '../features/owner_controls/screens/policy_control_screen.dart';
import '../features/owner_controls/screens/discount_management_screen.dart';
import '../features/owner_controls/screens/supplier_management_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/settings/screens/theme_settings_screen.dart';
import '../features/reports/screens/analytics_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/purchases_expenses/screens/purchases_expenses_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/notifications/screens/notification_settings_screen.dart';
import '../features/branches/screens/branches_screen.dart';
import '../features/branches/screens/branch_inventory_screen.dart';
import '../features/branches/screens/branch_management_screen.dart';
import '../core/models/product_model.dart';
import '../core/models/branch_model.dart';

class AppRoute {
  // ---------------------------------------------------------------------------
  // Route Constants
  // ---------------------------------------------------------------------------
  static const String splashScreen = "/";
  static const String loginScreen = "/login";
  static const String bottomNavigationScreen = "/home";
  static const String addEditProductScreen = "/add-edit-product";
  static const String settingsScreen = "/settings";
  static const String userManagementScreen = "/user-management";
  static const String backupSyncScreen = "/backup-sync";
  static const String activityLogsScreen = "/activity-logs";
  static const String themeScreen = "/theme";
  static const String analyticsScreen = "/analytics";
  static const String reportsScreen = "/reports";
  static const String purchasesExpensesScreen = "/purchases-expenses";
  static const String notificationsScreen = "/notifications";
  static const String notificationSettingsScreen = "/notification-settings";
  static const String branchesScreen = "/branches";
  static const String branchInventoryScreen = "/branch-inventory";
  static const String branchManagementScreen = "/branch-management";

  // Owner & Governance Routes
  static const String investorManagementScreen = "/investors";
  static const String loanManagementScreen = "/loans";
  static const String moneyLentScreen = "/money-lent";
  static const String policyControlScreen = "/policies";
  static const String discountManagementScreen = "/discounts";
  static const String supplierManagementScreen = "/suppliers";

  // ---------------------------------------------------------------------------
  // Router Configuration
  // ---------------------------------------------------------------------------
  static final GoRouter router = GoRouter(
    initialLocation: splashScreen,
    routes: [
      GoRoute(
        path: splashScreen,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: loginScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: bottomNavigationScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const BottomNavigationScreen(),
        ),
      ),
      GoRoute(
        path: addEditProductScreen,
        pageBuilder: (context, state) {
          final product = state.extra as Product?;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: AddEditProductScreen(product: product),
            slideUp: true,
          );
        },
      ),
      GoRoute(
        path: settingsScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: userManagementScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const UserManagementScreen(),
        ),
      ),
      GoRoute(
        path: backupSyncScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const BackupRestoreScreen(),
        ),
      ),
      GoRoute(
        path: activityLogsScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const ActivityLogsScreen(),
        ),
      ),
      GoRoute(
        path: investorManagementScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const InvestorManagementScreen(),
        ),
      ),
      GoRoute(
        path: loanManagementScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const LoanManagementScreen(),
        ),
      ),
      GoRoute(
        path: moneyLentScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const MoneyLentScreen(),
        ),
      ),
      GoRoute(
        path: policyControlScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const PolicyControlScreen(),
        ),
      ),
      GoRoute(
        path: discountManagementScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const DiscountManagementScreen(),
        ),
      ),
      GoRoute(
        path: supplierManagementScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const SupplierManagementScreen(),
        ),
      ),
      GoRoute(
        path: themeScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const ThemeSettingsScreen(),
        ),
      ),
      GoRoute(
        path: analyticsScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const AnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: reportsScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const ReportsScreen(),
        ),
      ),
      GoRoute(
        path: purchasesExpensesScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const PurchasesExpensesScreen(),
        ),
      ),
      GoRoute(
        path: notificationsScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: notificationSettingsScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: branchesScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const BranchesScreen(),
        ),
      ),
      GoRoute(
        path: branchInventoryScreen,
        pageBuilder: (context, state) {
          final branch = state.extra as Branch;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: BranchInventoryScreen(branch: branch),
          );
        },
      ),
      GoRoute(
        path: branchManagementScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const BranchManagementScreen(),
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Custom Transitions (Slide & Fade)
  // ---------------------------------------------------------------------------
  static CustomTransitionPage<void> _buildPageWithTransition({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    bool slideUp = false,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = slideUp ? const Offset(0.0, 1.0) : const Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        final tween = Tween<Offset>(begin: begin, end: end).chain(CurveTween(curve: curve));
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }
}
