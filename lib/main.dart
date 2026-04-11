import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Placeholder configuration)
  // Note: You will need to run 'flutterfire configure' to generate actual firebase_options.dart
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed or not configured. Running offline.");
  }

  runApp(const DisciplineApp());
}

class DisciplineApp extends StatelessWidget {
  const DisciplineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discipline',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.minimalistTheme,
      home: const MainLayout(),
    );
  }
}