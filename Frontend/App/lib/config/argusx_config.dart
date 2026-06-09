/// Runtime configuration via --dart-define flags.
class ArgusXConfig {
  static const wsUrl = String.fromEnvironment(
    'ARGUSX_WS_URL',
    defaultValue: 'ws://10.0.2.2:8000/ws/pulse',
  );

  static const apiUrl = String.fromEnvironment(
    'ARGUSX_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const supabaseUrl = String.fromEnvironment(
    'ARGUSX_SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'ARGUSX_SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
