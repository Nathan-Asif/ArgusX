import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/grid_background.dart';
import '../widgets/tech_panel.dart';
import '../widgets/tech_input.dart';
import '../widgets/tech_button.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final ArgusXAuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!widget.authService.isConfigured) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const DashboardScreen(riderId: 'demo-rider'),
            ),
          );
        }
        return;
      }
      if (_isRegister) {
        await widget.authService.signUp(email: email, password: password);
      } else {
        await widget.authService.signIn(email: email, password: password);
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(riderId: widget.authService.riderId),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    // 1. Logo Section
                    Container(
                      height: 110.0,
                      width: 110.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF131314),
                        // 0px border-radius — sharp corners per design.md §Shapes
                        border: Border.all(
                          color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8E2DE2).withValues(alpha: 0.2),
                            blurRadius: 20.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // 2. Titles Section
                    Text(
                      'ARGUSX',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFE5E2E3),
                        fontSize: 44.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.0,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF8E2DE2).withValues(alpha: 0.5),
                            blurRadius: 15.0,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'SECURE GATEWAY v.4.0',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF998CA0),
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 36.0),

                    // 3. Authentication Panel
                    TechPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                      borderColor: const Color(0xFF353436),
                      bracketColor: const Color(0xFF8E2DE2).withValues(alpha: 0.6),
                      bracketLength: 14.0,
                      bracketThickness: 2.0,
                      backgroundColor: const Color(0xEB0E0E0F), // deeper obsidian black
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'AUTHENTICATION PROTOCOL',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFFDDB7FF),
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              const _BlinkingStatus(),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          // High-tech partition line
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

                          // Operator ID / Email
                          TechInput(
                            label: 'OPERATOR ID / EMAIL',
                            hintText: 'operator@argusx.io',
                            prefixIcon: Icons.badge_outlined,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 20.0),
                          TechInput(
                            label: 'PASSWORD',
                            hintText: '••••••••••••••••',
                            prefixIcon: Icons.key_outlined,
                            isPassword: true,
                            controller: _passwordController,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: GoogleFonts.inter(color: const Color(0xFFFF5252), fontSize: 11),
                            ),
                          ],
                          const SizedBox(height: 32.0),
                          TechButton(
                            label: _busy
                                ? 'SYNCING...'
                                : (_isRegister ? 'CREATE ACCOUNT' : 'SIGN IN'),
                            icon: Icons.sync_lock_outlined,
                            onTap: _busy ? () {} : _submit,
                          ),
                          const SizedBox(height: 24.0),
                          Center(
                            child: _HoverText(
                              text: _isRegister
                                  ? 'ALREADY HAVE ACCESS? SIGN IN'
                                  : 'NEW OPERATOR? CREATE ACCOUNT',
                              onTap: () => setState(() => _isRegister = !_isRegister),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // 4. Secure Connection Footer
                    // Vertically leading tech line
                    Container(
                      height: 40.0,
                      width: 1.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4D4354).withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.security_outlined,
                          color: Color(0xFF4D4354),
                          size: 14.0,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'SECURE CONNECTION',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF4D4354),
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
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

// Blinking square status indicator
class _BlinkingStatus extends StatefulWidget {
  const _BlinkingStatus();

  @override
  State<_BlinkingStatus> createState() => _BlinkingStatusState();
}

class _BlinkingStatusState extends State<_BlinkingStatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.15, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 8.0,
            width: 8.0,
            color: const Color(0xFFDDB7FF),
          ),
          const SizedBox(width: 6.0),
          Text(
            'AWAITING INPUT',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF998CA0),
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// Hoverable Text Link
class _HoverText extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _HoverText({required this.text, required this.onTap});

  @override
  State<_HoverText> createState() => _HoverTextState();
}

class _HoverTextState extends State<_HoverText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: GoogleFonts.spaceGrotesk(
            color: _isHovered ? const Color(0xFFDDB7FF) : const Color(0xFF4D4354),
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
