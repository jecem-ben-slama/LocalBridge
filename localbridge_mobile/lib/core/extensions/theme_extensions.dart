import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/app_color_extension.dart';

extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  AppColorsExtension get appColors => const AppColorsExtension();
}
