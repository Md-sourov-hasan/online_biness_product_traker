import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:online_buiness_product_traker/main.dart';
import 'package:online_buiness_product_traker/core/services/theme_language_service.dart';
import 'package:online_buiness_product_traker/core/services/database_service.dart';
import 'package:online_buiness_product_traker/core/services/auth_service.dart';
import 'package:online_buiness_product_traker/core/services/notification_service.dart';
import 'package:online_buiness_product_traker/core/services/report_export_service.dart';
import 'package:online_buiness_product_traker/core/services/backup_service.dart';
import 'package:online_buiness_product_traker/core/utils/connectivity_service.dart';
import 'package:online_buiness_product_traker/features/dashboard/controllers/dashboard_controller.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    Get.testMode = true;
    Get.put(ConnectivityService());
    Get.put(NotificationService());
    final db = DatabaseService();
    Get.put(db);
    final themeService = ThemeLanguageService();
    Get.put(themeService);
    Get.put(AuthService());
    Get.put(ReportExportService());
    Get.put(BackupService());

    await tester.pumpWidget(MyApp(themeService: themeService));
    expect(find.byType(MyApp), findsOneWidget);

    // Advance past splash timer
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 500));

    // Cancel periodic dashboard timer before exiting test
    if (Get.isRegistered<DashboardController>()) {
      Get.delete<DashboardController>(force: true);
    }
  });
}
