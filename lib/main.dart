import 'package:flutter/material.dart';
import './pages/splash_screen.dart'; // Ensure you have this file in your project.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetWise',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(toolbarHeight: 50.0),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0x00ccecd4)),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
