import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light(Color seedColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark(Color seedColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
