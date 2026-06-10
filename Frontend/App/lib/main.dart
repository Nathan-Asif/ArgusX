import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'config/argus_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = ArgusXAuthService();
  await auth.initialize();
  runApp(ArgusXApp(authService: auth));
}

class ArgusXApp extends StatelessWidget {
  final ArgusXAuthService authService;

  const ArgusXApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ArgusTheme.accentThemeNotifier,
      builder: (context, accent, child) {
        final activeColor = ArgusTheme.activeColor;
        final glowColor = ArgusTheme.glowColor;
        return MaterialApp(
          title: 'ArgusX',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0B0B0C),
            colorScheme: ColorScheme.dark(
              primary: activeColor,
              secondary: glowColor,
              surface: const Color(0xFF131314),
              onPrimary: const Color(0xFF4A0080),
              onSecondary: Colors.white,
              onSurface: const Color(0xFFE5E2E3),
            ),
            useMaterial3: true,
          ),
          home: LoginScreen(authService: authService),
        );
      },
    );
  }
}
