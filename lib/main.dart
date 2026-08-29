import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/utils/sizer.dart';
import 'core/utils/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'routes/app_routes.dart';
import 'core/utils/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize connectivity service
  Get.put(ConnectivityService());
  // Initialize notification service
  Get.put(NotificationService());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'TrackIt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundNeutral,
      ),
      builder: (context, child) {
        Sizer.init(context);
        return child!;
      },
      routeInformationProvider: AppRoute.router.routeInformationProvider,
      routeInformationParser: AppRoute.router.routeInformationParser,
      routerDelegate: AppRoute.router.routerDelegate,
    );
  }
}
