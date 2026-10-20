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
  final double? fixedHeight;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    this.label = '',
    required this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.fixedHeight,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = AppColors.textPrimary;
    Color subtextColor = AppColors.textSecondary;
    Color fillColor = const Color(0xFFEEEFF3); // Clean Nestora-style gray fill

    try {
      if (Get.isRegistered<ThemeLanguageService>()) {
        final ts = Get.find<ThemeLanguageService>();
        textColor = ts.textColor;
        subtextColor = ts.subtextColor;
        fillColor = ts.isDark ? const Color(0xFF222634) : const Color(0xFFEEEFF3);
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        Container(
          height: fixedHeight,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: fixedHeight != null
              ? Center(child: _buildTextFormField(textColor, subtextColor))
              : _buildTextFormField(textColor, subtextColor),
        ),
      ],
    );
  }

  Widget _buildTextFormField(Color textColor, Color subtextColor) {
    return TextFormField(
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
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: fixedHeight != null,
        hintText: hintText.isNotEmpty ? hintText : null,
        hintStyle: getTextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: subtextColor,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
