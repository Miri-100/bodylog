
import 'package:supabase_flutter/supabase_flutter.dart';

class GoalService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get _user => _client.auth.currentUser;

  Future<List<Map<String, dynamic>>> getGoals() async {
    final user = _user;
    if (user == null) throw Exception('User not logged in');

    final data = await _client
        .from('goals')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addGoal({
    required String goalType,
    required double targetValue,
    DateTime? startDate,
    DateTime? endDate,
    String status = 'active',
  }) async {
    final user = _user;
    if (user == null) throw Exception('User not logged in');

    await _client.from('goals').insert({
      'user_id': user.id,
      'goal_type': goalType,
      'target_value': targetValue,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'status': status,
    });
  }

  Future<void> updateGoal({
    required int id,
    required String goalType,
    required double targetValue,
    DateTime? startDate,
    DateTime? endDate,
    required String status,
  }) async {
    await _client.from('goals').update({
      'goal_type': goalType,
      'target_value': targetValue,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteGoal(int id) async {
    await _client.from('goals').delete().eq('id', id);
  }

  Future<double> calculateCurrentProgress(String goalType) async {
    final user = _user;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    if (goalType == 'workouts_per_week') {
      final workouts = await _client
          .from('workouts')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', weekStart.toIso8601String());

      return (workouts as List).length.toDouble();
    }

    if (goalType == 'calories_per_week') {
      final workouts = await _client
          .from('workouts')
          .select('calories')
          .eq('user_id', user.id)
          .gte('created_at', weekStart.toIso8601String());

      double total = 0;
      for (final row in workouts) {
        total += ((row['calories'] ?? 0) as num).toDouble();
      }
      return total;
    }

    if (goalType == 'minutes_per_week') {
      final workouts = await _client
          .from('workouts')
          .select('duration')
          .eq('user_id', user.id)
          .gte('created_at', weekStart.toIso8601String());

      double total = 0;
      for (final row in workouts) {
        total += ((row['duration'] ?? 0) as num).toDouble();
      }
      return total;
    }

    if (goalType == 'weight_target') {
      final profile = await _client
          .from('profiles')
          .select('weight_kg')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return 0;
      return ((profile['weight_kg'] ?? 0) as num).toDouble();
    }

    return 0;
  }
}
