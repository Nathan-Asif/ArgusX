import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/tech_panel.dart';
import '../widgets/circular_gauge.dart';
import '../widgets/event_log.dart';
import '../widgets/argus_ring.dart';
import '../services/websocket_service.dart';

class MissionControlView extends StatefulWidget {
  const MissionControlView({super.key});

  @override
  State<MissionControlView> createState() => _MissionControlViewState();
}

class _MissionControlViewState extends State<MissionControlView> with AutomaticKeepAliveClientMixin {
  // ── HUD State Machine (PRD §7) ────────────────────────────────────
  HudState _hudState = HudState.standby;
  ThreatLevel _threatLevel = ThreatLevel.normal;

  // PRD §6.1 outbound schema — active ui_commands list
  List<String> _uiCommands = [];

  // ── Simulated Inbound Telemetry Stream (PRD §6.1) ─────────────────
  double _simSpeed = 45.2;
  double _simLat = 34.0522;
  double _simLng = -118.2437;
  String _simFrameHash = 'e2b3c4...';
  Timer? _simTimer;

  // ── Live WebSocket Backend Connection ─────────────────────────────
  final ArgusXWebSocketService _ws = ArgusXWebSocketService();
  StreamSubscription<ArgusXPulseResponse>? _wsSub;
  StreamSubscription<WsConnectionState>? _wsStateSub;
  WsConnectionState _wsState = WsConnectionState.disconnected;
  bool _isLiveMode = false;
  // Android emulator → 10.0.2.2 reaches host localhost.
  // Real device on same WiFi → replace with your PC's LAN IP.
  String _serverUrl = 'ws://10.0.2.2:8000/ws/pulse';

