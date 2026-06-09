import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/argusx_config.dart';

class ArgusXAuthService {
  bool get isConfigured => ArgusXConfig.isSupabaseConfigured;

  SupabaseClient? get _client =>
      isConfigured ? Supabase.instance.client : null;

  User? get currentUser => _client?.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  String get riderId => currentUser?.id ?? 'anonymous';

  Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: ArgusXConfig.supabaseUrl,
      anonKey: ArgusXConfig.supabaseAnonKey,
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured. Set ARGUSX_SUPABASE_URL and ARGUSX_SUPABASE_ANON_KEY.');
    }
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured.');
    }
    await client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }
}
