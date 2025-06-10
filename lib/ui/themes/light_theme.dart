import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LightTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.main100,
      onPrimary: AppColors.white100,
      secondary: AppColors.gray100,
      surface: Colors.white,
      onSurface: AppColors.black100,
      error: Colors.red,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.main100,
      foregroundColor: AppColors.black100,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.black100,
      unselectedLabelColor: AppColors.white80,
      indicatorColor: AppColors.white100,
    ),
  );
}
