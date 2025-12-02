import 'package:flutter/material.dart';
import 'app_colors.dart';

final appTheme = ThemeData(
  scaffoldBackgroundColor: Colors.white,
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.thunderbird400,
  ),
  fontFamily: 'FoundersGrotesk',

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
);
