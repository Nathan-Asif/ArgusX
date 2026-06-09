import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WsConnectionState { disconnected, connecting, connected, error }

class ArgusXPulseResponse {
  final String threatLevel;
  final String hudMode;
  final List<String> uiCommands;
  final String enrichedContext;
  final Map<String, dynamic> navigation;
  final List<dynamic> pinnedPois;
  final List<dynamic> hazards;
  final Map<String, dynamic>? destination;
  final Map<String, dynamic> routeVisualization;

  const ArgusXPulseResponse({
    required this.threatLevel,
    required this.hudMode,
    required this.uiCommands,
    required this.enrichedContext,
    required this.navigation,
    required this.pinnedPois,
    required this.hazards,
    this.destination,
    required this.routeVisualization,
  });

  factory ArgusXPulseResponse.fromJson(Map<String, dynamic> json) {
    return ArgusXPulseResponse(
      threatLevel: (json['threat_level'] as String? ?? 'NORMAL').toUpperCase(),
      hudMode: json['hud_mode'] as String? ?? 'Sentry_Active',
      uiCommands: List<String>.from(json['ui_commands'] as List? ?? []),
      enrichedContext: json['enriched_context'] as String? ?? '',
      navigation: Map<String, dynamic>.from(json['navigation'] as Map? ?? {}),
      pinnedPois: List<dynamic>.from(json['pinned_pois'] as List? ?? []),
      hazards: List<dynamic>.from(json['hazards'] as List? ?? []),
      destination: json['destination'] as Map<String, dynamic>?,
      routeVisualization:
          Map<String, dynamic>.from(json['route_visualization'] as Map? ?? {}),
    );
  }
}

class ArgusXWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _responseController = StreamController<ArgusXPulseResponse>.broadcast();
  final _stateController = StreamController<WsConnectionState>.broadcast();

  Stream<ArgusXPulseResponse> get responses => _responseController.stream;
  Stream<WsConnectionState> get connectionState => _stateController.stream;

  WsConnectionState _currentState = WsConnectionState.disconnected;
  WsConnectionState get state => _currentState;

  void _setState(WsConnectionState s) {
    _currentState = s;
    _stateController.add(s);
  }

  Future<void> connect(String uri) async {
    await disconnect();
    _setState(WsConnectionState.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(uri));
      await _channel!.ready;
      _setState(WsConnectionState.connected);

      _sub = _channel!.stream.listen(
        (raw) {
          try {
            final json = jsonDecode(raw as String) as Map<String, dynamic>;
            _responseController.add(ArgusXPulseResponse.fromJson(json));
          } catch (_) {}
        },
        onError: (_) => _setState(WsConnectionState.error),
        onDone: () => _setState(WsConnectionState.disconnected),
        cancelOnError: false,
      );
    } catch (_) {
      _setState(WsConnectionState.error);
    }
  }

  void sendPulse({
    required double speed,
    required double lat,
    required double lng,
    String frameData = '',
    String sessionId = 'flutter-session',
    String riderId = 'operator-01',
    Map<String, dynamic>? destination,
    Map<String, dynamic>? routeContext,
    Map<String, dynamic>? routeVisualization,
    int routeStepIndex = 0,
  }) {
    if (_currentState != WsConnectionState.connected) return;

    final payload = <String, dynamic>{
      'speed': speed,
      'coordinates': {'lat': lat, 'lng': lng},
      'frame_data': frameData,
      'session_id': sessionId,
      'rider_id': riderId,
    };
    if (destination != null) payload['destination'] = destination;
    if (routeContext != null) payload['route_context'] = routeContext;
    if (routeVisualization != null) {
      payload['route_visualization'] = routeVisualization;
    }
    if (routeStepIndex > 0) payload['route_step_index'] = routeStepIndex;

    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (_) {
      _setState(WsConnectionState.error);
    }
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _sub = null;
    _channel = null;
    _setState(WsConnectionState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _responseController.close();
    await _stateController.close();
  }
}
