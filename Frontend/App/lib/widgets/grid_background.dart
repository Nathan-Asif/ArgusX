import 'package:flutter/material.dart';

class GridBackground extends StatelessWidget {
  final Widget child;

  const GridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Obsidian Base Color
        Container(
          color: const Color(0xFF0B0B0C),
        ),
        // Grid Paint Layer
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ),
        ),
        // Subtle Gradient Overlay for Depth (Simulates light emission from screen center)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF8E2DE2).withValues(alpha: 0.04), // soft purple glow in center
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Child Content
        Positioned.fill(child: child),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8E2DE2).withValues(alpha: 0.06) // faint violet line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final dotPaint = Paint()
      ..color = const Color(0xFF8E2DE2).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const double step = 25.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Square markers at intersections — squares only per design.md §Data Visualization
    for (double x = 0; x < size.width; x += step * 4) {
      for (double y = 0; y < size.height; y += step * 4) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: 1.5, height: 1.5),
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
