import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/theme_language_service.dart';

class CommonBackgroundScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const CommonBackgroundScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<ThemeLanguageService>()) {
      return Obx(() {
        final theme = Get.find<ThemeLanguageService>();
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: appBar,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          body: SafeArea(
            child: body,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: body,
      ),
    );
  }
}
