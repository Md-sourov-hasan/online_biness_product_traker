import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../styles/global_text_style.dart';
import '../../services/theme_language_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/sizer.dart';

class CustomFilledButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;

  const CustomFilledButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color btnColor = color ?? AppColors.primary;
    try {
      if (color == null && Get.isRegistered<ThemeLanguageService>()) {
        btnColor = Get.find<ThemeLanguageService>().accentColor;
      }
    } catch (_) {}

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  text,
                  style: getTextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor ?? AppColors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
