import 'package:bodylog/services/app_strings.dart';
import 'package:bodylog/services/profile_service.dart';
import 'package:flutter/material.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final ProfileService _profileService = ProfileService();

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _username = '';
  String? _fullName;
  String _gender = 'Male';
  String _activityLevel = 'Moderately Active';

  bool _isLoading = true;
  bool _isSaving = false;

  double? _bmi;
  String _bmiCategory = 'Not enough data';
  double? _bmr;
  double? _dailyCalories;

  final Map<String, double> _activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly Active': 1.375,
    'Moderately Active': 1.55,
    'Very Active': 1.725,
  };

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await _profileService.getProfile();

      if (profile != null) {
        _username = profile['username'] ?? '';
        _fullName = profile['full_name'];

        _ageController.text = profile['age']?.toString() ?? '';
        _heightController.text = profile['height_cm']?.toString() ?? '';
        _weightController.text = profile['weight_kg']?.toString() ?? '';

        final gender = (profile['gender'] ?? '').toString().trim();
        if (gender.isNotEmpty) {
          _gender = gender[0].toUpperCase() + gender.substring(1).toLowerCase();
        }
      }

      _calculateHealthData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.text(context, 'failed_to_load_profile')}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateHealthData() {
    final age = int.tryParse(_ageController.text.trim());
    final heightCm = double.tryParse(_heightController.text.trim());
    final weightKg = double.tryParse(_weightController.text.trim());

    double? bmi;
    String bmiCategory = AppStrings.text(context, 'not_enough_data');
    double? bmr;
    double? dailyCalories;

    if (heightCm != null && weightKg != null && heightCm > 0 && weightKg > 0) {
      final heightM = heightCm / 100;
      bmi = weightKg / (heightM * heightM);

      if (bmi < 18.5) {
        bmiCategory = AppStrings.text(context, 'underweight');
      } else if (bmi < 25) {
        bmiCategory = AppStrings.text(context, 'normal');
      } else if (bmi < 30) {
        bmiCategory = AppStrings.text(context, 'overweight');
      } else {
        bmiCategory = AppStrings.text(context, 'obese');
      }
    }

    if (age != null &&
        heightCm != null &&
        weightKg != null &&
        age > 0 &&
        heightCm > 0 &&
        weightKg > 0) {
      if (_gender.toLowerCase() == 'male') {
        bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
      } else {
        bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
      }

      final multiplier = _activityMultipliers[_activityLevel] ?? 1.55;
      dailyCalories = bmr * multiplier;
    }

    setState(() {
      _bmi = bmi;
      _bmiCategory = bmiCategory;
      _bmr = bmr;
      _dailyCalories = dailyCalories;
    });
  }

  Future<void> _saveHealthProfileData() async {
    setState(() => _isSaving = true);

    try {
      await _profileService.updateProfile(
        username: _username,
        fullName: _fullName,
        age: _ageController.text.trim().isEmpty
            ? null
            : int.tryParse(_ageController.text.trim()),
        gender: _gender,
        heightCm: _heightController.text.trim().isEmpty
            ? null
            : double.tryParse(_heightController.text.trim()),
        weightKg: _weightController.text.trim().isEmpty
            ? null
            : double.tryParse(_weightController.text.trim()),
      );

      _calculateHealthData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.text(context, 'profile_data_updated_successfully'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.text(context, 'failed_to_update_profile_data')}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _healthTip() {
    if (_bmi == null || _dailyCalories == null) {
      return AppStrings.text(context, 'health_tip_missing');
    }

    if (_bmi! < 18.5) {
      return AppStrings.text(context, 'health_tip_underweight');
    } else if (_bmi! < 25) {
      return AppStrings.text(context, 'health_tip_normal');
    } else if (_bmi! < 30) {
      return AppStrings.text(context, 'health_tip_overweight');
    } else {
      return AppStrings.text(context, 'health_tip_obese');
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
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

  Widget _summaryStat(String title, String value, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const topColor = Color(0xFF667EEA);
    const bottomColor = Color(0xFF764BA2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppStrings.text(context, 'health_tracking')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              topColor,
              bottomColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.text(context, 'your_health_summary'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.text(context, 'health_summary_subtitle'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.text(context, 'health_overview'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _summaryStat(
                            AppStrings.text(context, 'bmi_label'),
                            _bmi != null ? _bmi!.toStringAsFixed(1) : '--',
                            _bmiCategory,
                          ),
                          const SizedBox(width: 10),
                          _summaryStat(
                            AppStrings.text(context, 'daily_calories'),
                            _dailyCalories != null
                                ? _dailyCalories!.round().toString()
                                : '--',
                            'kcal/day',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monitor_weight_outlined,
                              color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.text(context, 'bmi_calculator'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          AppStrings.text(context, 'height_cm'),
                          Icons.height,
                        ),
                        onChanged: (_) => _calculateHealthData(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          AppStrings.text(context, 'weight_kg'),
                          Icons.monitor_weight,
                        ),
                        onChanged: (_) => _calculateHealthData(),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.text(context, 'bmi_label')}: ${_bmi != null ? _bmi!.toStringAsFixed(1) : '--'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${AppStrings.text(context, 'category')}: $_bmiCategory',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_outlined,
                              color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.text(context, 'calories_calculator'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          AppStrings.text(context, 'age'),
                          Icons.calendar_today,
                        ),
                        onChanged: (_) => _calculateHealthData(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: _inputDecoration(
                          AppStrings.text(context, 'gender'),
                          Icons.wc_outlined,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Male',
                            child: Text(AppStrings.text(context, 'male')),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text(AppStrings.text(context, 'female')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _gender = value);
                            _calculateHealthData();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _activityLevel,
                        decoration: _inputDecoration(
                          AppStrings.text(context, 'activity_level'),
                          Icons.directions_run,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Sedentary',
                            child: Text(
                                AppStrings.text(context, 'sedentary')),
                          ),
                          DropdownMenuItem(
                            value: 'Lightly Active',
                            child: Text(AppStrings.text(
                                context, 'lightly_active')),
                          ),
                          DropdownMenuItem(
                            value: 'Moderately Active',
                            child: Text(AppStrings.text(
                                context, 'moderately_active')),
                          ),
                          DropdownMenuItem(
                            value: 'Very Active',
                            child: Text(
                                AppStrings.text(context, 'very_active')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _activityLevel = value);
                            _calculateHealthData();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.text(context, 'bmr')}: ${_bmr != null ? _bmr!.round() : '--'} kcal',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppStrings.text(context, 'estimated_daily_calories')}: ${_dailyCalories != null ? _dailyCalories!.round() : '--'} kcal',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tips_and_updates_outlined,
                              color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.text(context, 'health_tips'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _healthTip(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveHealthProfileData,
                    icon: _isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : AppStrings.text(context, 'update_profile_data'),
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF764BA2),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
