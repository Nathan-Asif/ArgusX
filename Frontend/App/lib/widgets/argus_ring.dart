import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/argus_fonts.dart';

/// Threat level enum matching PRD §6.1 outbound WebSocket schema.
/// threat_level: "NORMAL | WARNING | CRITICAL"
enum ThreatLevel { normal, warning, critical }

/// HUD State Machine per PRD §7 SDA Compliance.
/// Standby → Sentry_Active → Hazard_Alert → Navigation
enum HudState { standby, sentryActive, hazardAlert, navigation }

extension ThreatLevelLabel on ThreatLevel {
  String get label {
    return switch (this) {
      ThreatLevel.normal => 'NORMAL',
      ThreatLevel.warning => 'WARNING',
      ThreatLevel.critical => 'CRITICAL',
    };
  }

  Color get primaryColor {
    return switch (this) {
      ThreatLevel.normal => const Color(0xFFDDB7FF),   // Quantum Violet
      ThreatLevel.warning => const Color(0xFFFFB74D),  // Amber
      ThreatLevel.critical => const Color(0xFFFF5252), // Danger Red
    };
  }

  Color get glowColor {
    return switch (this) {
      ThreatLevel.normal => const Color(0xFF8E2DE2),
      ThreatLevel.warning => const Color(0xFFE65100),
      ThreatLevel.critical => const Color(0xFFB71C1C),
    };
  }
}

extension HudStateLabel on HudState {
  String get label {
    return switch (this) {
      HudState.standby => 'STANDBY',
      HudState.sentryActive => 'SENTRY ACTIVE',
      HudState.hazardAlert => 'HAZARD ALERT',
      HudState.navigation => 'NAV MODE',
    };
  }

  double get irisTarget {
    return switch (this) {
      HudState.standby => 0.15,
      HudState.sentryActive => 0.65,
      HudState.hazardAlert => 0.92,
      HudState.navigation => 0.42,
    };
  }
}

/// The Argus Ring — the central pulsing digital iris (PRD §5.1).
/// Dynamically shifts neon color profiles (Quantum Violet gradients)
/// depending on system health metrics and external threat levels.
class ArgusRing extends StatefulWidget {
  final ThreatLevel threatLevel;
  final HudState hudState;
  final double size;

  const ArgusRing({
    super.key,
    this.threatLevel = ThreatLevel.normal,
    this.hudState = HudState.standby,
    this.size = 240.0,
  });

  @override
  State<ArgusRing> createState() => _ArgusRingState();
}

