import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants/colors.dart';

TextStyle getTextStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.normal,
  Color color = AppColors.textPrimary,
  double? lineHeight,
}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: lineHeight != null ? lineHeight / fontSize : null,
  );
}
