import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Connection state for the ArgusX Safety Pulse WebSocket.
enum WsConnectionState { disconnected, connecting, connected, error }

/// Parsed outbound packet from the FastAPI backend (PRD §6.1).
class ArgusXPulseResponse {
  final String threatLevel;   // "NORMAL" | "WARNING" | "CRITICAL"
  final String hudMode;       // "Standby" | "Sentry_Active" | "Hazard_Alert" | "Navigation"
  final List<String> uiCommands;
  final String enrichedContext;
  final Map<String, dynamic> navigation;
  final List<dynamic> pinnedPois;

  const ArgusXPulseResponse({
    required this.threatLevel,
    required this.hudMode,
    required this.uiCommands,
    required this.enrichedContext,
    required this.navigation,
    required this.pinnedPois,
  });

  factory ArgusXPulseResponse.fromJson(Map<String, dynamic> json) {
    return ArgusXPulseResponse(
      threatLevel: (json['threat_level'] as String? ?? 'NORMAL').toUpperCase(),
      hudMode: json['hud_mode'] as String? ?? 'Sentry_Active',
      uiCommands: List<String>.from(json['ui_commands'] as List? ?? []),
      enrichedContext: json['enriched_context'] as String? ?? '',
      navigation: Map<String, dynamic>.from(json['navigation'] as Map? ?? {}),
      pinnedPois: List<dynamic>.from(json['pinned_pois'] as List? ?? []),
    );
  }
}

/// Manages the bi-directional WebSocket connection to the FastAPI
/// Safety Pulse endpoint (`ws://<host>/ws/pulse`).
///
/// Usage:
/// ```dart
/// final svc = ArgusXWebSocketService();
/// svc.connect('ws://192.168.1.10:8000/ws/pulse');
/// svc.responses.listen((r) { ... });
/// svc.sendTelemetry(speed: 55.0, lat: 24.86, lng: 67.01);
/// svc.disconnect();
/// ```
class ArgusXWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _responseController =
      StreamController<ArgusXPulseResponse>.broadcast();
  final _stateController =
      StreamController<WsConnectionState>.broadcast();

  /// Emits every decoded backend response packet.
  Stream<ArgusXPulseResponse> get responses => _responseController.stream;

  /// Emits connection lifecycle state changes.
  Stream<WsConnectionState> get connectionState => _stateController.stream;

  WsConnectionState _currentState = WsConnectionState.disconnected;
  WsConnectionState get state => _currentState;

  void _setState(WsConnectionState s) {
    _currentState = s;
    _stateController.add(s);
  }

  /// Opens a connection to [uri] (e.g. `ws://192.168.1.10:8000/ws/pulse`).
  /// Safe to call multiple times — disconnects any previous channel first.
  Future<void> connect(String uri) async {
    await disconnect();
    _setState(WsConnectionState.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(uri));
      // Wait for the underlying socket to be ready.
      await _channel!.ready;
      _setState(WsConnectionState.connected);

      _sub = _channel!.stream.listen(
        (raw) {
          try {
            final json = jsonDecode(raw as String) as Map<String, dynamic>;
            _responseController.add(ArgusXPulseResponse.fromJson(json));
          } catch (_) {
            // Malformed frame — ignore, keep connection alive.
          }
        },
        onError: (_) => _setState(WsConnectionState.error),
        onDone: () => _setState(WsConnectionState.disconnected),
        cancelOnError: false,
      );
    } catch (_) {
      _setState(WsConnectionState.error);
    }
  }

  /// Sends a telemetry frame to the backend.
  /// [frameData] is an optional base64-encoded JPEG string.
  void sendTelemetry({
    required double speed,
    required double lat,
    required double lng,
    String frameData = '',
    String sessionId = 'flutter-session',
    String riderId = 'operator-01',
  }) {
    if (_currentState != WsConnectionState.connected) return;
    final payload = jsonEncode({
      'speed': speed,
      'coordinates': {'lat': lat, 'lng': lng},
      'frame_data': frameData,
      'session_id': sessionId,
      'rider_id': riderId,
    });
    try {
      _channel?.sink.add(payload);
    } catch (_) {
      _setState(WsConnectionState.error);
    }
  }

  /// Closes the WebSocket connection gracefully.
  Future<void> disconnect() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _sub = null;
    _channel = null;
    _setState(WsConnectionState.disconnected);
  }

  /// Must be called when the owning widget is disposed.
  Future<void> dispose() async {
    await disconnect();
    await _responseController.close();
    await _stateController.close();
  }
}
