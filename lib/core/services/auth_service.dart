import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import '../../routes/app_routes.dart';
import '../../features/notifications/models/notification_item.dart';
import '../../features/notifications/controllers/notifications_controller.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find<AuthService>();

  final Rx<AppUser?> currentUser = Rx<AppUser?>(null);
  final RxBool isLoggedIn = true.obs; // Demo default active
  final RxBool isLoading = false.obs;

  SharedPreferences? _prefs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final userEmail = _prefs?.getString('sm_auth_email');
      if (userEmail != null && userEmail.isNotEmpty) {
        final db = Get.find<DatabaseService>();
        final matched = db.users.firstWhereOrNull((u) => u.email == userEmail);
        if (matched != null) {
          currentUser.value = matched;
          isLoggedIn.value = true;
          return;
        }
      }
      // Default to Super Admin demo profile
      currentUser.value = AppUser(
        id: 'owner_1',
        name: 'Sourov Hasan (Owner)',
        email: 'owner@stockmate.com',
        role: 'Super Admin (Owner)',
        approvalStatus: 'approved',
        deviceName: 'Primary Terminal',
      );
      isLoggedIn.value = true;
    } catch (e) {
      debugPrint('Auth init error: $e');
    }
  }

  bool get isSuperAdmin => currentUser.value?.isOwner ?? true;
  bool get isManager => currentUser.value?.isManager ?? false;
  bool get isStaff => currentUser.value?.isStaff ?? false;
  bool get isApproved => currentUser.value?.isApproved ?? true;

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    final db = Get.find<DatabaseService>();
    final user = db.users.firstWhereOrNull((u) => u.email.toLowerCase() == email.trim().toLowerCase());

    if (user != null) {
      currentUser.value = user;
      isLoggedIn.value = true;
      await _prefs?.setString('sm_auth_email', user.email);
      isLoading.value = false;
      return true;
    } else {
      // Create new user demo
      final newUser = AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: email.split('@').first,
        email: email.trim(),
        role: 'Staff',
        approvalStatus: 'pending',
      );
      db.users.add(newUser);
      db.saveToLocal();

      try {
        if (Get.isRegistered<NotificationsController>()) {
          Get.find<NotificationsController>().dispatchNotification(
            AppNotificationItem(
              id: const Uuid().v4(),
              code: 'USR-01',
              title: 'New User Registration 👤',
              message: '${newUser.name} registered and is pending Owner approval.',
              timestamp: DateTime.now(),
              type: NotificationType.pendingApproval,
              priority: NotificationPriority.high,
              recipientRole: 'Owner',
              route: AppRoute.userManagementScreen,
            ),
          );
        }
      } catch (_) {}

      currentUser.value = newUser;
      isLoggedIn.value = true;
      await _prefs?.setString('sm_auth_email', newUser.email);
      isLoading.value = false;
      return true;
    }
  }

  Future<void> loginAsRole(String roleName, {String? customName, String? customEmail}) async {
    isLoading.value = true;
    final db = Get.find<DatabaseService>();

    String userId;
    String name;
    String email;

    if (roleName.contains('Owner') || roleName.contains('Super Admin')) {
      userId = 'owner_1';
      name = customName ?? 'Sourov Hasan (Owner)';
      email = customEmail ?? 'owner@stockmate.com';
    } else if (roleName.contains('Manager')) {
      userId = 'manager_1';
      name = customName ?? 'Store Manager';
      email = customEmail ?? 'manager@stockmate.com';
    } else {
      userId = 'staff_1';
      name = customName ?? 'Sales Associate (Staff)';
      email = customEmail ?? 'staff@stockmate.com';
    }

    final user = AppUser(
      id: userId,
      name: name,
      email: email,
      role: roleName,
      approvalStatus: 'approved',
      deviceName: 'Active Terminal',
      createdAt: DateTime.now(),
    );

    currentUser.value = user;
    isLoggedIn.value = true;
    await _prefs?.setString('sm_auth_email', email);

    db.logActivity('auth', 'Session Login ($roleName)', '$name signed in with active $roleName role privileges.');

    isLoading.value = false;
  }

  void switchUserRole(String role) {
    if (currentUser.value != null) {
      final updated = currentUser.value!.copyWith(role: role, approvalStatus: 'approved');
      currentUser.value = updated;
      Get.snackbar('Role Switched', 'Current role set to: $role', snackPosition: SnackPosition.BOTTOM);
    } else {
      loginAsRole(role);
    }
  }

  Future<void> logout() async {
    await _prefs?.remove('sm_auth_email');
    currentUser.value = null;
    isLoggedIn.value = false;
  }
}
