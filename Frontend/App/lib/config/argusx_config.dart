/// Runtime configuration via --dart-define flags.
///
/// Production defaults target the live VPS API. For local dev override:
///   flutter run --dart-define=ARGUSX_API_URL=http://127.0.0.1:8000 \
///               --dart-define=ARGUSX_WS_URL=ws://127.0.0.1:8000/ws/pulse
/// Android emulator: use http://10.0.2.2:8000 and ws://10.0.2.2:8000/ws/pulse
class ArgusXConfig {
  static const wsUrl = String.fromEnvironment(
    'ARGUSX_WS_URL',
    defaultValue: 'wss://argusx-api.codemelodies.com/ws/pulse',
  );

  static const apiUrl = String.fromEnvironment(
    'ARGUSX_API_URL',
    defaultValue: 'https://argusx-api.codemelodies.com',
  );

  static const supabaseUrl = String.fromEnvironment(
    'ARGUSX_SUPABASE_URL',
    defaultValue: 'https://gghskxggmncepmecssvv.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'ARGUSX_SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_nQKdPcZOsgHwtfKWaSpCrg_ujLnrEOk',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
