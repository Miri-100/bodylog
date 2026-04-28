import 'dart:typed_data';
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

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileExt,
  }) async {
    final user = _user;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final fileName =
        'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'users/${user.id}/$fileName';

    await _client.storage.from('avatars').uploadBinary(
      filePath,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    return _client.storage.from('avatars').getPublicUrl(filePath);
  }

  Future<void> updateProfile({
    required String username,
    String? fullName,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? avatarUrl,
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
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }
}
