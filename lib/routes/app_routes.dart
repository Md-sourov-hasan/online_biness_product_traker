import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash_screen/screen/splash_screen.dart';
import '../features/bottom_navigation/screens/bottom_navigation_screen.dart';
import '../features/products/screens/add_edit_product_screen.dart';
import '../features/orders/screens/add_order_screen.dart';
import '../core/models/product_model.dart';

class AppRoute {
  static const String splashScreen = "/";
  static const String bottomNavigationScreen = "/home";
  static const String addEditProductScreen = "/add-edit-product";
  static const String addOrderScreen = "/add-order";

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
          );
        },
      ),
      GoRoute(
        path: addOrderScreen,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const AddOrderScreen(),
        ),
      ),
    ],
  );

  static CustomTransitionPage _buildPageWithTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    bool slideUp = false,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (slideUp) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        }
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }
}
