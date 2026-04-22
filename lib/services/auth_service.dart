import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
    );

    final user = response.user;
    final session = response.session;

    if (user == null) {
      throw Exception('Signup failed');
    }

    if (session == null) {
      throw Exception(
        'Signup succeeded, but no active session. Turn off email confirmation in Supabase for testing first.',
      );
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'username': username.trim(),
      'email': email.trim(),
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}
