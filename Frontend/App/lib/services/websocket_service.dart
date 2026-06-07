import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _threatLevel = 'NORMAL';
  List<String> _uiCommands = [];
  String _enrichedContext = 'System initialized. Scanning...';

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get threatLevel => _threatLevel;
  List<String> get uiCommands => _uiCommands;
  String get enrichedContext => _enrichedContext;

  final String _url = 'ws://127.0.0.1:8000/ws/pulse';

  void connect() {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      
      _channel!.stream.listen(
        (message) {
          _isConnecting = false;
          _isConnected = true;
          _parseMessage(message);
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      // Verify connection by pushing initial heartbeat
      sendTelemetry(0.0, 37.7749, -122.4194);
    } catch (e) {
      _handleDisconnect();
    }
  }

  void sendTelemetry(double speed, double lat, double lng) {
    if (_channel == null || !_isConnected) return;

    final payload = {
      'speed': speed,
      'coordinates': {'lat': lat, 'lng': lng},
      'frame_data': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='
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
      
      _enrichedContext = data['enriched_context']?.toString() ?? 'Safety corridor verified.';
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _channel = null;
    notifyListeners();
  }

  void disconnect() {
    _channel?.sink.close();
    _handleDisconnect();
  }

  // Helper function to force trigger simulated threat levels (useful for stand-alone local runs)
  void simulateThreatChange(String level, String context) {
    _threatLevel = level;
    _enrichedContext = context;
    notifyListeners();
  }
}
