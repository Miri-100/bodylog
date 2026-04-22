import 'package:bodylog/services/auth_service.dart';
import 'package:bodylog/services/profile_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();

      if (profile != null) {
        _usernameController.text = profile['username'] ?? '';
        _fullNameController.text = profile['full_name'] ?? '';
        _ageController.text = profile['age']?.toString() ?? '';
        _genderController.text = profile['gender'] ?? '';
        _heightController.text = profile['height_cm']?.toString() ?? '';
        _weightController.text = profile['weight_kg']?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _profileService.updateProfile(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        age: _ageController.text.trim().isEmpty
            ? null
            : int.tryParse(_ageController.text.trim()),
        gender: _genderController.text.trim(),
        heightCm: _heightController.text.trim().isEmpty
            ? null
            : double.tryParse(_heightController.text.trim()),
        weightKg: _weightController.text.trim().isEmpty
            ? null
            : double.tryParse(_weightController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: const Icon(
                    Icons.person,
                    size: 42,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _usernameController,
                  decoration:
                  _inputDecoration('Username', Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _fullNameController,
                  decoration:
                  _inputDecoration('Full Name', Icons.badge_outlined),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration:
                  _inputDecoration('Age', Icons.calendar_today),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _genderController,
                  decoration:
                  _inputDecoration('Gender', Icons.wc_outlined),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                  _inputDecoration('Height (cm)', Icons.height),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                  _inputDecoration('Weight (kg)', Icons.monitor_weight),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Save Profile',
                      style: TextStyle(fontSize: 16),
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
    _usernameController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
