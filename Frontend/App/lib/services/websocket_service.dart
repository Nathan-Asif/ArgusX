import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/argusx_config.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _threatLevel = 'NORMAL';
  List<String> _uiCommands = [];
  String _enrichedContext = 'System initialized. Scanning...';

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get threatLevel => _threatLevel;
  List<String> get uiCommands => _uiCommands;
  String get enrichedContext => _enrichedContext;

  void connect() {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(ArgusXConfig.wsPulseUrl));

      _subscription = _channel!.stream.listen(
        _parseMessage,
        onError: (_) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
      );

      // Mark connected once the socket handshake completes, then send heartbeat.
      _channel!.ready.then((_) {
        _isConnecting = false;
        _isConnected = true;
        notifyListeners();
        sendTelemetry(0.0, 37.7749, -122.4194);
      }).catchError((_) {
        _handleDisconnect();
      });
    } catch (e) {
      _handleDisconnect();
    }
  }

  void sendTelemetry(double speed, double lat, double lng) {
    if (_channel == null || !_isConnected) return;

    final payload = {
      'speed': speed,
      'coordinates': {'lat': lat, 'lng': lng},
      'frame_data':
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    };

    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _parseMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message as String);
      _threatLevel = data['threat_level']?.toString() ?? 'NORMAL';

      final commands = data['ui_commands'];
      if (commands is List) {
        _uiCommands = commands.map((c) => c.toString()).toList();
      } else {
        _uiCommands = [];
      }

      _enrichedContext =
          data['enriched_context']?.toString() ?? 'Safety corridor verified.';
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void _handleDisconnect() {
    _subscription?.cancel();
    _subscription = null;
    _isConnected = false;
    _isConnecting = false;
    _channel = null;
    notifyListeners();
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _handleDisconnect();
  }

  void simulateThreatChange(String level, String context) {
    _threatLevel = level;
    _enrichedContext = context;
    notifyListeners();
  }
}
