import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../theme/theme.dart';

void main() {
  runApp(const WanderApp());
}

class WanderApp extends StatelessWidget {
  const WanderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wander',
      theme: AppTheme.defaultTheme,
      home: const HomeScreen(),
    );
  }
}
