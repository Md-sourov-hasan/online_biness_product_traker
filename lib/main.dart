import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/utils/sizer.dart';
import 'core/utils/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/database_service.dart';
import 'core/services/theme_language_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/permission_service.dart';
import 'core/services/report_export_service.dart';
import 'core/services/backup_service.dart';
import 'core/utils/localization/app_translations.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  Get.put(ConnectivityService());
  Get.put(NotificationService());
  await Get.putAsync(() async => DatabaseService());
  final themeLanguageService = await Get.putAsync(
    () async => ThemeLanguageService(),
  );
  await Get.putAsync(() async => AuthService());
  Get.put(PermissionService());
  Get.put(ReportExportService());
  Get.put(BackupService());

  runApp(MyApp(themeService: themeLanguageService));
}

class MyApp extends StatelessWidget {
  final ThemeLanguageService themeService;

  const MyApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GetMaterialApp.router(
        title: 'StockMate',
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: themeService.currentLocale.value,
        fallbackLocale: const Locale('en', 'US'),
        theme: themeService.themeData,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(),
        ),
        builder: (context, child) {
          Sizer.init(context);
          return child!;
        },
        routeInformationProvider: AppRoute.router.routeInformationProvider,
        routeInformationParser: AppRoute.router.routeInformationParser,
        routerDelegate: AppRoute.router.routerDelegate,
      );
    });
  }
}
