import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGray = Color(0xFF4F4F4F);
  static const Color secondaryGray = Color(0xFF7D7D7D);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color indicatorGray = Color(0xFFD9D9D9);
  static const Color accentBlue = Colors.blue;

  static const TextStyle regularText = TextStyle(
    color: primaryGray,
    fontSize: 18,
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    letterSpacing: -0.09,
  );

  static const TextStyle headerText = TextStyle(
    color: primaryGray,
    fontSize: 20,
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    letterSpacing: -0.10,
  );
}
