import 'package:flutter/material.dart';
import 'package:argusx/config/argus_fonts.dart';

class HudNavBanner extends StatelessWidget {
  final Map<String, dynamic> navigation;
  final int? remainingDistanceM;

  const HudNavBanner({
    super.key,
    required this.navigation,
    this.remainingDistanceM,
  });

  @override
  Widget build(BuildContext context) {
    final arrow = (navigation['arrow'] as String? ?? 'STRAIGHT').toUpperCase();
    final instruction = navigation['instruction'] as String? ?? 'Continue on route';
    final distanceM = remainingDistanceM ?? navigation['distance_m'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForArrow(arrow), color: const Color(0xFF34D399), size: 28),
          const SizedBox(height: 4),
          Text(
            arrow.replaceAll('_', ' '),
            style: ArgusFonts.display(
              color: const Color(0xFF34D399),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            distanceM != null ? 'In ${distanceM}m - $instruction' : instruction,
            textAlign: TextAlign.center,
            style: ArgusFonts.body(
              color: const Color(0xFFE5E2E3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForArrow(String arrow) => switch (arrow) {
        'LEFT' => Icons.turn_left,
        'RIGHT' => Icons.turn_right,
        'U_TURN' => Icons.u_turn_left,
        _ => Icons.arrow_upward,
      };
}
