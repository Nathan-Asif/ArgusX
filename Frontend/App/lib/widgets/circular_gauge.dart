import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CircularGauge extends StatefulWidget {
  final double value;
  final double maxValue;
  final String label;
  final String unit;

  const CircularGauge({
    super.key,
    required this.value,
    this.maxValue = 100.0,
    required this.label,
    required this.unit,
  });

  @override
  State<CircularGauge> createState() => _CircularGaugeState();
}

class _CircularGaugeState extends State<CircularGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const glowColor = Color(0xFF8E2DE2);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Gauge Custom Paint
                  SizedBox(
                    height: 200.0,
                    width: 200.0,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        value: _animation.value,
                        maxValue: widget.maxValue,
                        accentColor: glowColor,
                      ),
                    ),
                  ),
                  // Center Text info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF998CA0),
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _animation.value.toStringAsFixed(1),
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFFE5E2E3),
                          fontSize: 42.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          shadows: [
                            Shadow(
                              color: glowColor.withValues(alpha: 0.4),
                              blurRadius: 15.0,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        widget.unit,
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF998CA0),
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color accentColor;

  _GaugePainter({
    required this.value,
    required this.maxValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);

    // Paint for faint concentric rings
    final basePaint = Paint()
      ..color = const Color(0xFF4D4354).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Paint for crosshairs
    final crossPaint = Paint()
      ..color = const Color(0xFF4D4354).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Paint for dynamic neon progress arc
    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    // Glowing effect paint for arc
    final arcGlowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
      ..strokeCap = StrokeCap.square;

    // Draw solid inner rings
    canvas.drawCircle(center, radius - 15, basePaint);
    canvas.drawCircle(center, radius - 20, basePaint);

    // Draw dashed outer ring
    final dashedPaint = Paint()
      ..color = const Color(0xFF4D4354).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    double dashWidth = 3.0;
    double dashSpace = 4.0;
    double perimeter = 2 * pi * radius;
    int dashCount = (perimeter / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < dashCount; i++) {
      double angle = (i * (dashWidth + dashSpace) / perimeter) * 2 * pi;
      double x1 = center.dx + radius * cos(angle);
      double y1 = center.dy + radius * sin(angle);
      double x2 = center.dx + radius * cos(angle + (dashWidth / perimeter) * 2 * pi);
      double y2 = center.dy + radius * sin(angle + (dashWidth / perimeter) * 2 * pi);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashedPaint);
    }

    // Draw technical crosshairs
    double crossSize = 10.0;
    // Top
    canvas.drawLine(Offset(radius, 0), Offset(radius, crossSize), crossPaint);
    // Bottom
    canvas.drawLine(Offset(radius, size.height), Offset(radius, size.height - crossSize), crossPaint);
    // Left
    canvas.drawLine(Offset(0, radius), Offset(crossSize, radius), crossPaint);
    // Right
    canvas.drawLine(Offset(size.width, radius), Offset(size.width - crossSize, radius), crossPaint);

    // Draw glowing progress arc
    double percentage = value / maxValue;
    double sweepAngle = percentage * 2 * pi * 0.75; // 270 degree arc max
    double startAngle = -pi * 1.25; // start from bottom-left diagonal

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      sweepAngle,
      false,
      arcGlowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.accentColor != accentColor;
  }
}
