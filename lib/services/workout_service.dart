import 'package:supabase_flutter/supabase_flutter.dart';

class Workout {
  final int? id;
  final String userId;
  final String name;
  final int duration;
  final int calories;
  final double? distance;
  final double? pace; 
  final DateTime workoutDate;
  final String? notes;

  Workout({
    this.id,
    required this.userId,
    required this.name,
    required this.duration,
    required this.calories,
    this.distance,
    this.pace,
    required this.workoutDate,
    this.notes,
  });

  // UI Helper: Converts stored hr/km back to km/h for the user to see
  String get displaySpeed {
    if (pace != null && pace! > 0) {
      double kmh = 1 / pace!;
      return "${kmh.toStringAsFixed(1)} km/h";
    }
    return "--";
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      duration: map['duration'],
      calories: map['calories'],
      distance: map['distance']?.toDouble(),
      pace: map['pace']?.toDouble(),
      workoutDate: DateTime.parse(map['workout_date']),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'duration': duration,
      'calories': calories,
      'distance': distance,
      'pace': pace,
      'workout_date': workoutDate.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }
}

class WorkoutService {
  final _supabase = Supabase.instance.client;

  Stream<List<Workout>> getWorkoutsStream({bool ascending = false}) {
    return _supabase
        .from('workouts')
        .stream(primaryKey: ['id'])
        .order('workout_date', ascending: ascending)
        .map((maps) => maps.map((map) => Workout.fromMap(map)).toList());
  }

  Future<void> createWorkout(Workout workout) async {
    await _supabase.from('workouts').insert(workout.toMap());
  }

  Future<void> updateWorkout(Workout workout) async {
    if (workout.id == null) return;
    final data = workout.toMap();
    data.remove('id'); // Don't try to update the Primary Key
    await _supabase.from('workouts').update(data).eq('id', workout.id!);
  }

  Future<void> deleteWorkout(int id) async {
    await _supabase.from('workouts').delete().eq('id', id);
  }
}
