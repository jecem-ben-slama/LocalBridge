import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkest,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.card,
        error: AppColors.error,
        onPrimary: AppColors.text,
        onSecondary: AppColors.darkest,
        onSurface: AppColors.text,
        onError: AppColors.text,
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.muted),
      ),
    );
  }
}
