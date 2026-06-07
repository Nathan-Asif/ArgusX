/// Centralized ArgusX client configuration for the Flutter HUD.
///
/// Values are resolved from `--dart-define` flags at build/run time, with
/// sensible local defaults. Example:
///
///   flutter run --dart-define=ARGUSX_WS_URL=ws://192.168.1.10:8000/ws/pulse
class ArgusXConfig {
  static const String wsPulseUrl = String.fromEnvironment(
    'ARGUSX_WS_URL',
    defaultValue: 'ws://127.0.0.1:8000/ws/pulse',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'ARGUSX_API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
