import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/argus_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/grid_background.dart';
import '../widgets/tech_panel.dart';
import '../widgets/tech_input.dart';
import '../widgets/tech_button.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  final ArgusXAuthService authService;
  const SignupScreen({super.key, required this.authService});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _handleController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _handleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _error = null; });

    final handle = _handleController.text.trim();
    final email  = _emailController.text.trim();
    final pass   = _passwordController.text;
    final confirm = _confirmController.text;

    if (handle.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'ALL FIELDS REQUIRED');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'PASSWORDS DO NOT MATCH');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'PASSWORD MIN 8 CHARACTERS');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authService.signUp(
        email: email,
        password: pass,
        fullName: handle,
      );
      // Upsert operator handle into profiles table
      if (widget.authService.isConfigured) {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          await Supabase.instance.client
              .from('profiles')
              .upsert({'id': uid, 'handle': handle, 'role': 'customer'});
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => DashboardScreen(riderId: handle),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final glowColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Text(
                      'ARGUSX',
                      style: ArgusFonts.display(
                        color: const Color(0xFFE5E2E3),
                        fontSize: 36.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.0,
                        shadows: [
                          Shadow(
                            color: glowColor.withValues(alpha: 0.5),
                            blurRadius: 15.0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'OPERATOR REGISTRATION',
                      style: ArgusFonts.body(
                        color: const Color(0xFF998CA0),
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 36.0),

                    // Form panel
                    TechPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                      borderColor: const Color(0xFF353436),
                      bracketColor: glowColor.withValues(alpha: 0.6),
                      bracketLength: 14.0,
                      bracketThickness: 2.0,
                      backgroundColor: const Color(0xEB0E0E0F),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'NEW OPERATOR PROFILE',
                                style: ArgusFonts.display(
                                  color: activeColor,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Container(width: 8, height: 8, color: activeColor),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Container(
                            height: 1.0,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4D4354).withValues(alpha: 0.5),
                                  const Color(0xFF4D4354).withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28.0),

                          // Rider Handle
                          TechInput(
                            label: 'RIDER HANDLE',
                            hintText: 'CHOOSE OPERATOR DESIGNATION...',
                            prefixIcon: Icons.badge_outlined,
                            controller: _handleController,
                          ),
                          const SizedBox(height: 20.0),

                          // Email
                          TechInput(
                            label: 'OPERATOR EMAIL',
                            hintText: 'ENTER EMAIL ADDRESS...',
                            prefixIcon: Icons.alternate_email_outlined,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 20.0),

                          // Password
                          TechInput(
                            label: 'ACCESS KEY',
                            hintText: '••••••••••••••••',
                            prefixIcon: Icons.key_outlined,
                            isPassword: true,
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 20.0),

                          // Confirm Password
                          TechInput(
                            label: 'CONFIRM ACCESS KEY',
                            hintText: '••••••••••••••••',
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            controller: _confirmController,
                          ),

                          // Error message
                          if (_error != null) ...[
                            const SizedBox(height: 16.0),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.5)),
                                color: const Color(0xFFFF5252).withValues(alpha: 0.08),
                              ),
                              child: Text(
                                _error!,
                                style: ArgusFonts.body(
                                  color: const Color(0xFFFF5252),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32.0),

                          TechButton(
                            label: _isLoading ? 'INITIALIZING PROFILE...' : 'REGISTER OPERATOR',
                            icon: _isLoading ? Icons.hourglass_top_outlined : Icons.person_add_outlined,
                            onTap: _isLoading ? () {} : _register,
                          ),
                          const SizedBox(height: 24.0),

                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text(
                                'RETURN TO LOGIN TERMINAL',
                                style: ArgusFonts.body(
                                  color: const Color(0xFF4D4354),
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
