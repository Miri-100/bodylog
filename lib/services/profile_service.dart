import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get _user => _client.auth.currentUser;

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _user;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return data;
  }

  Future<void> updateProfile({
    required String username,
    String? fullName,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
  }) async {
    final user = _user;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await _client.from('profiles').update({
      'username': username.trim(),
      'full_name': fullName?.trim().isEmpty ?? true ? null : fullName!.trim(),
      'age': age,
      'gender': gender?.trim().isEmpty ?? true ? null : gender!.trim(),
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }
}
