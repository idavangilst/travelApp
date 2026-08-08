import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../theme/theme.dart';

void main() {
  runApp(const EvaraApp());
}

class EvaraApp extends StatelessWidget {
  const EvaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Evara',
      theme: AppTheme.defaultTheme,
      home: const HomeScreen(),
    );
  }
}
