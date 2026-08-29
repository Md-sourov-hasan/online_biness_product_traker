import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';

class SplashScreenController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    // Usually we would use go_router's context to navigate.
    // However, since we are in a GetX controller without context, 
    // we use a global router key or pass context from the UI.
    // For now, we will expose a method to be called from the UI.
  }
}
