import 'package:flutter/material.dart';

class Sizer {
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _blockSizeHorizontal;
  static late double _blockSizeVertical;
  // Design dimensions (based on a standard mobile screen like iPhone 14)
  static const double designWidth = 390;
  static const double designHeight = 844;

  static void init(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    _screenWidth = size.width;
    _screenHeight = size.height;
    // Keep responsive scaling optimal for mobile while protecting against oversized screen blowouts
    _blockSizeHorizontal = (_screenWidth / designWidth).clamp(0.8, 1.25);
    _blockSizeVertical = (_screenHeight / designHeight).clamp(0.8, 1.25);
  }

  // Responsive width
  static double w(double width) {
    return width * _blockSizeHorizontal;
  }

  // Responsive height
  static double h(double height) {
    return height * _blockSizeVertical;
  }

  // Responsive font size
  static double sp(double fontSize) {
    return fontSize * _blockSizeHorizontal;
  }

  // Responsive radius
  static double r(double radius) {
    return radius * _blockSizeHorizontal;
  }

  // Screen width
  static double get screenWidth => _screenWidth;

  // Screen height
  static double get screenHeight => _screenHeight;

  // Vertical spacing
  static Widget verticalSpace(double height) {
    return SizedBox(height: h(height));
  }

  // Horizontal spacing
  static Widget horizontalSpace(double width) {
    return SizedBox(width: w(width));
  }
}

// Extension methods for easier usage
extension SizerExt on num {
  double get w => Sizer.w(toDouble());
  double get h => Sizer.h(toDouble());
  double get sp => Sizer.sp(toDouble());
  double get r => Sizer.r(toDouble());
  
  Widget get verticalSpace => Sizer.verticalSpace(toDouble());
  Widget get horizontalSpace => Sizer.horizontalSpace(toDouble());
}
