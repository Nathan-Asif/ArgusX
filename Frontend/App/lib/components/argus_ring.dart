import 'dart:math';
import 'package:flutter/material.dart';

class ArgusRing extends StatefulWidget {
  final String threatLevel;

  const ArgusRing({
    super.key,
    required this.threatLevel,
  });

  @override
  State<ArgusRing> createState() => _ArgusRingState();
}

class _ArgusRingState extends State<ArgusRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically adjust animation duration based on threat levels
    if (widget.threatLevel == 'CRITICAL') {
      _controller.duration = const Duration(milliseconds: 1000);
    } else if (widget.threatLevel == 'WARNING') {
      _controller.duration = const Duration(milliseconds: 1800);
    } else {
      _controller.duration = const Duration(milliseconds: 3000);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(160, 160),
          painter: _RingPainter(
            animationValue: _controller.value,
            threatLevel: widget.threatLevel,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double animationValue;
  final String threatLevel;

  _RingPainter({
    required this.animationValue,
    required this.threatLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width / 2, size.height / 2);

    // Color definitions based on threat levels
    Color primaryColor;
    Color secondaryColor;
    double pulseScale;

    if (threatLevel == 'CRITICAL') {
      primaryColor = const Color(0xFFEF4444); // Crimson Red
      secondaryColor = const Color(0xFFEC4899); // Neon Pink
      pulseScale = 0.85 + 0.15 * sin(animationValue * 2 * pi);
    } else if (threatLevel == 'WARNING') {
      primaryColor = const Color(0xFFF59E0B); // Amber Yellow
      secondaryColor = const Color(0xFFEC4899);
      pulseScale = 0.90 + 0.10 * sin(animationValue * 2 * pi);
    } else {
      primaryColor = const Color(0xFF8B5CF6); // Quantum Violet
      secondaryColor = const Color(0xFF06B6D4); // Cyan
      pulseScale = 0.93 + 0.07 * sin(animationValue * 2 * pi);
    }

    // Paint: Outer glow ring
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..shader = SweepGradient(
        colors: [
          primaryColor.withOpacity(0.0),
          primaryColor.withOpacity(0.4),
          secondaryColor.withOpacity(0.4),
          primaryColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
        transform: GradientRotation(animationValue * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius * pulseScale, glowPaint);

    // Paint: Inner neon ring
    final neonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = SweepGradient(
        colors: [
          primaryColor,
          secondaryColor,
          primaryColor,
        ],
        transform: GradientRotation(-animationValue * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.75));

    canvas.drawCircle(center, maxRadius * 0.75 * (2.0 - pulseScale), neonPaint);

    // Paint: Central digital iris (radar lines)
    final radarPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2) + (animationValue * pi / 4);
      final start = Offset(
        center.dx + cos(angle) * (maxRadius * 0.3),
        center.dy + sin(angle) * (maxRadius * 0.3),
      );
      final end = Offset(
        center.dx + cos(angle) * (maxRadius * 0.65),
        center.dy + sin(angle) * (maxRadius * 0.65),
      );
      canvas.drawLine(start, end, radarPaint);
    }

    // Paint: Pulse core dot
    final corePaint = Paint()
      ..color = primaryColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, maxRadius * 0.15 * pulseScale, corePaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.threatLevel != threatLevel;
  }
}
