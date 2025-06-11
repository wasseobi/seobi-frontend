import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LightTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      primary: AppColors.main100,
      onPrimary: AppColors.white100,
      primaryContainer: AppColors.white100,
      onPrimaryContainer: AppColors.black100,

      secondary: AppColors.main80,
      onSecondary: AppColors.white100,
      secondaryContainer: AppColors.white80,
      onSecondaryContainer: AppColors.black100,

      tertiary: AppColors.white80,
      onTertiary: AppColors.black100,
      tertiaryContainer: AppColors.white80,
      onTertiaryContainer: AppColors.black100,

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

    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.white100,
    ),

    dividerColor: AppColors.main80,

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.green100,
      circularTrackColor: AppColors.gray80,
    ),
  );
}
