import 'package:bodylog/services/app_strings.dart';
import 'package:bodylog/services/goal_service.dart';
import 'package:bodylog/widgets/app_gradient_background.dart';
import 'package:flutter/material.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final GoalService _goalService = GoalService();

  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;

  static const Color _primaryPurple = Color(0xFF764BA2);
  static const Color _textDark = Color(0xFF2D3142);
  static const Color _textSoft = Color(0xFF8A8F99);

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await _goalService.getGoals();

      final List<Map<String, dynamic>> processedGoals = [];

      for (final goal in goals) {
        final goalType = goal['goal_type']?.toString() ?? '';
        final target = ((goal['target_value'] ?? 0) as num).toDouble();
        final current = await _goalService.calculateCurrentProgress(goalType);

        double progress = 0;
        if (target > 0) {
          progress = current / target;
          if (progress > 1) progress = 1;
          if (progress < 0) progress = 0;
        }

        final status =
        progress >= 1 ? 'completed' : (goal['status'] ?? 'active');

        processedGoals.add({
          ...goal,
          'current_value': current,
          'progress': progress,
          'display_status': status,
        });
      }

      if (mounted) {
        setState(() {
          _goals = processedGoals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage(
          '${AppStrings.text(context, 'operation_failed')}: $e',
        );
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _goalTypeLabel(String goalType) {
    switch (goalType) {
      case 'workouts_per_week':
        return AppStrings.text(context, 'workouts_per_week');
      case 'calories_per_week':
        return AppStrings.text(context, 'calories_per_week');
      case 'minutes_per_week':
        return AppStrings.text(context, 'minutes_per_week');
      case 'weight_target':
        return AppStrings.text(context, 'weight_target');
      default:
        return goalType;
    }
  }

  String _goalUnit(String goalType) {
    switch (goalType) {
      case 'workouts_per_week':
        return AppStrings.text(context, 'workouts');
      case 'calories_per_week':
        return 'kcal';
      case 'minutes_per_week':
        return AppStrings.text(context, 'minutes_short');
      case 'weight_target':
        return 'kg';
      default:
        return '';
    }
  }

  String _motivationText(double progress) {
    if (progress >= 1) {
      return AppStrings.text(context, 'great_job_goal_completed');
    }
    if (progress >= 0.75) {
      return AppStrings.text(context, 'almost_there');
    }
    if (progress >= 0.5) {
      return AppStrings.text(context, 'doing_well');
    }
    if (progress > 0) {
      return AppStrings.text(context, 'nice_start');
    }
    return AppStrings.text(context, 'start_today');
  }

  Future<void> _deleteGoal(int id) async {
    try {
      await _goalService.deleteGoal(id);
      await _loadGoals();
      _showMessage(AppStrings.text(context, 'goal_deleted_successfully'));
    } catch (e) {
      _showMessage(
        '${AppStrings.text(context, 'operation_failed')}: $e',
      );
    }
  }

  Future<void> _showGoalBottomSheet({Map<String, dynamic>? goal}) async {
    final bool isEdit = goal != null;
    String selectedGoalType = goal?['goal_type'] ?? 'workouts_per_week';
    final targetController = TextEditingController(
      text: goal?['target_value']?.toString() ?? '',
    );
    String selectedStatus = goal?['status'] ?? 'active';
    DateTime? startDate = goal?['start_date'] != null
        ? DateTime.tryParse(goal!['start_date'])
        : DateTime.now();
    DateTime? endDate = goal?['end_date'] != null
        ? DateTime.tryParse(goal!['end_date'])
        : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickDate(bool isStart) async {
              final initialDate = isStart
                  ? (startDate ?? DateTime.now())
                  : (endDate ?? DateTime.now());

              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setSheetState(() {
                  if (isStart) {
                    startDate = picked;
                  } else {
                    endDate = picked;
                  }
                });
              }
            }

            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit
                          ? AppStrings.text(context, 'edit_goal')
                          : AppStrings.text(context, 'create_goal'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedGoalType,
                      decoration: InputDecoration(
                        labelText: AppStrings.text(context, 'goal_type'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'workouts_per_week',
                          child: Text(
                            AppStrings.text(context, 'workouts_per_week'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'calories_per_week',
                          child: Text(
                            AppStrings.text(context, 'calories_per_week'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'minutes_per_week',
                          child: Text(
                            AppStrings.text(context, 'minutes_per_week'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'weight_target',
                          child: Text(
                            AppStrings.text(context, 'weight_target'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedGoalType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: targetController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText:
                        '${AppStrings.text(context, 'target_value')} (${_goalUnit(selectedGoalType)})',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickDate(true),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              startDate == null
                                  ? AppStrings.text(context, 'start_date')
                                  : startDate!
                                  .toIso8601String()
                                  .split('T')
                                  .first,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickDate(false),
                            icon: const Icon(Icons.event_outlined),
                            label: Text(
                              endDate == null
                                  ? AppStrings.text(context, 'end_date')
                                  : endDate!.toIso8601String().split('T').first,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: AppStrings.text(context, 'status'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(AppStrings.text(context, 'active')),
                          ),
                          const DropdownMenuItem(
                            value: 'paused',
                            child: Text('Paused'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text(AppStrings.text(context, 'completed')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => selectedStatus = value);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final target =
                          double.tryParse(targetController.text.trim());

                          if (target == null || target <= 0) {
                            _showMessage(
                              AppStrings.text(context, 'please_enter_valid_target'),
                            );
                            return;
                          }

                          try {
                            if (isEdit) {
                              await _goalService.updateGoal(
                                id: goal['id'],
                                goalType: selectedGoalType,
                                targetValue: target,
                                startDate: startDate,
                                endDate: endDate,
                                status: selectedStatus,
                              );
                            } else {
                              await _goalService.addGoal(
                                goalType: selectedGoalType,
                                targetValue: target,
                                startDate: startDate,
                                endDate: endDate,
                              );
                            }

                            if (mounted) Navigator.pop(context);
                            await _loadGoals();
                            _showMessage(
                              isEdit
                                  ? AppStrings.text(
                                context,
                                'goal_updated_successfully',
                              )
                                  : AppStrings.text(
                                context,
                                'goal_created_successfully',
                              ),
                            );
                          } catch (e) {
                            _showMessage(
                              '${AppStrings.text(context, 'operation_failed')}: $e',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isEdit
                              ? AppStrings.text(context, 'update_goal')
                              : AppStrings.text(context, 'create_goal'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  int get _activeGoalsCount =>
      _goals.where((g) => g['display_status'] == 'active').length;

  int get _completedGoalsCount =>
      _goals.where((g) => g['display_status'] == 'completed').length;

  double get _overallProgress {
    if (_goals.isEmpty) return 0;
    double total = 0;
    for (final goal in _goals) {
      total += (goal['progress'] ?? 0.0) as double;
    }
    return total / _goals.length;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return AppStrings.text(context, 'completed').toUpperCase();
      case 'active':
        return AppStrings.text(context, 'active').toUpperCase();
      case 'paused':
        return 'PAUSED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.white),
        )
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child:
                      const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.text(context, 'my_goals'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadGoals,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    Text(
                      AppStrings.text(context, 'goals_subtitle'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.text(context, 'goals_overview'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _summaryBox(
                                  AppStrings.text(context, 'active'),
                                  '$_activeGoalsCount',
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _summaryBox(
                                  AppStrings.text(context, 'completed'),
                                  '$_completedGoalsCount',
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _summaryBox(
                                  AppStrings.text(
                                    context,
                                    'progress_percent',
                                  ),
                                  '${(_overallProgress * 100).toStringAsFixed(0)}%',
                                  _primaryPurple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_goals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: _cardDecoration(),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 48,
                              color: _primaryPurple,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.text(context, 'set_first_goal'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._goals.map((goal) {
                        final progress =
                        (goal['progress'] ?? 0.0) as double;
                        final current =
                        (goal['current_value'] ?? 0.0) as double;
                        final target =
                        ((goal['target_value'] ?? 0) as num)
                            .toDouble();
                        final goalType =
                            goal['goal_type']?.toString() ?? '';
                        final status =
                            goal['display_status']?.toString() ?? 'active';

                        Color statusColor;
                        if (status == 'completed') {
                          statusColor = Colors.green;
                        } else if (status == 'paused') {
                          statusColor = Colors.grey;
                        } else {
                          statusColor = _primaryPurple;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: _cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _goalTypeLabel(goalType),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _textDark,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _statusLabel(status),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showGoalBottomSheet(goal: goal);
                                      } else if (value == 'delete') {
                                        _deleteGoal(goal['id']);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                          AppStrings.text(
                                            context,
                                            'edit_goal',
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          AppStrings.text(
                                            context,
                                            'delete',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${AppStrings.text(context, 'target')}: ${target.toStringAsFixed(goalType == 'weight_target' ? 1 : 0)} ${_goalUnit(goalType)}',
                                style: const TextStyle(
                                  color: _textSoft,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppStrings.text(context, 'current')}: ${current.toStringAsFixed(goalType == 'weight_target' ? 1 : 0)} ${_goalUnit(goalType)}',
                                style: const TextStyle(
                                  color: _textSoft,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(12),
                                backgroundColor: Colors.grey.shade300,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                  statusColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${(progress * 100).toStringAsFixed(1)}% ${AppStrings.text(context, 'complete')}',
                                style: const TextStyle(
                                  color: _textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _motivationText(progress),
                                style: const TextStyle(
                                  color: _textSoft,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        foregroundColor: _primaryPurple,
        onPressed: () => _showGoalBottomSheet(),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.text(context, 'add_goal')),
      ),
    );
  }

  Widget _summaryBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: _textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
