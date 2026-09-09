import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }

  const AppTheme._();
}
