import 'package:flutter/material.dart';
import '../config/argus_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/grid_background.dart';
import '../widgets/tech_panel.dart';
import '../widgets/tech_input.dart';
import '../widgets/tech_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final ArgusXAuthService authService;
  const ForgotPasswordScreen({super.key, required this.authService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    setState(() { _error = null; });

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'VALID EMAIL REQUIRED');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authService.resetPassword(email: email);
      if (mounted) setState(() => _sent = true);
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
                  children: [
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
                      'CREDENTIAL RECOVERY',
                      style: ArgusFonts.body(
                        color: const Color(0xFF998CA0),
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 36.0),

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
                          Text(
                            'RESET ACCESS PROTOCOL',
                            style: ArgusFonts.display(
                              color: activeColor,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
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
                          const SizedBox(height: 24.0),

                          if (_sent) ...[
                            // Success state
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                ),
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_outlined, color: Color(0xFF00E5FF), size: 16.0),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        'DIRECTIVE TRANSMITTED',
                                        style: ArgusFonts.display(
                                          color: const Color(0xFF00E5FF),
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'A password reset link has been dispatched to ${_emailController.text.trim()}. Check your inbox and follow instructions.',
                                    style: ArgusFonts.body(
                                      color: const Color(0xFF998CA0),
                                      fontSize: 11.0,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Enter your registered operator email. A secure reset directive will be dispatched to your inbox.',
                              style: ArgusFonts.body(
                                color: const Color(0xFF998CA0),
                                fontSize: 11.0,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24.0),

                            TechInput(
                              label: 'OPERATOR EMAIL',
                              hintText: 'ENTER REGISTERED EMAIL...',
                              prefixIcon: Icons.alternate_email_outlined,
                              controller: _emailController,
                            ),

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
                              label: _isLoading ? 'TRANSMITTING...' : 'TRANSMIT RESET DIRECTIVE',
                              icon: _isLoading
                                  ? Icons.hourglass_top_outlined
                                  : Icons.send_outlined,
                              onTap: _isLoading ? () {} : _sendReset,
                            ),
                          ],

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
