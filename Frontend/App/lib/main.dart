import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ArgusXApp());
}

class ArgusXApp extends StatelessWidget {
  const ArgusXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArgusX Secure Gateway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFDDB7FF),
          secondary: Color(0xFF8E2DE2),
          surface: Color(0xFF131314),
          onPrimary: Color(0xFF4A0080),
          onSecondary: Colors.white,
          onSurface: Color(0xFFE5E2E3),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
