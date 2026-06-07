import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/argus_ring.dart';
import '../components/glass_panel.dart';
import '../services/websocket_service.dart';

class HudViewport extends StatefulWidget {
  final WebSocketService wsService;

  const HudViewport({
    super.key,
    required this.wsService,
  });

  @override
  State<HudViewport> createState() => _HudViewportState();
}

class _HudViewportState extends State<HudViewport> {
  double _speed = 52.4;
  double _lat = 37.7749;
  double _lng = -122.4194;
  int _battery = 98;
  int _secondsElapsed = 0;
  
  late Timer _telemetryTimer;
  late Timer _clockTimer;

  @override
  void initState() {
    super.initState();
    widget.wsService.connect();

    // Telemetry updates simulation (runs every 3 seconds)
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Slight speed changes
          _speed = double.parse((_speed + (double.tryParse((timer.tick % 5 - 2).toString()) ?? 0.0) * 2.1).toStringAsFixed(1));
          if (_speed < 0) _speed = 0;
          if (_speed > 130) _speed = 120;

          // Minor coordinate shifts
          _lat = double.parse((_lat + 0.00012).toStringAsFixed(5));
          _lng = double.parse((_lng - 0.00008).toStringAsFixed(5));

          // Lower battery slowly
          if (timer.tick % 60 == 0 && _battery > 1) {
            _battery--;
          }
        });

        // Broadcast telemetry through the socket
        widget.wsService.sendTelemetry(_speed, _lat, _lng);
      }
    });

    // Clock/Elapsed timer
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _telemetryTimer.cancel();
    _clockTimer.cancel();
    widget.wsService.disconnect();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;

    final String hoursStr = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return '$hoursStr$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: AnimatedBuilder(
        animation: widget.wsService,
        builder: (context, child) {
          final threat = widget.wsService.threatLevel;
          final contextText = widget.wsService.enrichedContext;
          final commands = widget.wsService.uiCommands;
          final isConnected = widget.wsService.isConnected;
          final isConnecting = widget.wsService.isConnecting;

          // Style adjustments based on threat levels
          Color statusGlowColor;
          if (threat == 'CRITICAL') {
            statusGlowColor = const Color(0xFFEF4444);
          } else if (threat == 'WARNING') {
            statusGlowColor = const Color(0xFFF59E0B);
          } else {
            statusGlowColor = const Color(0xFF8B5CF6);
          }

          // Check if HUD commands instruct pruning widgets
          final pruneWidgets = commands.contains('PRUNE_NON_ESSENTIAL_WIDGETS');

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  statusGlowColor.withOpacity(0.06),
                  const Color(0xFF020202),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20.0),
            child: SafeArea(
              child: Row(
                children: [
                  // --- LEFT PANEL (Operator Telemetry) ---
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Connection Status Banner
                        GlassPanel(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                          borderRadius: 8.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isConnected 
                                      ? const Color(0xFF06B6D4) 
                                      : isConnecting 
                                          ? const Color(0xFFF59E0B) 
                                          : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                isConnected 
                                    ? 'HUD LINKED' 
                                    : isConnecting 
                                        ? 'LINKING...' 
                                        : 'OFFLINE MODE',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Speedometer widget
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SPEED',
                              style: GoogleFonts.outfit(
                                color: Colors.white30,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${_speed.toInt()}',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 68,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  'KM/H',
                                  style: GoogleFonts.outfit(
                                    color: statusGlowColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Secondary Stats block (Hidden if PRUNE HUD mode is active)
                        pruneWidgets
                            ? const SizedBox(height: 20)
                            : GlassPanel(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('DUR', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
                                        const SizedBox(height: 2),
                                        Text(_formatDuration(_secondsElapsed), style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('BAT', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
                                        const SizedBox(height: 2),
                                        Text('$_battery%', style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),

                  // --- CENTER PANEL (Argus Ring & Alerts) ---
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pulse Iris
                        ArgusRing(threatLevel: threat),
                        const SizedBox(height: 20),

                        // Threat Alert Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: statusGlowColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: statusGlowColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            threat,
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- RIGHT PANEL (Spatial Grounding & Context) ---
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // GPS Coords Display
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'GPS POS',
                              style: GoogleFonts.outfit(
                                color: Colors.white30,
                                fontSize: 9,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$_lat, $_lng',
                              style: GoogleFonts.orbitron(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // AI Perception Feed Box (Prunes non-essential text if requested)
                        GlassPanel(
                          padding: const EdgeInsets.all(14.0),
                          borderColor: statusGlowColor.withOpacity(0.15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    color: statusGlowColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    'SENTRY FEED',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                pruneWidgets 
                                    ? 'Minimal alert overlay active.' 
                                    : contextText,
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Local Test Controllers (Only shown in simulator environment)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Button to cycle mock threat levels (for testing overlay visuals without backend)
                            GestureDetector(
                              onTap: () {
                                if (threat == 'NORMAL') {
                                  widget.wsService.simulateThreatChange(
                                    'WARNING',
                                    'WARNING: Cross-traffic intersection hazard detected.',
                                  );
                                } else if (threat == 'WARNING') {
                                  widget.wsService.simulateThreatChange(
                                    'CRITICAL',
                                    'CRITICAL: Immediate deceleration ahead. Obstruction.',
                                  );
                                } else {
                                  widget.wsService.simulateThreatChange(
                                    'NORMAL',
                                    'Scan complete. Corridor verified clear.',
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Text(
                                  'TEST OVERLAYS',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white30,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
