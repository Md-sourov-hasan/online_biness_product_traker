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
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    try {
      if (Get.isRegistered<ThemeLanguageService>()) {
        bgColor = Get.find<ThemeLanguageService>().backgroundColor;
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: bgColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: body,
      ),
    );
  }
}
