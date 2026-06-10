import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sim_launch_config.dart';
import '../services/navigation_service.dart';
import '../services/voice_destination_service.dart';
import '../widgets/tech_panel.dart';
import '../widgets/tech_toggle.dart';
import '../widgets/tech_button.dart';
import '../screens/camera_simulation_screen.dart';

/// Ride setup before launching the live camera safety HUD.
class CameraHudView extends StatefulWidget {
  final String riderId;

  const CameraHudView({super.key, required this.riderId});

  @override
  State<CameraHudView> createState() => _CameraHudViewState();
}

class _CameraHudViewState extends State<CameraHudView> with AutomaticKeepAliveClientMixin {
  final _destinationController = TextEditingController(text: 'Saddar, Karachi');
  final _navService = ArgusXNavigationService();
  final _voice = VoiceDestinationService();

  bool _useLiveCamera = true;
  bool _showGpsOnHud = true;
  bool _isResolving = false;
  String _status = 'Set destination by voice or text, then start the ride.';

  Map<String, dynamic>? _destination;
  Map<String, dynamic>? _routeContext;
  Map<String, dynamic>? _routeVisualization;
  Map<String, dynamic>? _origin;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _voice.initialize();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _resolveOrigin() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      return {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'label': 'Current location',
      };
    } catch (_) {
      return {'label': 'Nazimabad, Karachi'};
    }
  }

  Future<void> _resolveNavigation(String label) async {
    setState(() {
      _isResolving = true;
      _status = 'Resolving route via Google Maps...';
    });
    try {
      final origin = await _resolveOrigin();
      final result = await _navService.resolveRoute(
        origin: origin,
        destination: {'label': label},
      );
      setState(() {
        _origin = result['origin'] as Map<String, dynamic>? ?? origin;
        _destination = result['destination'] as Map<String, dynamic>? ?? {'label': label};
        _routeContext = result['route_context'] as Map<String, dynamic>?;
        _routeVisualization = result['route_visualization'] as Map<String, dynamic>?;
        _status = 'Route ready: ${_destination?['label'] ?? label}';
        _isResolving = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Route error: $e';
        _isResolving = false;
      });
    }
  }

  Future<void> _onVoiceTap() async {
    await _voice.startListening(
      onConfirmed: (place) async {
        _destinationController.text = place;
        await _resolveNavigation(place);
      },
      onStatus: (msg) {
        if (mounted) setState(() => _status = msg);
      },
    );
  }

  Future<void> _launchSimulation() async {
    final label = _destinationController.text.trim();
    if (label.isEmpty) {
      setState(() => _status = 'Enter or speak a destination first.');
      return;
    }

    if (_routeContext == null) {
      await _resolveNavigation(label);
      if (_routeContext == null) {
        if (mounted) {
          setState(() => _status = 'Could not resolve route. Check API and try again.');
        }
        return;
      }
    }

    if (!mounted) return;
    final config = SimLaunchConfig(
      destinationLabel: label,
      destination: _destination ?? {'label': label},
      routeContext: _routeContext,
      routeVisualization: _routeVisualization,
      origin: _origin,
      useLiveCamera: _useLiveCamera,
      showGpsOnHud: _showGpsOnHud,
      riderId: widget.riderId,
      sessionId: 'flutter-${DateTime.now().millisecondsSinceEpoch}',
    );

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (_, __, ___) => CameraSimulationScreen(config: config),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const activeColor = Color(0xFFDDB7FF);
    const glowColor = Color(0xFF8E2DE2);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RIDE SETUP',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFFE5E2E3),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your destination, confirm the route, then start the live safety ride.',
            style: GoogleFonts.inter(color: const Color(0xFF998CA0), fontSize: 11),
          ),
          const SizedBox(height: 20),
          TechPanel(
            padding: const EdgeInsets.all(16),
            bracketColor: glowColor.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESTINATION',
                    style: GoogleFonts.spaceGrotesk(
                        color: activeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _destinationController,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Saddar, Karachi',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF131314),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF353436)),
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TechButton(
                        label: 'RESOLVE ROUTE',
                        icon: Icons.route,
                        onTap: _isResolving
                            ? () {}
                            : () => _resolveNavigation(_destinationController.text.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _onVoiceTap,
                      icon: const Icon(Icons.mic, color: Color(0xFF8E2DE2)),
                      tooltip: 'Voice: Argus set location for...',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TechToggle(
                  label: 'USE LIVE CAMERA',
                  subLabel: 'Send real JPEG frames to perception agent',
                  value: _useLiveCamera,
                  onChanged: (v) => setState(() => _useLiveCamera = v),
                ),
                const SizedBox(height: 12),
                TechToggle(
                  label: 'SHOW GPS ON HUD',
                  subLabel: 'Display live coordinates on ride overlay',
                  value: _showGpsOnHud,
                  onChanged: (v) => setState(() => _showGpsOnHud = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _status,
            style: GoogleFonts.inter(color: const Color(0xFF93C5FD), fontSize: 11),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isResolving ? null : _launchSimulation,
            style: ElevatedButton.styleFrom(
              backgroundColor: glowColor,
              minimumSize: const Size(double.infinity, 50),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(
              'START SAFETY RIDE',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