class _ArgusRingState extends State<ArgusRing> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _irisController;
  late AnimationController _flickerController;

  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _irisAnim;
  late Animation<double> _flickerAnim;

  double _currentIris = 0.15;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(vsync: this, duration: _pulseDuration)
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
    _rotateAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _irisController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _currentIris = widget.hudState.irisTarget;
    _irisAnim = Tween<double>(begin: _currentIris, end: _currentIris).animate(_irisController);

    _flickerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 110))
      ..repeat(reverse: true);
    _flickerAnim = Tween<double>(begin: 0.78, end: 1.0).animate(_flickerController);
  }

  Duration get _pulseDuration {
    return switch (widget.threatLevel) {
      ThreatLevel.critical => const Duration(milliseconds: 280),
      ThreatLevel.warning => const Duration(milliseconds: 680),
      ThreatLevel.normal => const Duration(milliseconds: 1700),
    };
  }

  void _animateIrisTo(double target) {
    final start = _irisAnim.value;
    _irisAnim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _irisController, curve: Curves.easeOutCubic),
    );
    _irisController
      ..reset()
      ..forward();
  }

  @override
  void didUpdateWidget(ArgusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.threatLevel != widget.threatLevel) {
      _pulseController.duration = _pulseDuration;
      _pulseController.repeat(reverse: true);
    }
    if (oldWidget.hudState != widget.hudState) {
      _animateIrisTo(widget.hudState.irisTarget);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _irisController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _rotateAnim, _irisAnim, _flickerAnim]),
      builder: (ctx, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _ArgusRingPainter(
                  pulse: _pulseAnim.value,
                  rotate: _rotateAnim.value,
                  iris: _irisAnim.value,
                  flicker: widget.threatLevel == ThreatLevel.critical ? _flickerAnim.value : 1.0,
                  primaryColor: widget.threatLevel.primaryColor,
                  glowColor: widget.threatLevel.glowColor,
                  hudState: widget.hudState,
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              widget.hudState.label,
              style: ArgusFonts.display(
                color: widget.threatLevel.primaryColor.withValues(alpha: 0.85),
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ArgusRingPainter extends CustomPainter {
  final double pulse;
  final double rotate;
  final double iris;
  final double flicker;
  final Color primaryColor;
  final Color glowColor;
  final HudState hudState;

  _ArgusRingPainter({
    required this.pulse,
    required this.rotate,
    required this.iris,
    required this.flicker,
    required this.primaryColor,
    required this.glowColor,
    required this.hudState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    _drawGlowHalo(canvas, center, maxR * 0.94);
    _drawRotatingDashes(canvas, center, maxR * 0.89);
    _drawTickRing(canvas, center, maxR * 0.81);
    _drawCircle(canvas, center, maxR * 0.73, 1.0, primaryColor.withValues(alpha: 0.45 * pulse));
    _drawCircle(canvas, center, maxR * 0.63, 1.5, primaryColor.withValues(alpha: 0.75 * pulse));
    _drawIrisBlades(canvas, center, maxR * 0.57);
    _drawCore(canvas, center, maxR * (0.26 - iris * 0.10));
  }

  void _drawGlowHalo(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = glowColor.withValues(alpha: 0.13 * pulse * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.12 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  void _drawRotatingDashes(Canvas canvas, Offset c, double r) {
    const n = 48;
    const angle = (2 * math.pi) / n;
    const gap = 0.42;
    final paint = Paint()
      ..color = primaryColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < n; i++) {
      final a = rotate + i * angle;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, angle * (1 - gap), false, paint);
    }
  }

  void _drawTickRing(Canvas canvas, Offset c, double r) {
    const n = 36;
    final p = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final pMajor = Paint()
      ..color = primaryColor.withValues(alpha: 0.75)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < n; i++) {
      final a = (2 * math.pi / n) * i;
      final isMajor = i % 9 == 0;
      final len = isMajor ? 10.0 : 5.0;
      canvas.drawLine(
        Offset(c.dx + (r - len) * math.cos(a), c.dy + (r - len) * math.sin(a)),
        Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a)),
        isMajor ? pMajor : p,
      );
    }
  }

  void _drawCircle(Canvas canvas, Offset c, double r, double sw, Color color) {
    canvas.drawCircle(c, r, Paint()..color = color..strokeWidth = sw..style = PaintingStyle.stroke);
  }

  void _drawIrisBlades(Canvas canvas, Offset c, double r) {
    const blades = 8;
    const closedA = math.pi / blades;
    final openA = closedA * (1 - iris * 0.65);
    final innerR = r * (0.42 + iris * 0.22);

    final fill = Paint()
      ..color = primaryColor.withValues(alpha: 0.20 + iris * 0.12)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = primaryColor.withValues(alpha: 0.55)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < blades; i++) {
      final base = (2 * math.pi / blades) * i;
      final path = Path()
        ..moveTo(c.dx + innerR * math.cos(base - closedA * 0.5), c.dy + innerR * math.sin(base - closedA * 0.5))
        ..lineTo(c.dx + r * math.cos(base - openA), c.dy + r * math.sin(base - openA))
        ..lineTo(c.dx + r * math.cos(base + openA), c.dy + r * math.sin(base + openA))
        ..lineTo(c.dx + innerR * math.cos(base + closedA * 0.5), c.dy + innerR * math.sin(base + closedA * 0.5))
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  void _drawCore(Canvas canvas, Offset c, double r) {
    // Glow
    canvas.drawCircle(c, r * 1.6, Paint()
      ..color = glowColor.withValues(alpha: 0.28 * pulse * flicker)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    // Gradient fill
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(colors: [
        primaryColor.withValues(alpha: 0.9 * pulse * flicker),
        glowColor.withValues(alpha: 0.55 * pulse * flicker),
        Colors.transparent,
      ], stops: const [0.0, 0.55, 1.0]).createShader(Rect.fromCircle(center: c, radius: r)));
    // Border ring
    canvas.drawCircle(c, r, Paint()
      ..color = primaryColor.withValues(alpha: 0.9 * pulse)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);
    // Center square dot (design.md §Data Visualization — no circles)
    canvas.drawRect(
      Rect.fromCenter(center: c, width: 4.0, height: 4.0),
      Paint()..color = primaryColor..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ArgusRingPainter old) => true;
}
