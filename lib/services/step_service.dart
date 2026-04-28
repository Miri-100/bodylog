import 'package:supabase_flutter/supabase_flutter.dart';

class StepService {
  final _supabase = Supabase.instance.client;

  // --- THE LIVE STREAM ---
  Stream<int> getStepsStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(0);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    return _supabase
        .from('steps')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((list) {
      final todayRow = list.firstWhere(
            (row) => row['step_date'].toString().contains(todayStr),
        orElse: () => {'step_count': 0},
      );
      return todayRow['step_count'] as int;
    });
  }

  Future<int> getTodaySteps() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final res = await _supabase.from('steps').select().eq('user_id', user.id).eq('step_date', today).maybeSingle();
    return res != null ? (res['step_count'] as int) : 0;
  }

  // FIX: Added onConflict to handle the duplicate key error
  Future<void> updateTodaySteps(int newCount) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];

    await _supabase.from('steps').upsert({
      'user_id': user.id,
      'step_count': newCount,
      'step_date': today,
    }, onConflict: 'user_id,step_date');
  }
}
