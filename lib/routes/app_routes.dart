import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash_screen/screen/splash_screen.dart';
import '../features/bottom_navigation/screens/bottom_navigation_screen.dart';
import '../features/products/screens/add_edit_product_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/user_management_screen.dart';
import '../features/settings/screens/backup_restore_screen.dart';
import '../features/settings/screens/activity_logs_screen.dart';
import '../core/models/product_model.dart';

class AppRoute {
  // ---------------------------------------------------------------------------
  // Route Constants
  // ---------------------------------------------------------------------------
  static const String splashScreen = "/";
  static const String bottomNavigationScreen = "/home";
  static const String addEditProductScreen = "/add-edit-product";
  static const String settingsScreen = "/settings";
  static const String userManagementScreen = "/user-management";
  static const String backupSyncScreen = "/backup-sync";
  static const String activityLogsScreen = "/activity-logs";

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
