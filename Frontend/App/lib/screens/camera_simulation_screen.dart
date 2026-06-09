import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/argusx_config.dart';
import '../models/sim_launch_config.dart';
import '../utils/hazard_layout.dart';
import '../widgets/hud/hud_map_panel.dart';
import '../widgets/hud/hud_nav_banner.dart';
import '../widgets/hud_bracket_painter.dart';
import '../services/navigation_service.dart';
import '../services/navigation_voice_service.dart';
import '../services/websocket_service.dart';

/// Full-screen camera HUD connected to the ArgusX Safety Pulse backend.
class CameraSimulationScreen extends StatefulWidget {
  final SimLaunchConfig config;

  const CameraSimulationScreen({
    super.key,
    required this.config,
  });

  @override
  State<CameraSimulationScreen> createState() => _CameraSimulationScreenState();
}

class _CameraSimulationScreenState extends State<CameraSimulationScreen>
    with TickerProviderStateMixin {
  // ── Camera ─────────────────────────────────────────────────────────
  CameraController? _controller;
  bool _isCameraReady = false;
  String? _cameraError;

  List<Map<String, dynamic>> _hazards = [];
  bool _showHazards = true;
  bool _showMap = true;
  bool _voiceGuidance = true;
  Map<String, dynamic> _navigation = {};
  Map<String, dynamic> _routeContext = {};
  Map<String, dynamic> _routeVisualization = {};
  String _threatLevel = 'NORMAL';
  int _routeStepIndex = 0;
  int _remainingDistanceM = 0;
  bool _advancingStep = false;

  // ── WebSocket backend link ───────────────────────────────────────
  final ArgusXWebSocketService _ws = ArgusXWebSocketService();
  final ArgusXNavigationService _navService = ArgusXNavigationService();
  final NavigationVoiceService _navVoice = NavigationVoiceService();
  StreamSubscription<ArgusXPulseResponse>? _wsSub;
  Timer? _frameTimer;
  WsConnectionState _wsState = WsConnectionState.disconnected;
  double _lat = 24.9107;
  double _lng = 67.0311;
  double _speed = 28.0;

  // ── Boot sequence state ─────────────────────────────────────────────
  bool _isBooting = true;
  String _bootText = 'ESTABLISHING SAT-LINK...';

  // ── HUD animations ──────────────────────────────────────────────────
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late AnimationController _glitchController;

  @override
  void initState() {
    super.initState();

    // Force fullscreen — hide status/nav bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Force landscape mode for the camera simulation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _blinkAnimation =
        Tween<double>(begin: 0.2, end: 1.0).animate(_blinkController);

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _runBootAndInit();
  }

  Future<void> _runBootAndInit() async {
    // Step 1 — show boot text steps
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _bootText = 'CALIBRATING RETICLE SYS...');
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _bootText = 'LINKING NAVIGATION MODULE...');
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _bootText = 'INITIALIZING CAMERA ARRAY...');

    // Step 2 — initialise real camera
    await _initCamera();
    if (mounted) setState(() => _isBooting = false);

    // Step 3 — try connecting to backend and start frame loop
    _ws.connectionState.listen((s) {
      if (mounted) setState(() => _wsState = s);
    });
    if (widget.config.origin?['lat'] != null) {
      _lat = (widget.config.origin!['lat'] as num).toDouble();
      _lng = (widget.config.origin!['lng'] as num).toDouble();
    }
    _routeVisualization = Map<String, dynamic>.from(
      widget.config.routeVisualization ?? {},
    );
    _routeContext = Map<String, dynamic>.from(widget.config.routeContext ?? {});
    _navigation = Map<String, dynamic>.from(_routeContext);
    _routeStepIndex = (_routeContext['step_index'] as int?) ?? 0;
    _remainingDistanceM = (_routeContext['distance_m'] as int?) ?? 0;

    await _navVoice.initialize();
    _navVoice.enabled = _voiceGuidance;

    await _ws.connect(ArgusXConfig.wsUrl);
    _wsSub = _ws.responses.listen(_onBackendResponse);
    _startFrameLoop();
    _sendFrame();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'NO_CAMERA_DETECTED');
        return;
      }
      // Pick back camera if available, otherwise first
      final desc = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        desc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'CAM_FAULT: ${e.code}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'ERROR: ${e.toString().substring(0, 40)}');
      }
    }
  }

  void _terminate() {
    Navigator.of(context).pop();
  }

  // ── Backend frame loop ─────────────────────────────────────────
  void _startFrameLoop() {
    // Send a telemetry frame every 1.5 s.
    _frameTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _sendFrame();
    });
  }

  Future<void> _sendFrame() async {
    _lat += 0.00005;
    _lng += 0.00003;
    _speed = 45.0 + (DateTime.now().millisecond % 20).toDouble();
    _tickNavigationProgress();

    String frameData = widget.config.fixtureToken;
    if (widget.config.useLiveCamera && _isCameraReady && _controller != null) {
      try {
        final xFile = await _controller!.takePicture();
        final bytes = await xFile.readAsBytes();
        frameData = base64Encode(bytes);
      } catch (_) {
        frameData = widget.config.fixtureToken;
      }
    }

    _ws.sendPulse(
      speed: _speed,
      lat: _lat,
      lng: _lng,
      frameData: frameData,
      sessionId: widget.config.sessionId,
      riderId: widget.config.riderId,
      destination: widget.config.destination,
      routeContext: _routeContext.isNotEmpty
          ? _routeContext
          : widget.config.routeContext,
      routeVisualization: _routeVisualization.isNotEmpty
          ? _routeVisualization
          : widget.config.routeVisualization,
      routeStepIndex: _routeStepIndex,
    );
  }

  void _tickNavigationProgress() {
    if (!widget.config.hasNavigation || _remainingDistanceM <= 0) return;

    final metersPerPulse = _speed * 1000 / 3600 * 1.5;
    _remainingDistanceM =
        (_remainingDistanceM - metersPerPulse).round().clamp(0, 999999);

    if (_remainingDistanceM < 30 && !_advancingStep) {
      _advanceRouteStep();
    }
  }

  Future<void> _advanceRouteStep() async {
    final totalSteps = (_routeContext['total_steps'] as int?) ??
        (_routeVisualization['total_steps'] as int?) ??
        1;
    if (_routeStepIndex >= totalSteps - 1) return;

    _advancingStep = true;
    try {
      final result = await _navService.resolveRoute(
        origin: {'lat': _lat, 'lng': _lng, 'label': 'Current position'},
        destination:
            widget.config.destination ?? {'label': widget.config.destinationLabel},
        stepIndex: _routeStepIndex + 1,
      );
      if (!mounted) return;
      setState(() {
        _routeStepIndex = _routeStepIndex + 1;
        _routeContext =
            Map<String, dynamic>.from(result['route_context'] as Map? ?? {});
        _routeVisualization = Map<String, dynamic>.from(
          result['route_visualization'] as Map? ?? _routeVisualization,
        );
        _remainingDistanceM = (_routeContext['distance_m'] as int?) ?? 0;
      });
      _navVoice.resetRoute();
    } catch (_) {
      // Keep current step if resolve fails.
    } finally {
      _advancingStep = false;
    }
  }

  void _onBackendResponse(ArgusXPulseResponse r) {
    if (!mounted) return;
    _navVoice.onNavigationUpdate(
      r.navigation,
      stepIndex: _routeStepIndex,
      remainingDistanceM: _remainingDistanceM,
      threatLevel: r.threatLevel,
    );
    setState(() {
      _threatLevel = r.threatLevel;
      _navigation = r.navigation;
      if (r.routeVisualization.isNotEmpty) {
        _routeVisualization = r.routeVisualization;
      }
      _hazards = [];
      if (_showHazards && r.hazards.isNotEmpty) {
        for (final item in r.hazards) {
          if (item is Map<String, dynamic>) {
            _hazards.add(HazardLayout.fromAgentHazard(item));
          } else if (item is Map) {
            _hazards.add(HazardLayout.fromAgentHazard(Map<String, dynamic>.from(item)));
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _wsSub?.cancel();
    _ws.dispose();
    _navVoice.dispose();
    _blinkController.dispose();
    _glitchController.dispose();
    _controller?.dispose();
    
    // Restore system UI overlay (status and nav bars) on return to dashboard
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Restore preferred orientations to default (auto-rotate portrait/landscape)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFDDB7FF);
    const dangerColor = Color(0xFFFF5252);
    final borderColor = const Color(0xFFDDB7FF).withValues(alpha: 0.6);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Camera feed / states ─────────────────────────────
            if (_isBooting)
              _BootOverlay(
                glitchController: _glitchController,
                bootText: _bootText,
              )
            else if (_isCameraReady && _controller != null)
              _CameraFeed(controller: _controller!)
            else
              _CameraErrorView(error: _cameraError),

            // ── Everything below only shown when boot is done ────────
            if (!_isBooting) ...[
              // Scanlines (5% opacity to keep feed legible)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: CustomPaint(painter: _ScanlinePainter()),
                ),
              ),

              // ── Passive Sentry Vision Overlay (PRD §5.1) ───────────
              if (_showHazards)
                ..._hazards.map((h) {
                  return Positioned(
                    top: MediaQuery.of(context).size.height * h['top'],
                    left: MediaQuery.of(context).size.width * h['left'],
                    width: MediaQuery.of(context).size.width * h['width'],
                    height: MediaQuery.of(context).size.height * h['height'],
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: h['color'] as Color, width: 1.5),
                        color: (h['color'] as Color).withValues(alpha: 0.05),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Top-left threat tag
                          Positioned(
                            top: -18,
                            left: -1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              color: h['color'] as Color,
                              child: Text(
                                "${h['threat']} // ${h['distance']}",
                                style: GoogleFonts.spaceMono(
                                  color: Colors.black,
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Bottom-left label
                          Positioned(
                            bottom: 2,
                            left: 4,
                            child: Text(
                              h['label'] as String,
                              style: GoogleFonts.spaceGrotesk(
                                color: h['color'] as Color,
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Reticle indicators on corners
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(width: 6, height: 6, color: h['color'] as Color),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(width: 6, height: 6, color: h['color'] as Color),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              if (_navigation.isNotEmpty)
                Positioned(
                  top: 56,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: HudNavBanner(
                      navigation: _navigation,
                      remainingDistanceM: _remainingDistanceM > 0
                          ? _remainingDistanceM
                          : null,
                    ),
                  ),
                ),

              if (_showMap && _routeVisualization.isNotEmpty)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: HudMapPanel(
                    routeVisualization: _routeVisualization,
                    lat: _lat,
                    lng: _lng,
                  ),
                ),

              // ── Overlay toggles ───
              Positioned(
                bottom: 80.0,
                left: 24.0,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    border: Border.all(color: activeColor.withValues(alpha: 0.5), width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HUD OVERLAYS',
                        style: GoogleFonts.spaceGrotesk(
                          color: activeColor,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          _MiniToggle(
                            label: 'HAZARD DETECT',
                            value: _showHazards,
                            activeColor: const Color(0xFFFF5252),
                            onChanged: (val) => setState(() => _showHazards = val),
                          ),
                          const SizedBox(width: 8.0),
                          _MiniToggle(
                            label: 'ROUTE MAP',
                            value: _showMap,
                            activeColor: const Color(0xFF00E5FF),
                            onChanged: (val) => setState(() => _showMap = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      _MiniToggle(
                        label: 'VOICE GUIDANCE',
                        value: _voiceGuidance,
                        activeColor: const Color(0xFFDDB7FF),
                        onChanged: (val) {
                          setState(() {
                            _voiceGuidance = val;
                            _navVoice.enabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Top data bar
              Positioned(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                child: _TopHudBar(
                  borderColor: borderColor,
                  activeColor: activeColor,
                  speed: _speed,
                  threat: _threatLevel,
                ),
              ),

              // WS live / sim status badge — top-right corner
              Positioned(
                top: 16.0,
                right: 16.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    border: Border.all(
                      color: _wsState == WsConnectionState.connected
                          ? const Color(0xFF00E5FF)
                          : _wsState == WsConnectionState.connecting
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFF4D4354),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.0,
                        height: 5.0,
                        color: _wsState == WsConnectionState.connected
                            ? const Color(0xFF00E5FF)
                            : _wsState == WsConnectionState.connecting
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFF4D4354),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        _wsState == WsConnectionState.connected
                            ? 'LIVE FEED'
                            : _wsState == WsConnectionState.connecting
                                ? 'LINKING...'
                                : 'SIM MODE',
                        style: GoogleFonts.spaceMono(
                          color: _wsState == WsConnectionState.connected
                              ? const Color(0xFF00E5FF)
                              : _wsState == WsConnectionState.connecting
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFF4D4354),
                          fontSize: 8.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Central targeting reticle
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _ReticlePainter(
                      color: activeColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),

              // Bottom-left REC indicator
              Positioned(
                bottom: 24.0,
                left: 24.0,
                child: FadeTransition(
                  opacity: _blinkAnimation,
                  child: Row(
                    children: [
                      Container(
                        width: 10.0,
                        height: 10.0,
                        // Square marker per design.md §Data Visualization
                        color: dangerColor,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'REC // CH-1',
                        style: GoogleFonts.spaceGrotesk(
                          color: dangerColor,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (widget.config.showGpsOnHud)
                Positioned(
                  bottom: 24.0,
                  left: 24.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEST: ${widget.config.destinationLabel}',
                        style: GoogleFonts.spaceMono(
                          color: activeColor,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'LAT: ${_lat.toStringAsFixed(5)}',
                        style: GoogleFonts.spaceMono(color: activeColor, fontSize: 9.0),
                      ),
                      Text(
                        'LNG: ${_lng.toStringAsFixed(5)}',
                        style: GoogleFonts.spaceMono(color: activeColor, fontSize: 9.0),
                      ),
                    ],
                  ),
                ),

              // Corner brackets (design.md §Cards & Modules)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomPaint(painter: HudBracketPainter(color: borderColor)),
                ),
              ),

              // Terminate button — top-left, danger red, 0px radius
              Positioned(
                top: 80.0,
                left: 24.0,
                child: GestureDetector(
                  onTap: _terminate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      border: Border.all(color: dangerColor, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close, color: dangerColor, size: 12.0),
                        const SizedBox(width: 4.0),
                        Text(
                          'END RIDE',
                          style: GoogleFonts.spaceGrotesk(
                            color: dangerColor,
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Camera feed widget ────────────────────────────────────────────────
class _CameraFeed extends StatelessWidget {
  final CameraController controller;
  const _CameraFeed({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxWidth *
                (controller.value.aspectRatio == 0
                    ? 16 / 9
                    : 1 / controller.value.aspectRatio),
            child: CameraPreview(controller),
          ),
        ),
      );
    });
  }
}

// ── Error fallback ───────────────────────────────────────────────────
class _CameraErrorView extends StatelessWidget {
  final String? error;
  const _CameraErrorView({this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0B0C),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined,
                color: Color(0xFFFF5252), size: 48),
            const SizedBox(height: 16),
            Text(
              error ?? 'CAMERA_UNAVAILABLE',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFFFF5252),
                fontSize: 12.0,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check browser camera permissions and reload.',
              style: GoogleFonts.inter(
                color: const Color(0xFF998CA0),
                fontSize: 11.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Boot overlay ─────────────────────────────────────────────────────
class _BootOverlay extends StatelessWidget {
  final AnimationController glitchController;
  final String bootText;
  const _BootOverlay(
      {required this.glitchController, required this.bootText});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40.0,
              height: 40.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
              ),
            ),
            const SizedBox(height: 24.0),
            AnimatedBuilder(
              animation: glitchController,
              builder: (context, _) {
                final shift = glitchController.value > 0.8 ? 2.0 : 0.0;
                return Padding(
                  padding: EdgeInsets.only(left: shift),
                  child: Text(
                    bootText,
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF00E5FF),
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top HUD bar ──────────────────────────────────────────────────────
class _TopHudBar extends StatelessWidget {
  final Color borderColor;
  final Color activeColor;
  final double speed;
  final String threat;

  const _TopHudBar({
    required this.borderColor,
    required this.activeColor,
    required this.speed,
    required this.threat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 1.0, color: borderColor, width: double.infinity),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ARGUSX',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFFE5E2E3),
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        '${speed.toInt()} km/h',
                        style: GoogleFonts.spaceMono(color: activeColor, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 10.0,
                child:
                    CustomPaint(painter: HudDividerPainter(color: borderColor)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'THREAT: $threat',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFFE5E2E3),
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Row(
                        children: [
                          // Square indicator per design.md §Status Chips
                          Container(
                            width: 6,
                            height: 6,
                            color: const Color(0xFF00E676),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '100%',
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFF00E676),
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
            height: 1.0,
            color: borderColor.withValues(alpha: 0.3),
            width: double.infinity),
      ],
    );
  }
}

// ── Scanline painter ─────────────────────────────────────────────────
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;
    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Targeting reticle painter ─────────────────────────────────────────
class _ReticlePainter extends CustomPainter {
  final Color color;
  _ReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
        center,
        radius + 10,
        paint
          ..strokeWidth = 0.5
          ..color = color.withValues(alpha: 0.3));

    final lineLength = radius + 20;
    // Crosshair lines
    canvas.drawLine(Offset(center.dx, center.dy - radius / 2),
        Offset(center.dx, center.dy - lineLength), paint);
    canvas.drawLine(Offset(center.dx, center.dy + radius / 2),
        Offset(center.dx, center.dy + lineLength), paint);
    canvas.drawLine(Offset(center.dx - radius / 2, center.dy),
        Offset(center.dx - lineLength, center.dy), paint);
    canvas.drawLine(Offset(center.dx + radius / 2, center.dy),
        Offset(center.dx + lineLength, center.dy), paint);

    // Center dot — square per design.md §Data Visualization
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 4.0, height: 4.0),
      paint
        ..style = PaintingStyle.fill
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Mini Toggle Button for HUD Overlays ──────────────────────────────
class _MiniToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _MiniToggle({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: value ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: value ? activeColor : const Color(0xFF353436),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.0,
              height: 6.0,
              color: value ? activeColor : const Color(0xFF353436),
            ),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                color: value ? Colors.white : const Color(0xFF998CA0),
                fontSize: 8.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
