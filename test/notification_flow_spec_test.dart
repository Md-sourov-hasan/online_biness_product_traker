import 'package:flutter_test/flutter_test.dart';
import 'package:online_buiness_product_traker/core/models/user_model.dart';
import 'package:online_buiness_product_traker/features/notifications/models/notification_item.dart';
import 'package:online_buiness_product_traker/features/notifications/models/notification_settings_model.dart';
import 'package:online_buiness_product_traker/features/notifications/controllers/notifications_controller.dart';

void main() {
  group('StockMate Notification Flow Specification Tests', () {
    final ownerUser = AppUser(
      id: 'owner_1',
      name: 'Store Owner',
      email: 'owner@stockmate.com',
      role: 'Super Admin (Owner)',
      approvalStatus: 'approved',
    );

    final managerUser = AppUser(
      id: 'manager_1',
      name: 'Store Manager',
      email: 'manager@stockmate.com',
      role: 'Store Manager',
      approvalStatus: 'approved',
    );

    final staffUser1 = AppUser(
      id: 'staff_1',
      name: 'Tanvir (Staff)',
      email: 'tanvir@stockmate.com',
      role: 'Staff',
      approvalStatus: 'approved',
    );

    final staffUser2 = AppUser(
      id: 'staff_2',
      name: 'Rahim (Staff)',
      email: 'rahim@stockmate.com',
      role: 'Staff',
      approvalStatus: 'approved',
    );

    test('Staff recipient isolation: Staff only receives STF-* codes targeted to them', () {
      final defaultSettings = NotificationSettingsModel();

      // SAL-01: Sale completed
      final saleNotif = AppNotificationItem(
        id: '1',
        code: 'SAL-01',
        title: 'New Sale',
        message: 'Sale completed',
        timestamp: DateTime.now(),
        type: NotificationType.sale,
        recipientRole: 'Owner',
        actorUserId: 'staff_1',
        actorRole: 'Staff',
      );

      // Staff member should NOT receive SAL-01 (even if they were the actor, self action without confirmation)
      expect(
        NotificationsController.isNotificationForUser(
          item: saleNotif,
          user: staffUser1,
          currentSettings: defaultSettings,
        ),
        false,
      );

      // STF-01: Self confirmation for staff_1
      final staffConfirm = AppNotificationItem(
        id: '2',
        code: 'STF-01',
        title: 'Sale Saved',
        message: 'Your sale was saved',
        timestamp: DateTime.now(),
        type: NotificationType.sale,
        recipientRole: 'Staff',
        recipientUserId: 'staff_1',
        actorUserId: 'staff_1',
        isSelfConfirmation: true,
      );

      // staff_1 SHOULD receive their own confirmation
      expect(
        NotificationsController.isNotificationForUser(
          item: staffConfirm,
          user: staffUser1,
          currentSettings: defaultSettings,
        ),
        true,
      );

      // staff_2 should NOT receive staff_1's confirmation
      expect(
        NotificationsController.isNotificationForUser(
          item: staffConfirm,
          user: staffUser2,
          currentSettings: defaultSettings,
        ),
        false,
      );
    });

    test('Staff confidentiality guard: Staff NEVER receives loans, investors, or owner actions', () {
      final defaultSettings = NotificationSettingsModel();

      final loanNotif = AppNotificationItem(
        id: '3',
        code: 'MNY-01',
        title: 'Loan Recorded',
        message: 'Borrowed ৳50,000',
        timestamp: DateTime.now(),
        type: NotificationType.moneyLent,
        recipientRole: 'Owner',
      );

      final investorNotif = AppNotificationItem(
        id: '4',
        code: 'MNY-04',
        title: 'Investor Added',
        message: 'Added capital ৳100,000',
        timestamp: DateTime.now(),
        type: NotificationType.investor,
        recipientRole: 'Owner',
      );

      expect(
        NotificationsController.isNotificationForUser(
          item: loanNotif,
          user: staffUser1,
          currentSettings: defaultSettings,
        ),
        false,
      );

      expect(
        NotificationsController.isNotificationForUser(
          item: investorNotif,
          user: staffUser1,
          currentSettings: defaultSettings,
        ),
        false,
      );
    });

    test('Manager recipient rules: Receives stock alerts and staff actions, NEVER loans/investors/user approvals', () {
      final managerSettings = NotificationSettingsModel();

      // DSC-02: Discount result to manager_1 is ALWAYS allowed
      final dsc02 = AppNotificationItem(
        id: '5',
        code: 'DSC-02',
        title: 'Discount Approved',
        message: 'Discount 10% was APPROVED',
        timestamp: DateTime.now(),
        type: NotificationType.discount,
        recipientRole: 'Manager',
        recipientUserId: 'manager_1',
      );
      expect(
        NotificationsController.isNotificationForUser(
          item: dsc02,
          user: managerUser,
          currentSettings: managerSettings,
        ),
        true,
      );

      // Stock alerts STK-01 / STK-02
      final stk01 = AppNotificationItem(
        id: '6',
        code: 'STK-01',
        title: 'Out of Stock',
        message: 'Product out of stock',
        timestamp: DateTime.now(),
        type: NotificationType.lowStock,
        recipientRole: 'Owner',
      );
      expect(
        NotificationsController.isNotificationForUser(
          item: stk01,
          user: managerUser,
          currentSettings: managerSettings,
        ),
        true,
      );

      // Turn off stock alerts for Manager
      managerSettings.stockAlerts = false;
      expect(
        NotificationsController.isNotificationForUser(
          item: stk01,
          user: managerUser,
          currentSettings: managerSettings,
        ),
        false,
      );

      // Loans / Investors / Approvals are NEVER allowed for Manager
      final mny01 = AppNotificationItem(
        id: '7',
        code: 'MNY-01',
        title: 'Loan',
        message: 'Loan entry',
        timestamp: DateTime.now(),
        type: NotificationType.moneyLent,
        recipientRole: 'Owner',
      );
      final usr01 = AppNotificationItem(
        id: '8',
        code: 'USR-01',
        title: 'User Pending',
        message: 'User pending approval',
        timestamp: DateTime.now(),
        type: NotificationType.pendingApproval,
        recipientRole: 'Owner',
      );
      expect(
        NotificationsController.isNotificationForUser(
          item: mny01,
          user: managerUser,
          currentSettings: managerSettings,
        ),
        false,
      );
      expect(
        NotificationsController.isNotificationForUser(
          item: usr01,
          user: managerUser,
          currentSettings: managerSettings,
        ),
        false,
      );
    });

    test('Owner recipient rules: Category toggles, actor filter, and pending approvals unmuted', () {
      final ownerSettings = NotificationSettingsModel();

      // Owner receives SAL-01, MNY-01, EXP-01 by default
      final sal01 = AppNotificationItem(
        id: '9',
        code: 'SAL-01',
        title: 'Sale',
        message: 'Sale done',
        timestamp: DateTime.now(),
        type: NotificationType.sale,
        actorRole: 'Staff',
      );
      expect(
        NotificationsController.isNotificationForUser(
          item: sal01,
          user: ownerUser,
          currentSettings: ownerSettings,
        ),
        true,
      );

      // Actor filter: manager_only suppresses Staff actions
      ownerSettings.recipientFilter = 'manager_only';
      expect(
        NotificationsController.isNotificationForUser(
          item: sal01,
          user: ownerUser,
          currentSettings: ownerSettings,
        ),
        false,
      );
      ownerSettings.recipientFilter = 'everyone';

      // Category toggle: turn off salesAndReturns
      ownerSettings.salesAndReturns = false;
      expect(
        NotificationsController.isNotificationForUser(
          item: sal01,
          user: ownerUser,
          currentSettings: ownerSettings,
        ),
        false,
      );
      ownerSettings.salesAndReturns = true;

      // Master switch turned off: pending approvals (USR-01) MUST NOT be hidden
      ownerSettings.masterSwitch = false;
      final usr01 = AppNotificationItem(
        id: '10',
        code: 'USR-01',
        title: 'User Pending',
        message: 'New user registered',
        timestamp: DateTime.now(),
        type: NotificationType.pendingApproval,
        recipientRole: 'Owner',
      );
      expect(
        NotificationsController.isNotificationForUser(
          item: usr01,
          user: ownerUser,
          currentSettings: ownerSettings,
        ),
        true, // Pending approval remains visible per spec
      );
    });
  });
}
