import 'dart:math';

import 'package:screen_corner_radius/screen_corner_radius.dart';

class AppDimensions {
  // Screen Corner Radius
  static ScreenRadius? screenCornerRadius;

  static Future<void> initialize() async {
    screenCornerRadius = await ScreenCornerRadius.get();
  }

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Margins
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;

  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Border Radius
  static final double borderRadiusLarge = max(
    screenCornerRadius?.topLeft ?? 0.0,
    12.0,
  );
  static final double borderRadiusMedium = borderRadiusLarge * 2.0 / 3.0;
  static final double borderRadiusSmall = borderRadiusSmall * 3.0;
}