  // ── Safety Pulse Lifecycle / Activity Model (PRD §7) ──────────────
  int _activePipelineStep = 0;
  final List<String> _pipelineSteps = [
    'FRAME_CAPTURE (Flutter)',
    'INGRESS_STREAM (FastAPI)',
    'GEMINI_INFERENCE (Gemini Live)',
    'HUD_OVERLAY_ACTION (Flutter HUD)',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Listen to WS connection state so status chip updates reactively.
    _wsStateSub = _ws.connectionState.listen((s) {
      if (mounted) setState(() => _wsState = s);
    });
    // Simulation fallback — only ticks when NOT in live mode.
    _simTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted && !_isLiveMode) {
        setState(() {
          _simSpeed = 40.0 + math.Random().nextDouble() * 25.0;
          _simLat += (math.Random().nextDouble() - 0.5) * 0.0002;
          _simLng += (math.Random().nextDouble() - 0.5) * 0.0002;
          final randInt = math.Random().nextInt(1000000);
          _simFrameHash = 'f${randInt.toRadixString(16).padLeft(6, '0')}';
          _activePipelineStep = (_activePipelineStep + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _wsSub?.cancel();
    _wsStateSub?.cancel();
    _ws.dispose();
    super.dispose();
  }

  void _setHudState(HudState s) {
    setState(() {
      _hudState = s;
      _uiCommands = switch (s) {
        HudState.standby      => [],
        HudState.sentryActive => ['ACTIVATE_SENTRY_VISION'],
        HudState.hazardAlert  => ['TRIGGER_HUD_ALERTS', 'PRUNE_NON_ESSENTIAL_WIDGETS'],
        HudState.navigation   => ['ENGAGE_NAV_OVERLAY'],
      };
      if (s == HudState.hazardAlert) _threatLevel = ThreatLevel.warning;
      if (s == HudState.standby)     _threatLevel = ThreatLevel.normal;
    });
  }

  void _setThreat(ThreatLevel t) => setState(() => _threatLevel = t);

  // ── Live backend integration ──────────────────────────────────────
  Future<void> _toggleLiveMode() async {
    if (_isLiveMode) {
      await _ws.disconnect();
      if (mounted) setState(() => _isLiveMode = false);
    } else {
      if (mounted) setState(() => _isLiveMode = true);
      await _ws.connect(_serverUrl);
      await _wsSub?.cancel();
      _wsSub = _ws.responses.listen(_applyBackendResponse);
    }
  }

  /// Maps a backend response packet to local HUD state.
  void _applyBackendResponse(ArgusXPulseResponse r) {
    if (!mounted) return;
    setState(() {
      _threatLevel = switch (r.threatLevel) {
        'WARNING'  => ThreatLevel.warning,
        'CRITICAL' => ThreatLevel.critical,
        _          => ThreatLevel.normal,
      };
      _hudState = switch (r.hudMode) {
        'Standby'      => HudState.standby,
        'Hazard_Alert' => HudState.hazardAlert,
        'Navigation'   => HudState.navigation,
        _              => HudState.sentryActive,
      };
      _uiCommands = r.uiCommands;
      _activePipelineStep = (_activePipelineStep + 1) % 4;
      if (r.enrichedContext.isNotEmpty) {
        _simFrameHash = r.enrichedContext.substring(
            0, r.enrichedContext.length.clamp(0, 8));
      }
    });
    // Keep the loop alive — send fresh telemetry back.
    _ws.sendTelemetry(speed: _simSpeed, lat: _simLat, lng: _simLng);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const activeColor = Color(0xFFDDB7FF);
    const glowColor = Color(0xFF8E2DE2);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MISSION CONTROL header
          Text(
            'MISSION CONTROL',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFFE5E2E3),
              fontSize: 28.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'NODE ALPHA // SECTOR 7G // ACTIVE',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF998CA0),
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16.0),

          // Nominals & Status Row
          Row(
            children: [
              // Chip 1: SYS.NOMINAL
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF131314).withValues(alpha: 0.8),
                  border: Border.all(
                    color: const Color(0xFF353436),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 6.0,
                      width: 6.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676), // Nominal Green — square per design.md
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00E676),
                            blurRadius: 4.0,
                            spreadRadius: 1.0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'SYS.NOMINAL',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF00E676),
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              // Chip 2: Live WS connection status
              GestureDetector(
                onTap: _toggleLiveMode,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131314).withValues(alpha: 0.8),
                    border: Border.all(
                      color: _wsState == WsConnectionState.connected
                          ? const Color(0xFF00E5FF)
                          : _wsState == WsConnectionState.connecting
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFF353436),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _wsState == WsConnectionState.connected
                            ? Icons.wifi_tethering
                            : _wsState == WsConnectionState.connecting
                                ? Icons.wifi_find
                                : Icons.wifi_off,
                        color: _wsState == WsConnectionState.connected
                            ? const Color(0xFF00E5FF)
                            : _wsState == WsConnectionState.connecting
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFF998CA0),
                        size: 12.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        _wsState == WsConnectionState.connected
                            ? 'LIVE'
                            : _wsState == WsConnectionState.connecting
                                ? 'LINKING...'
                                : _isLiveMode ? 'WS_ERR' : 'SIM',
                        style: GoogleFonts.spaceGrotesk(
                          color: _wsState == WsConnectionState.connected
                              ? const Color(0xFF00E5FF)
                              : _wsState == WsConnectionState.connecting
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFF998CA0),
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // ── BACKEND CONNECTION PANEL ──────────────────────────────
          TechPanel(
            padding: const EdgeInsets.all(12.0),
            borderColor: _wsState == WsConnectionState.connected
                ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                : const Color(0xFF353436),
            bracketColor: _wsState == WsConnectionState.connected
                ? const Color(0xFF00E5FF)
                : const Color(0xFF4D4354),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BACKEND.LINK',
                      style: GoogleFonts.spaceGrotesk(
                        color: _wsState == WsConnectionState.connected
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF4D4354),
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleLiveMode,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: _isLiveMode
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.1)
                              : const Color(0xFF353436).withValues(alpha: 0.3),
                          border: Border.all(
                            color: _isLiveMode
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFF4D4354),
                          ),
                        ),
                        child: Text(
                          _isLiveMode ? 'DISCONNECT' : 'CONNECT',
                          style: GoogleFonts.spaceGrotesk(
                            color: _isLiveMode
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFF998CA0),
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  color: const Color(0xFF09090A),
                  child: Text(
                    _serverUrl,
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF4D4354),
                      fontSize: 9.0,
                    ),
                  ),
                ),
                if (_wsState == WsConnectionState.error) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    'ERR: Could not reach backend. Running in SIM mode.',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFFFF5252),
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // ── ARGUS RING — PRD §5.1 Central HUD Iris ─────────────────
          TechPanel(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            borderColor: _threatLevel.primaryColor.withValues(alpha: 0.35),
            bracketColor: _threatLevel.glowColor.withValues(alpha: 0.6),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ARGUS.IRIS', style: GoogleFonts.spaceGrotesk(
                      color: _threatLevel.primaryColor, fontSize: 12.0,
                      fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    // Threat level chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: _threatLevel.primaryColor, width: 1.0),
                        color: _threatLevel.glowColor.withValues(alpha: 0.1),
                      ),
                      child: Text(_threatLevel.label, style: GoogleFonts.spaceGrotesk(
                        color: _threatLevel.primaryColor, fontSize: 9.0,
                        fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Center(
                  child: ArgusRing(
                    threatLevel: _threatLevel,
                    hudState: _hudState,
                    size: 220.0,
                  ),
                ),
                const SizedBox(height: 20.0),
                // ── HUD State Machine buttons (PRD §7) ─────────────────
                Text('HUD STATE MACHINE', style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF4D4354), fontSize: 9.0,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    _StateBtn('STANDBY',    HudState.standby,      _hudState, _setHudState),
                    const SizedBox(width: 4.0),
                    _StateBtn('SENTRY',     HudState.sentryActive,  _hudState, _setHudState),
                    const SizedBox(width: 4.0),
                    _StateBtn('HAZARD',     HudState.hazardAlert,   _hudState, _setHudState),
                    const SizedBox(width: 4.0),
                    _StateBtn('NAV',        HudState.navigation,    _hudState, _setHudState),
                  ],
                ),
                const SizedBox(height: 12.0),
                // ── Threat Level buttons (PRD §6.1) ────────────────────
                Text('THREAT LEVEL', style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF4D4354), fontSize: 9.0,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    _ThreatBtn('NORMAL',   ThreatLevel.normal,   _threatLevel, _setThreat, const Color(0xFF00E676)),
                    const SizedBox(width: 4.0),
                    _ThreatBtn('WARNING',  ThreatLevel.warning,  _threatLevel, _setThreat, const Color(0xFFFFB74D)),
                    const SizedBox(width: 4.0),
                    _ThreatBtn('CRITICAL', ThreatLevel.critical, _threatLevel, _setThreat, const Color(0xFFFF5252)),
                  ],
                ),
                // ── Active UI commands (PRD §6.1 outbound schema) ─────
                if (_uiCommands.isNotEmpty) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF353436)),
                      color: const Color(0xFF0E0E0F),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACTIVE UI_COMMANDS', style: GoogleFonts.spaceMono(
                          color: const Color(0xFF4D4354), fontSize: 8.0, letterSpacing: 1.0)),
                        const SizedBox(height: 6.0),
                        ..._uiCommands.map((cmd) => Padding(
                          padding: const EdgeInsets.only(bottom: 3.0),
                          child: Row(
                            children: [
                              Container(width: 4, height: 4, color: activeColor),
                              const SizedBox(width: 6.0),
                              Text(cmd, style: GoogleFonts.spaceMono(
                                color: activeColor, fontSize: 9.0,
                                fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          const SizedBox(height: 8.0),

          // -- MODULES BLOCKS --

          // 1. DATA.LINK Panel
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            bracketColor: glowColor.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DATA.LINK',
                      style: GoogleFonts.spaceGrotesk(
                        color: activeColor,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.dns_outlined, color: Color(0xFF998CA0), size: 16.0),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Supabase I/O',
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF4D4354),
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '14.2',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFFE5E2E3),
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'ms',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF998CA0),
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Small visual bar chart
                    const Row(
                      children: [
                        _MiniBar(height: 12.0, opacity: 0.3),
                        SizedBox(width: 4.0),
                        _MiniBar(height: 24.0, opacity: 0.5),
                        SizedBox(width: 4.0),
                        _MiniBar(height: 16.0, opacity: 0.4),
                        SizedBox(width: 4.0),
                        _MiniBar(height: 32.0, opacity: 0.9),
                        SizedBox(width: 4.0),
                        _MiniBar(height: 8.0, opacity: 0.2),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 2. CORE.API Panel
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            bracketColor: glowColor.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CORE.API',
                      style: GoogleFonts.spaceGrotesk(
                        color: activeColor,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.gps_fixed_outlined, color: Color(0xFF998CA0), size: 16.0),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    // Green check badge
                    Container(
                      height: 32.0,
                      width: 32.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E0E0F),
                        border: Border.all(
                          color: const Color(0xFF00E676),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          color: Color(0xFF00E676),
                          size: 16.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PYTHON_V3.11',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFFE5E2E3),
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'OPERATIONAL',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF00E676),
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

           // 3. EVENT.LOG Panel
          const TechPanel(
            padding: EdgeInsets.all(16.0),
            child: EventLogPanel(),
          ),
          const SizedBox(height: 16.0),

          // ── INBOUND.STREAM Console (PRD §6.1 Schema) ────────────────
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            borderColor: activeColor.withValues(alpha: 0.35),
            bracketColor: const Color(0xFF00E5FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INBOUND.STREAM',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF00E5FF),
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6.0,
                          height: 6.0,
                          color: const Color(0xFF00E5FF),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          'WS // LIVE_PULSE',
                          style: GoogleFonts.spaceMono(
                            color: const Color(0xFF00E5FF),
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                // Code block console
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09090A),
                    border: Border.all(color: const Color(0xFF353436)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '{',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF998CA0),
                          fontSize: 10.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('"speed": ', style: GoogleFonts.spaceMono(color: const Color(0xFF998CA0), fontSize: 10.0)),
                                Text('${_simSpeed.toStringAsFixed(2)},', style: GoogleFonts.spaceMono(color: const Color(0xFF00E676), fontSize: 10.0, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                Text('"coordinates": {', style: GoogleFonts.spaceMono(color: const Color(0xFF998CA0), fontSize: 10.0)),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('"lat": ', style: GoogleFonts.spaceMono(color: const Color(0xFF998CA0), fontSize: 10.0)),
                                      Text('${_simLat.toStringAsFixed(6)},', style: GoogleFonts.spaceMono(color: const Color(0xFFDDB7FF), fontSize: 10.0)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text('"lng": ', style: GoogleFonts.spaceMono(color: const Color(0xFF998CA0), fontSize: 10.0)),
                                      Text('${_simLng.toStringAsFixed(6)}', style: GoogleFonts.spaceMono(color: const Color(0xFFDDB7FF), fontSize: 10.0)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text('},', style: GoogleFonts.spaceMono(color: const Color(0xFF998CA0), fontSize: 10.0)),
                            Row(
                              children: [
                                Text('"frame_data": ', style: GoogleFonts.spaceMono(color: const Color(0xFF998CA0), fontSize: 10.0)),
                                Text('"/9j/4AAQSkZJRgABAQAAAQABAAD/2wBD...${_simFrameHash}"', style: GoogleFonts.spaceMono(color: const Color(0xFFFFB74D), fontSize: 9.0)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '}',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF998CA0),
                          fontSize: 10.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // ── ACTIVITY MODEL / SAFETY PULSE LIFECYCLE (PRD §7) ────────
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            borderColor: activeColor.withValues(alpha: 0.35),
            bracketColor: activeColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAFETY.PULSE.LIFECYCLE',
                  style: GoogleFonts.spaceGrotesk(
                    color: activeColor,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'PRD §7 Activity Model: Deterministic time-critical flow of a single frame.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4D4354),
                    fontSize: 10.0,
                  ),
                ),
                const SizedBox(height: 16.0),
                // Pipeline Steps
                Column(
                  children: List.generate(_pipelineSteps.length, (index) {
                    final isActive = _activePipelineStep == index;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isActive
                                ? activeColor.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border.all(
                              color: isActive ? activeColor : const Color(0xFF353436),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8.0,
                                height: 8.0,
                                color: isActive ? activeColor : const Color(0xFF353436),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Text(
                                  'STEP 0${index + 1} // ${_pipelineSteps[index]}',
                                  style: GoogleFonts.spaceMono(
                                    color: isActive ? Colors.white : const Color(0xFF998CA0),
                                    fontSize: 9.5,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (isActive)
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 14.0,
                                ),
                            ],
                          ),
                        ),
                        if (index < _pipelineSteps.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 14.0),
                            child: CustomPaint(
                              size: const Size(1, 15),
                              painter: _DottedLinePainter(
                                color: isActive ? activeColor : const Color(0xFF353436),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 4. THROUGHPUT Centerpiece
          TechPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            borderColor: activeColor.withValues(alpha: 0.3),
            bracketColor: activeColor,
            child: Column(
              children: [
                const CircularGauge(
                  value: 94.2,
                  maxValue: 100.0,
                  label: 'Throughput',
                  unit: 'TB/s',
                ),
                const SizedBox(height: 24.0),
                // High-tech internal divider
                Container(
                  height: 1.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4D4354).withValues(alpha: 0.1),
                        const Color(0xFF4D4354).withValues(alpha: 0.4),
                        const Color(0xFF4D4354).withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TelemetryItem(label: 'CPU LOAD', value: '42%', color: const Color(0xFFE5E2E3)),
                    // vertical thin tech divider
                    Container(height: 24.0, width: 1.0, color: const Color(0xFF353436)),
                    _TelemetryItem(label: 'MEM USAGE', value: '68%', color: const Color(0xFFE5E2E3)),
                    // vertical thin tech divider
                    Container(height: 24.0, width: 1.0, color: const Color(0xFF353436)),
                    _TelemetryItem(label: 'TEMP', value: '74°C', color: const Color(0xFFFFB872)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 5. TACTICAL.CMD Panel
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TACTICAL.CMD',
                  style: GoogleFonts.spaceGrotesk(
                    color: activeColor,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16.0),
                // Execute Purge Solid Button
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.bolt, color: Colors.white, size: 16.0),
                  label: Text(
                    'EXECUTE PURGE',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 13.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: glowColor,
                    minimumSize: const Size(double.infinity, 48.0),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Cyberpunk sharp edge
                    ),
                    elevation: 4.0,
                    shadowColor: glowColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12.0),
                // Recalibrate Ghost Button
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.refresh, color: activeColor, size: 16.0),
                  label: Text(
                    'RECALIBRATE',
                    style: GoogleFonts.spaceGrotesk(
                      color: activeColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 13.0,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: activeColor, width: 1.0),
                    minimumSize: const Size(double.infinity, 48.0),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 6. NET.TOPOLOGY Panel
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NET.TOPOLOGY',
                  style: GoogleFonts.spaceGrotesk(
                    color: activeColor,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16.0),
                // schematic visual container
                Container(
                  height: 150.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0E0F),
                    border: Border.all(
                      color: const Color(0xFF353436),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRect(
                    child: CustomPaint(
                      painter: _TopologyPainter(glowColor: glowColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mini-bar graphic component for stats links
class _MiniBar extends StatelessWidget {
  final double height;
  final double opacity;

  const _MiniBar({required this.height, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: 6.0,
      decoration: BoxDecoration(
        color: const Color(0xFFDDB7FF).withValues(alpha: opacity),
        // 0px border-radius per design.md §Shapes
      ),
    );
  }
}

// Telemetry Item Widget (CPU/MEM/TEMP statistics)
class _TelemetryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF4D4354),
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: color,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Custom Painter to draw vector schematic lines representing a high-tech network topology map
class _TopologyPainter extends CustomPainter {
  final Color glowColor;

  _TopologyPainter({required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF4D4354).withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final glowLinePaint = Paint()
      ..color = glowColor.withValues(alpha: 0.15)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = const Color(0xFF353436)
      ..style = PaintingStyle.fill;

    final activeNodePaint = Paint()
      ..color = const Color(0xFFDDB7FF)
      ..style = PaintingStyle.fill;

    final activeNodeGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Node locations
    final Offset node1 = Offset(size.width * 0.15, size.height * 0.5);
    final Offset node2 = Offset(size.width * 0.45, size.height * 0.3);
    final Offset node3 = Offset(size.width * 0.45, size.height * 0.7);
    final Offset node4 = Offset(size.width * 0.8, size.height * 0.5);

    // Draw connecting schematic paths (lines)
    canvas.drawLine(node1, node2, linePaint);
    canvas.drawLine(node1, node3, linePaint);
    canvas.drawLine(node2, node4, glowLinePaint);
    canvas.drawLine(node3, node4, linePaint);
    canvas.drawLine(node2, node3, linePaint);

    // Draw standard circles representing passive nodes
    canvas.drawCircle(node1, 4.0, nodePaint);
    canvas.drawCircle(node3, 4.0, nodePaint);

    // Draw active glowing circles representing active nodes
    canvas.drawCircle(node2, 5.0, activeNodeGlowPaint);
    canvas.drawCircle(node2, 4.0, activeNodePaint);

    canvas.drawCircle(node4, 5.0, activeNodeGlowPaint);
    canvas.drawCircle(node4, 4.0, activeNodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── HUD State Machine button (PRD §7) ─────────────────────────────────
class _StateBtn extends StatelessWidget {
  final String label;
  final HudState state;
  final HudState current;
  final ValueChanged<HudState> onTap;

  const _StateBtn(this.label, this.state, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isActive = state == current;
    const activeColor = Color(0xFFDDB7FF);
    const glowColor = Color(0xFF8E2DE2);
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(state),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isActive ? glowColor.withValues(alpha: 0.25) : Colors.transparent,
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFF353436),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? activeColor : const Color(0xFF4D4354),
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ),
      ),
    );
  }
}

// ── Threat Level button (PRD §6.1) ────────────────────────────────────
class _ThreatBtn extends StatelessWidget {
  final String label;
  final ThreatLevel level;
  final ThreatLevel current;
  final ValueChanged<ThreatLevel> onTap;
  final Color color;

  const _ThreatBtn(this.label, this.level, this.current, this.onTap, this.color);

  @override
  Widget build(BuildContext context) {
    final isActive = level == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: isActive ? color : const Color(0xFF353436),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? color : const Color(0xFF4D4354),
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dotted line painter for Safety Pulse Lifecycle steps ───────────
class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + 3),
        paint,
      );
      startY += 6;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

