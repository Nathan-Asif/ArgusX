import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/tech_panel.dart';
import '../widgets/argus_ring.dart';
import '../config/argus_fonts.dart';
import '../config/argusx_config.dart';
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

  // ── Simulated Inbound Telemetry Stream (PRD §6.1) ─────────────────
  double _simSpeed = 45.2;
  double _simLat = 34.0522;
  double _simLng = -118.2437;
  Timer? _simTimer;

  // ── Live WebSocket Backend Connection ─────────────────────────────
  final ArgusXWebSocketService _ws = ArgusXWebSocketService();
  StreamSubscription<ArgusXPulseResponse>? _wsSub;
  StreamSubscription<WsConnectionState>? _wsStateSub;
  WsConnectionState _wsState = WsConnectionState.disconnected;
  bool _isLiveMode = false;
  final String _serverUrl = ArgusXConfig.wsUrl;
  Timer? _livePulseTimer;

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
        });
      }
    });

    // Auto-connect to live backend stream
    _toggleLiveMode();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _livePulseTimer?.cancel();
    _wsSub?.cancel();
    _wsStateSub?.cancel();
    _ws.dispose();
    super.dispose();
  }

  // ── Live backend integration ──────────────────────────────────────
  Future<void> _toggleLiveMode() async {
    if (_isLiveMode) {
      _livePulseTimer?.cancel();
      await _ws.disconnect();
      if (mounted) setState(() => _isLiveMode = false);
    } else {
      if (mounted) setState(() => _isLiveMode = true);
      try {
        await _ws.connect(_serverUrl);
        await _wsSub?.cancel();
        _wsSub = _ws.responses.listen(_applyBackendResponse);
        _ws.sendPulse(speed: _simSpeed, lat: _simLat, lng: _simLng);
        _livePulseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
          _ws.sendPulse(speed: _simSpeed, lat: _simLat, lng: _simLng);
        });
      } catch (e) {
        debugPrint('WebSocket connection failed: $e');
      }
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
    });
    // Keep the loop alive — send fresh telemetry back.
    _ws.sendPulse(speed: _simSpeed, lat: _simLat, lng: _simLng);
  }

  void _setHudState(HudState state) {
    setState(() {
      _isLiveMode = false;
      _hudState = state;
      if (state == HudState.standby) {
        _simSpeed = 0.0;
      } else if (state == HudState.navigation && _simSpeed == 0.0) {
        _simSpeed = 45.2;
      }
    });
    // Disconnect websocket if we were live
    _ws.disconnect();
    _livePulseTimer?.cancel();
  }

  void _setThreat(ThreatLevel level) {
    setState(() {
      _isLiveMode = false;
      _threatLevel = level;
      if (level == ThreatLevel.critical || level == ThreatLevel.warning) {
        _hudState = HudState.hazardAlert;
      } else if (level == ThreatLevel.normal && _hudState == HudState.hazardAlert) {
        _hudState = HudState.sentryActive;
      }
    });
    // Disconnect websocket if we were live
    _ws.disconnect();
    _livePulseTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final liveColor = _isLiveMode
        ? (_wsState == WsConnectionState.connected
            ? const Color(0xFF00E676)
            : const Color(0xFF00E5FF))
        : const Color(0xFFFFB74D);

    final statusText = _isLiveMode
        ? (_wsState == WsConnectionState.connected
            ? 'LIVE_STREAM'
            : 'CONNECTING')
        : 'SIMULATION';

    final statusIcon = _isLiveMode
        ? (_wsState == WsConnectionState.connected
            ? Icons.sensors_rounded
            : Icons.sync_rounded)
        : Icons.offline_bolt_rounded;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MISSION CONTROL header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MISSION CONTROL',
                    style: ArgusFonts.display(
                      color: const Color(0xFFE5E2E3),
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'NODE ALPHA // ACTIVE',
                    style: ArgusFonts.body(
                      color: const Color(0xFF998CA0),
                      fontSize: 9.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              // Live / Simulator status indicator
              GestureDetector(
                onTap: _toggleLiveMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: liveColor),
                    color: liveColor.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        color: liveColor,
                        size: 11.0,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        statusText,
                        style: ArgusFonts.telemetry(
                          color: liveColor,
                          fontSize: 8.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),

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
                    Text('ARGUS.IRIS', style: ArgusFonts.display(
                      color: _threatLevel.primaryColor, fontSize: 10.0,
                      fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    // Threat level chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: _threatLevel.primaryColor, width: 1.0),
                        color: _threatLevel.glowColor.withValues(alpha: 0.1),
                      ),
                      child: Text(_threatLevel.label, style: ArgusFonts.display(
                        color: _threatLevel.primaryColor, fontSize: 8.0,
                        fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLiveMode = false;
                        final nextState = switch (_hudState) {
                          HudState.standby => HudState.sentryActive,
                          HudState.sentryActive => HudState.hazardAlert,
                          HudState.hazardAlert => HudState.navigation,
                          HudState.navigation => HudState.standby,
                        };
                        _hudState = nextState;
                        if (nextState == HudState.standby) {
                          _simSpeed = 0.0;
                          _threatLevel = ThreatLevel.normal;
                        } else if (nextState == HudState.sentryActive) {
                          _simSpeed = 25.0;
                          _threatLevel = ThreatLevel.normal;
                        } else if (nextState == HudState.hazardAlert) {
                          _simSpeed = 45.0;
                          _threatLevel = ThreatLevel.critical;
                        } else if (nextState == HudState.navigation) {
                          _simSpeed = 65.0;
                          _threatLevel = ThreatLevel.normal;
                        }
                      });
                      _ws.disconnect();
                      _livePulseTimer?.cancel();
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: ArgusRing(
                        threatLevel: _threatLevel,
                        hudState: _hudState,
                        size: 220.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                // ── HUD State Machine buttons (PRD §7) ─────────────────
                Text('HUD STATE MACHINE', style: ArgusFonts.display(
                  color: const Color(0xFF4D4354), fontSize: 8.0,
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
                Text('THREAT LEVEL', style: ArgusFonts.display(
                  color: const Color(0xFF4D4354), fontSize: 8.0,
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
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Clean, high-tech telemetry statistics block for the rider
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            bracketColor: const Color(0xFF8E2DE2).withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TelemetryValue(
                  label: 'SPEED',
                  value: '${_simSpeed.toStringAsFixed(1)} KM/H',
                ),
                Container(height: 32.0, width: 1.0, color: const Color(0xFF353436)),
                _TelemetryValue(
                  label: 'LATITUDE',
                  value: _simLat.toStringAsFixed(4),
                ),
                Container(height: 32.0, width: 1.0, color: const Color(0xFF353436)),
                _TelemetryValue(
                  label: 'LONGITUDE',
                  value: _simLng.toStringAsFixed(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Simulation Controls (active only when in SIMULATION mode)
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            bracketColor: const Color(0xFF00E5FF).withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SIMULATION CONTROLS',
                      style: ArgusFonts.display(
                        color: const Color(0xFFE5E2E3),
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (_isLiveMode)
                      Text(
                        'DISABLED IN LIVE_STREAM',
                        style: ArgusFonts.telemetry(
                          color: const Color(0xFFFFB74D),
                          fontSize: 7.0,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF00E5FF), width: 1.0),
                        ),
                        child: Text(
                          'ACTIVE_OVERRIDE',
                          style: ArgusFonts.telemetry(
                            color: const Color(0xFF00E5FF),
                            fontSize: 7.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  _isLiveMode
                      ? 'Telemetry is currently driven in real-time by the active backend connection.'
                      : 'Manually select local HUD states and threat profiles to test UI responsive layouts.',
                  style: ArgusFonts.body(
                    color: const Color(0xFF998CA0),
                    fontSize: 10.0,
                  ),
                ),
                const SizedBox(height: 16.0),
                
                // HUD Mode
                Text(
                  'HUD STATE',
                  style: ArgusFonts.display(
                    color: const Color(0xFF4D4354),
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: HudState.values.map((state) {
                      final isSelected = _hudState == state;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: _isLiveMode
                              ? null
                              : () {
                                  setState(() {
                                    _hudState = state;
                                    if (state == HudState.standby) {
                                      _simSpeed = 0.0;
                                    } else if (state == HudState.navigation && _simSpeed == 0.0) {
                                      _simSpeed = 45.2;
                                    }
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF8E2DE2).withValues(alpha: 0.15)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFDDB7FF)
                                    : const Color(0xFF353436),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              state.label,
                              style: ArgusFonts.telemetry(
                                color: isSelected
                                    ? const Color(0xFFDDB7FF)
                                    : _isLiveMode
                                        ? const Color(0xFF353436)
                                        : const Color(0xFF998CA0),
                                fontSize: 8.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16.0),
                
                // Threat Level
                Text(
                  'THREAT LEVEL',
                  style: ArgusFonts.display(
                    color: const Color(0xFF4D4354),
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: ThreatLevel.values.map((level) {
                    final isSelected = _threatLevel == level;
                    final color = level.primaryColor;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: _isLiveMode
                            ? null
                            : () {
                                setState(() {
                                  _threatLevel = level;
                                  if (level == ThreatLevel.critical || level == ThreatLevel.warning) {
                                    _hudState = HudState.hazardAlert;
                                  } else if (level == ThreatLevel.normal && _hudState == HudState.hazardAlert) {
                                    _hudState = HudState.sentryActive;
                                  }
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? level.glowColor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : const Color(0xFF353436),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            level.label,
                            style: ArgusFonts.telemetry(
                              color: isSelected
                                  ? color
                                  : _isLiveMode
                                      ? const Color(0xFF353436)
                                      : const Color(0xFF998CA0),
                              fontSize: 8.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryValue extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: ArgusFonts.display(
            color: const Color(0xFF4D4354),
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          value,
          style: ArgusFonts.telemetry(
            color: const Color(0xFFE5E2E3),
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StateBtn extends StatelessWidget {
  final String label;
  final HudState state;
  final HudState currentState;
  final Function(HudState) onTap;

  const _StateBtn(this.label, this.state, this.currentState, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = currentState == state;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(state),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8E2DE2).withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: isSelected ? const Color(0xFFDDB7FF) : const Color(0xFF353436),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: ArgusFonts.telemetry(
                color: isSelected ? const Color(0xFFDDB7FF) : const Color(0xFF998CA0),
                fontSize: 8.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreatBtn extends StatelessWidget {
  final String label;
  final ThreatLevel level;
  final ThreatLevel currentLevel;
  final Function(ThreatLevel) onTap;
  final Color activeColor;

  const _ThreatBtn(this.label, this.level, this.currentLevel, this.onTap, this.activeColor);

  @override
  Widget build(BuildContext context) {
    final isSelected = currentLevel == level;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFF353436),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: ArgusFonts.telemetry(
                color: isSelected ? activeColor : const Color(0xFF998CA0),
                fontSize: 8.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
