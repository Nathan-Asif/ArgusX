import 'dart:ui';
import 'package:flutter/material.dart';

class TechPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Color bracketColor;
  final double bracketLength;
  final double bracketThickness;
  final Color backgroundColor;

  const TechPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.borderColor = const Color(0xFF353436), // titanium border
    this.bracketColor = const Color(0xFFDDB7FF), // glow purple/pink accent
    this.bracketLength = 12.0,
    this.bracketThickness = 2.0,
    this.backgroundColor = const Color(0xCC131314), // translucent obsidian black
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CornerBracketPainter(
        bracketColor: bracketColor,
        bracketLength: bracketLength,
        bracketThickness: bracketThickness,
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  final Color bracketColor;
  final double bracketLength;
  final double bracketThickness;

  _CornerBracketPainter({
    required this.bracketColor,
    required this.bracketLength,
    required this.bracketThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bracketColor
      ..strokeWidth = bracketThickness
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;

    // Top-Left corner
    canvas.drawLine(const Offset(0, 0), Offset(bracketLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, bracketLength), paint);

    // Top-Right corner
    canvas.drawLine(Offset(w, 0), Offset(w - bracketLength, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, bracketLength), paint);

    // Bottom-Left corner
    canvas.drawLine(Offset(0, h), Offset(bracketLength, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - bracketLength), paint);

    // Bottom-Right corner
    canvas.drawLine(Offset(w, h), Offset(w - bracketLength, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - bracketLength), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    return oldDelegate.bracketColor != bracketColor ||
        oldDelegate.bracketLength != bracketLength ||
        oldDelegate.bracketThickness != bracketThickness;
  }
}
