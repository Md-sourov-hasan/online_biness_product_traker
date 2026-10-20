import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:online_buiness_product_traker/core/utils/constants/app_constants.dart';
import 'package:online_buiness_product_traker/features/auth/controllers/login_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginController Architecture Tests', () {
    late LoginController controller;

    setUp(() {
      Get.reset();
      controller = LoginController();
      controller.onInit();
    });

    tearDown(() {
      controller.onClose();
    });

    test('Initializes with Owner role defaults', () {
      expect(controller.selectedRole.value, AppConstants.roleOwner);
      expect(controller.nameController.text, 'Sourov Hasan');
      expect(controller.emailController.text, 'owner@stockmate.com');
      expect(controller.roleDisplayShort, 'Owner');
      expect(controller.showCustomInput.value, isFalse);
    });

    test('Switches to Store Manager role correctly', () {
      controller.selectRole(AppConstants.roleManager);
      expect(controller.selectedRole.value, AppConstants.roleManager);
      expect(controller.nameController.text, 'Store Manager');
      expect(controller.emailController.text, 'manager@stockmate.com');
      expect(controller.roleDisplayShort, 'Manager');
    });

    test('Switches to Staff role correctly', () {
      controller.selectRole(AppConstants.roleStaff);
      expect(controller.selectedRole.value, AppConstants.roleStaff);
      expect(controller.nameController.text, 'Sales Associate');
      expect(controller.emailController.text, 'staff@stockmate.com');
      expect(controller.roleDisplayShort, 'Staff');
    });

    test('Toggles custom credentials input state', () {
      expect(controller.showCustomInput.value, isFalse);
      controller.toggleCustomInput();
      expect(controller.showCustomInput.value, isTrue);
      controller.toggleCustomInput();
      expect(controller.showCustomInput.value, isFalse);
    });
  });
}
