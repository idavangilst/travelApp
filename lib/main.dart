import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../screens/home_screen.dart';
import '../theme/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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