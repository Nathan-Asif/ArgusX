import 'package:flutter/material.dart';

class HudBracketPainter extends CustomPainter {
  final Color color;

  HudBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // We want to draw a border with "T" intersections or L brackets
    // Left-Top L-Bracket
    canvas.drawLine(const Offset(0, 8), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(8, 0), paint);
    
    // Fill corner
    canvas.drawRect(const Rect.fromLTWH(0, 0, 3, 3), fillPaint);

    // Right-Top L-Bracket
    canvas.drawLine(Offset(size.width - 8, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, 8), paint);
    
    // Fill corner
    canvas.drawRect(Rect.fromLTWH(size.width - 3, 0, 3, 3), fillPaint);

    // Bottom-Left L-Bracket
    canvas.drawLine(Offset(0, size.height - 8), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(8, size.height), paint);

    // Bottom-Right L-Bracket
    canvas.drawLine(Offset(size.width - 8, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// A specific painter for the top divider T-joint seen in the mockup
class HudDividerPainter extends CustomPainter {
  final Color color;

  HudDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw vertical line
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    
    // Draw top T-bracket
    canvas.drawLine(Offset(size.width / 2 - 4, 0), Offset(size.width / 2 + 4, 0), paint);
    
    // Fill the T-joint box
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 1.5, 0, 3, 3), fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
