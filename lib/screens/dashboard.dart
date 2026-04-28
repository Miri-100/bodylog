import 'package:bodylog/screens/goals.dart';
import 'package:bodylog/screens/health.dart';
import 'package:bodylog/screens/profile.dart';
import 'package:bodylog/screens/progress.dart';
import 'package:bodylog/screens/settings.dart';
import 'package:bodylog/screens/workout.dart';
import 'package:bodylog/services/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class DashboardData {
  final String email;
  final int todayWorkoutCount;
  final int todayCalories;
  final int todayMinutes;
  final int weeklyMinutes;
  final List<double> weeklyDurations;
  final int activeGoals;
  final int completedGoals;
  final double avgGoalProgress;
  final double? bmi;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;

  DashboardData({
    required this.email,
    required this.todayWorkoutCount,
    required this.todayCalories,
    required this.todayMinutes,
    required this.weeklyMinutes,
    required this.weeklyDurations,
    required this.activeGoals,
    required this.completedGoals,
    required this.avgGoalProgress,
    required this.bmi,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
  });
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late Future<DashboardData> _dashboardFuture;

  final SupabaseClient _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      return;
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkoutTimerPage()),
      ).then((_) => _refreshDashboard());
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GoalsPage()),
      ).then((_) => _refreshDashboard());
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      ).then((_) => _refreshDashboard());
    }
  }

  Future<DashboardData> _loadDashboardData() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    Map<String, dynamic>? profile;
    try {
      profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      profile = null;
    }

    final double? heightCm = _toDouble(profile?['height_cm']);
    final double? weightKg = _toDouble(profile?['weight_kg']);
    final int? age = _toInt(profile?['age']);
    final String? gender = profile?['gender']?.toString();

    double? bmi;
    if (heightCm != null && weightKg != null && heightCm > 0) {
      final heightM = heightCm / 100;
      bmi = weightKg / (heightM * heightM);
    }

    final workoutsRaw = await _client
        .from('workouts')
        .select()
        .eq('user_id', user.id)
        .gte('created_at', weekStart.toIso8601String())
        .order('created_at', ascending: true);

    final workouts = List<Map<String, dynamic>>.from(workoutsRaw);

    int todayWorkoutCount = 0;
    int todayCalories = 0;
    int todayMinutes = 0;
    int weeklyMinutes = 0;

    final weeklyDurations = List<double>.filled(7, 0);

    for (final workout in workouts) {
      final calories = _toInt(workout['calories']) ?? 0;
      final duration = _toInt(workout['duration']) ?? 0;
      final createdAtString = workout['created_at']?.toString();

      if (createdAtString == null) continue;

      final createdAt = DateTime.tryParse(createdAtString);
      if (createdAt == null) continue;

      final localDate = createdAt.toLocal();
      final dayOnly = DateTime(localDate.year, localDate.month, localDate.day);

      weeklyMinutes += duration;

      final weekdayIndex = localDate.weekday - 1;
      if (weekdayIndex >= 0 && weekdayIndex < 7) {
        weeklyDurations[weekdayIndex] += duration.toDouble();
      }

      if (dayOnly == todayStart) {
        todayWorkoutCount += 1;
        todayCalories += calories;
        todayMinutes += duration;
      }
    }

    final goalsRaw = await _client.from('goals').select().eq('user_id', user.id);

    final goals = List<Map<String, dynamic>>.from(goalsRaw);

    int activeGoals = 0;
    int completedGoals = 0;
    double totalProgress = 0;
    int progressCount = 0;

    for (final goal in goals) {
      final goalType = goal['goal_type']?.toString() ?? '';
      final target = _toDouble(goal['target_value']) ?? 0;

      double current = 0;

      if (goalType == 'workouts_per_week') {
        current = workouts.length.toDouble();
      } else if (goalType == 'calories_per_week') {
        double totalCalories = 0;
        for (final workout in workouts) {
          totalCalories += _toDouble(workout['calories']) ?? 0;
        }
        current = totalCalories;
      } else if (goalType == 'minutes_per_week') {
        current = weeklyMinutes.toDouble();
      } else if (goalType == 'weight_target') {
        current = weightKg ?? 0;
      }

      if (target > 0) {
        double progress = current / target;
        if (progress < 0) progress = 0;
        if (progress > 1) progress = 1;

        totalProgress += progress;
        progressCount++;

        if (progress >= 1) {
          completedGoals++;
        } else {
          final rawStatus = (goal['status'] ?? 'active').toString().toLowerCase();
          if (rawStatus != 'paused') {
            activeGoals++;
          }
        }
      }
    }

    final avgGoalProgress =
    progressCount > 0 ? totalProgress / progressCount : 0.0;

    return DashboardData(
      email: user.email ?? 'BodyLog User',
      todayWorkoutCount: todayWorkoutCount,
      todayCalories: todayCalories,
      todayMinutes: todayMinutes,
      weeklyMinutes: weeklyMinutes,
      weeklyDurations: weeklyDurations,
      activeGoals: activeGoals,
      completedGoals: completedGoals,
      avgGoalProgress: avgGoalProgress,
      bmi: bmi,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
    );
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _bmiCategory(BuildContext context, double? bmi) {
    if (bmi == null) return AppStrings.text(context, 'not_enough_data');
    if (bmi < 18.5) return AppStrings.text(context, 'underweight');
    if (bmi < 25) return AppStrings.text(context, 'normal');
    if (bmi < 30) return AppStrings.text(context, 'overweight');
    return AppStrings.text(context, 'obese');
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF764BA2);
    const Color primaryIndigo = Color(0xFF667EEA);
    const Color textDark = Color(0xFF2D3142);
    const Color textSoft = Color(0xFF6C7280);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryIndigo,
              primaryPurple,
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<DashboardData>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load dashboard:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }

              final data = snapshot.data!;

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshDashboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _circleIconButton(
                                  icon: Icons.settings_outlined,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SettingsPage(),
                                      ),
                                    ).then((_) => _refreshDashboard());
                                  },
                                ),
                                Text(
                                  AppStrings.text(context, 'dashboard'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _circleIconButton(
                                  icon: Icons.flag_outlined,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const GoalsPage(),
                                      ),
                                    ).then((_) => _refreshDashboard());
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppStrings.text(context, 'welcome_back'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.email,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: _cardDecoration(),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppStrings.text(context, 'today_overview'),
                                        style: const TextStyle(
                                          color: textDark,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        color: primaryPurple,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _buildMainSummary(context, data),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _quickActionCard(
                                    title: AppStrings.text(context, 'progress'),
                                    subtitle:
                                    '${data.completedGoals} ${AppStrings.text(context, 'goals_completed')}',
                                    icon: Icons.show_chart,
                                    iconColor: Colors.blue,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const ProgressTrackingPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _quickActionCard(
                                    title: AppStrings.text(context, 'health'),
                                    subtitle: data.bmi != null
                                        ? '${AppStrings.text(context, 'bmi_label')} ${data.bmi!.toStringAsFixed(1)}'
                                        : AppStrings.text(
                                      context,
                                      'bmi_not_available',
                                    ),
                                    icon: Icons.favorite,
                                    iconColor: Colors.pink,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const HealthPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _infoCard(
                              title: AppStrings.text(context, 'training_load'),
                              icon: Icons.fitness_center,
                              iconColor: Colors.deepPurple,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${data.weeklyMinutes}',
                                          style: const TextStyle(
                                            color: textDark,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppStrings.text(
                                            context,
                                            'total_workout_minutes_this_week',
                                          ),
                                          style: const TextStyle(
                                            color: textSoft,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _miniWeeklyBars(data.weeklyDurations),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _infoCard(
                              title: AppStrings.text(context, 'goal_status'),
                              icon: Icons.flag,
                              iconColor: Colors.green,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(data.avgGoalProgress * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${data.activeGoals} ${AppStrings.text(context, 'active').toLowerCase()} • ${data.completedGoals} ${AppStrings.text(context, 'completed').toLowerCase()}',
                                    style: const TextStyle(
                                      color: textSoft,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  LinearProgressIndicator(
                                    value: data.avgGoalProgress,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(8),
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                      primaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _infoCard(
                              title: AppStrings.text(context, 'body_metrics'),
                              icon: Icons.monitor_weight_outlined,
                              iconColor: Colors.orange,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.bmi != null
                                              ? data.bmi!.toStringAsFixed(1)
                                              : '--',
                                          style: const TextStyle(
                                            color: textDark,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _bmiCategory(context, data.bmi),
                                          style: const TextStyle(
                                            color: textSoft,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${AppStrings.text(context, 'height')}: ${data.heightCm?.toStringAsFixed(0) ?? '--'} cm',
                                        style: const TextStyle(
                                          color: textSoft,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${AppStrings.text(context, 'weight')}: ${data.weightKg?.toStringAsFixed(0) ?? '--'} kg',
                                        style: const TextStyle(
                                          color: textSoft,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _infoCard(
                              title: AppStrings.text(context, 'profile_snapshot'),
                              icon: Icons.person_outline,
                              iconColor: Colors.cyan,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (data.gender?.toLowerCase() == 'male')
                                              ? AppStrings.text(context, 'male')
                                              : (data.gender?.toLowerCase() ==
                                              'female')
                                              ? AppStrings.text(
                                            context,
                                            'female',
                                          )
                                              : (data.gender ?? '--'),
                                          style: const TextStyle(
                                            color: textDark,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data.age != null
                                              ? '${AppStrings.text(context, 'age')} ${data.age}'
                                              : AppStrings.text(
                                            context,
                                            'bmi_not_available',
                                          ),
                                          style: const TextStyle(
                                            color: textSoft,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${data.todayWorkoutCount} ${AppStrings.text(context, 'workouts')}',
                                          style: const TextStyle(
                                            color: textSoft,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${data.todayCalories} kcal',
                                          style: const TextStyle(
                                            color: textSoft,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _bottomNavItem(
                          Icons.home_rounded,
                          AppStrings.text(context, 'dashboard'),
                          0,
                        ),
                        _bottomNavItem(
                          Icons.fitness_center,
                          'Workout',
                          1,
                        ),
                        _bottomNavItem(
                          Icons.flag,
                          AppStrings.text(context, 'goals'),
                          2,
                        ),
                        _bottomNavItem(
                          Icons.person_outline,
                          AppStrings.text(context, 'profile'),
                          3,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainSummary(BuildContext context, DashboardData data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _overviewStat(
            icon: Icons.fitness_center,
            iconColor: Colors.green,
            value: '${data.todayWorkoutCount}',
            label: AppStrings.text(context, 'workouts'),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: data.avgGoalProgress > 1 ? 1 : data.avgGoalProgress,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF764BA2),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.todayCalories}',
                    style: const TextStyle(
                      color: Color(0xFF2D3142),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      color: Color(0xFF6C7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _overviewStat(
            icon: Icons.timer_outlined,
            iconColor: Colors.pink,
            value: '${data.todayMinutes}',
            label: AppStrings.text(context, 'minutes_short'),
          ),
        ],
      ),
    );
  }

  Widget _overviewStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2D3142),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6C7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _quickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2D3142),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF6C7280),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF2D3142),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _miniWeeklyBars(List<double> weeklyDurations) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    double maxValue = 1;
    for (final value in weeklyDurations) {
      if (value > maxValue) maxValue = value;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(days.length, (index) {
        final rawHeight = weeklyDurations[index];
        final normalizedHeight = (rawHeight / maxValue) * 30;
        final barHeight =
        rawHeight == 0 ? 6.0 : normalizedHeight.clamp(6.0, 30.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                days[index],
                style: const TextStyle(
                  color: Color(0xFF6C7280),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _bottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    const Color selectedColor = Color(0xFF764BA2);
    const Color normalColor = Color(0xFF6C7280);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _onBottomNavTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : normalColor,
              size: 23,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : normalColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
