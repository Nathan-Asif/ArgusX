import 'package:flutter/material.dart';
import 'package:argusx/config/argus_fonts.dart';
import 'tech_panel.dart';

class TechButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const TechButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<TechButton> createState() => _TechButtonState();
}

class _TechButtonState extends State<TechButton> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _isPressed = true;
    });

    _rotationController.repeat();
    widget.onTap();

    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _isPressed = false;
    });

    // Simulate system sync for 2 seconds to show off the gorgeous rotating animation
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isSyncing = false;
      });
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final focusGlowColor = Theme.of(context).colorScheme.secondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54.0,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: (_isHovered || _isSyncing)
                  ? [
                      BoxShadow(
                        color: focusGlowColor.withValues(alpha: 0.3),
                        blurRadius: 15.0,
                        spreadRadius: 2.0,
                      ),
                    ]
                  : null,
            ),
            child: TechPanel(
              padding: EdgeInsets.zero, // no internal padding
              borderColor: activeColor,
              bracketColor: activeColor,
              bracketLength: 10.0,
              bracketThickness: 2.0,
              backgroundColor: Colors.transparent, // transparent to let the gradient shine
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      focusGlowColor.withValues(alpha: 0.85),
                      focusGlowColor.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rotating tech icon
                      RotationTransition(
                        turns: _rotationController,
                        child: Icon(
                          widget.icon,
                          color: const Color(0xFFE5E2E3),
                          size: 18.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      // Text label
                      Text(
                        _isSyncing ? "SYNCING..." : widget.label.toUpperCase(),
                        style: ArgusFonts.display(
                          color: const Color(0xFFE5E2E3),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
