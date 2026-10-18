import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../styles/global_text_style.dart';
import '../../services/theme_language_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/sizer.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = AppColors.textPrimary;
    Color subtextColor = AppColors.textSecondary;
    Color fillColor = AppColors.inputBackground;
    Color borderColor = AppColors.inputBorder;
    Color accentColor = AppColors.primary;

    try {
      if (Get.isRegistered<ThemeLanguageService>()) {
        final ts = Get.find<ThemeLanguageService>();
        textColor = ts.textColor;
        subtextColor = ts.subtextColor;
        fillColor = ts.inputFillColor;
        borderColor = ts.inputBorderColor;
        accentColor = ts.accentColor;
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: getTextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          8.verticalSpace,
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator,
          style: getTextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: getTextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: subtextColor,
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}
