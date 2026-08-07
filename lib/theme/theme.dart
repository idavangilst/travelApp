import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData defaultTheme = ThemeData(
    scaffoldBackgroundColor: DefaultAppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: DefaultAppColors.skyBlue),
    useMaterial3: true,
  );
}
