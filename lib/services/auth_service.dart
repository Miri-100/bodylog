import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    bool isAdmin = false,
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
      'is_admin': isAdmin,
    });
  }

  Future<bool> isUserAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final data = await _client.from('profiles').select('is_admin').eq('id', user.id).single();
      return data['is_admin'] == true;
    } catch (_) {
      return false;
    }
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

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Deletes the user profile from the database 
      await _client.from('profiles').delete().eq('id', user.id);
      
      // Call a secure remote procedure (RPC) to delete the actual Auth User via Supbase if set up
      await _client.rpc('delete_user');
    } catch (e) {
      // Ignore RPC error if not yet created in Supabase Dashboard
    }
    
    await signOut();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}
