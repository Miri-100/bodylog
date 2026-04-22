import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class WorkoutService {
  final SupabaseClient _client = SupabaseService.client;

  User? get _user => _client.auth.currentUser;

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final user = _user;
    if (user == null) return [];

    final data = await _client
        .from('workouts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addWorkout({
    required String name,
    required int duration,
    required int calories,
  }) async {
    final user = _user;
    if (user == null) throw Exception('User not logged in');

    await _client.from('workouts').insert({
      'user_id': user.id,
      'name': name,
      'duration': duration,
      'calories': calories,
    });
  }

  Future<void> updateWorkout({
    required int id,
    required String name,
    required int duration,
    required int calories,
  }) async {
    await _client.from('workouts').update({
      'name': name,
      'duration': duration,
      'calories': calories,
    }).eq('id', id);
  }

  Future<void> deleteWorkout(int id) async {
    await _client.from('workouts').delete().eq('id', id);
  }
}
