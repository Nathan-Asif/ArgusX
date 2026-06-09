import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom-right route map using Google Static Maps URL from backend.
class HudMapPanel extends StatelessWidget {
  final Map<String, dynamic> routeVisualization;
  final double lat;
  final double lng;

  const HudMapPanel({
    super.key,
    required this.routeVisualization,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final staticUrl = routeVisualization['static_map_url'] as String? ?? '';
    final remaining = routeVisualization['distance_remaining_m'];
    final dest = routeVisualization['destination'] as Map<String, dynamic>?;

    return Container(
      width: 220,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        border: Border.all(color: const Color(0xFF8E2DE2).withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (staticUrl.isNotEmpty)
            Image.network(
              staticUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackMap(),
            )
          else
            _fallbackMap(),
          Positioned(
            top: 6,
            left: 8,
            child: Text(
              'ROUTE MAP',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          if (remaining != null)
            Positioned(
              bottom: 22,
              left: 8,
              child: Text(
                '${(remaining as num) / 1000} km left',
                style: GoogleFonts.spaceMono(color: const Color(0xFF93C5FD), fontSize: 9),
              ),
            ),
          Positioned(
            bottom: 6,
            left: 8,
            right: 8,
            child: Text(
              dest?['label'] as String? ?? '$lat, $lng',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceMono(color: const Color(0xFF998CA0), fontSize: 7.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackMap() {
    return Container(
      color: const Color(0xFF1A1A1F),
      alignment: Alignment.center,
      child: Text(
        'Awaiting route map',
        style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 10),
      ),
    );
  }
}
