import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppColorsExtension {
  const AppColorsExtension();

  // Backgrounds
  Color get darkest => AppColors.darkest;
  Color get dark => AppColors.dark;
  Color get card => AppColors.card;
  Color get elevated => AppColors.elevated;

  // Borders
  Color get border => AppColors.border;
  Color get borderSoft => AppColors.borderSoft;
  Color get borderStrong => AppColors.borderStrong;

  // Primary — Teal
  Color get primary => AppColors.primary;
  Color get primaryHover => AppColors.primaryHover;
  Color get primaryActive => AppColors.primaryActive;
  Color get primarySoft => AppColors.primarySoft;

  // Secondary Accent — Cyan
  Color get accent => AppColors.accent;
  Color get accentSoft => AppColors.accentSoft;

  // Text
  Color get text => AppColors.text;
  Color get textSecondary => AppColors.textSecondary;
  Color get muted => AppColors.muted;
  Color get mutedDark => AppColors.mutedDark;

  // Semantic
  Color get success => AppColors.success;
  Color get successSoft => AppColors.successSoft;
  Color get warning => AppColors.warning;
  Color get warningSoft => AppColors.warningSoft;
  Color get error => AppColors.error;
  Color get errorSoft => AppColors.errorSoft;
  Color get info => AppColors.info;
  Color get infoSoft => AppColors.infoSoft;
}
