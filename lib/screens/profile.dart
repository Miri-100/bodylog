import 'dart:typed_data';
import 'package:bodylog/services/app_strings.dart';
import 'package:bodylog/services/auth_service.dart';
import 'package:bodylog/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Uint8List? _imageBytes;
  String? _avatarUrl;

  bool _isLoading = true;
  bool _isSaving = false;

  static const Color _topColor = Color(0xFF667EEA);
  static const Color _bottomColor = Color(0xFF764BA2);
  static const Color _primaryPurple = Color(0xFF764BA2);
  static const Color _textDark = Color(0xFF2D3142);
  static const Color _textSoft = Color(0xFF6C7280);

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
        _avatarUrl = profile['avatar_url'];
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.text(context, 'failed_to_load_profile')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showImageSourcePicker() async {
    if (_isSaving) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: [
                ListTile(
                  title: Text(
                    AppStrings.text(context, 'profile_photo'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: _primaryPurple),
                  title: Text(AppStrings.text(context, 'take_photo')),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading:
                  const Icon(Icons.photo_library, color: _primaryPurple),
                  title: Text(AppStrings.text(context, 'choose_gallery')),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_avatarUrl != null || _imageBytes != null)
                  ListTile(
                    leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                    title: Text(
                      AppStrings.text(context, 'remove_photo'),
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imageBytes = null;
                        _avatarUrl = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.text(context, 'failed_to_pick_image')}: $e',
          ),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? avatarToSave = _avatarUrl;

      if (_imageBytes != null) {
        avatarToSave = await _profileService.uploadAvatar(
          bytes: _imageBytes!,
          fileExt: 'jpg',
        );
      }

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
        avatarUrl: avatarToSave,
      );

      if (!mounted) return;

      setState(() {
        _avatarUrl = avatarToSave;
        _imageBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.text(context, 'profile_updated_successfully'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.text(context, 'failed_to_update_profile')}: $e',
          ),
        ),
      );
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.text(context, 'logout_failed')}: $e'),
        ),
      );
    }
  }

  ImageProvider? _buildAvatarImage() {
    if (_imageBytes != null) {
      return MemoryImage(_imageBytes!);
    }

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }

    return null;
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primaryPurple),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: _textSoft),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD9D9E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD9D9E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _primaryPurple, width: 1.5),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String email) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        const Spacer(),
        Text(
          AppStrings.text(context, 'profile'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: _buildAvatarImage(),
                  child: (_imageBytes == null &&
                      (_avatarUrl == null || _avatarUrl!.isEmpty))
                      ? const Icon(
                    Icons.person,
                    size: 58,
                    color: _primaryPurple,
                  )
                      : null,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSoft,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    final isMale = _genderController.text.toLowerCase() == 'male';
    final isFemale = _genderController.text.toLowerCase() == 'female';

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9D9E3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                isMale ? _primaryPurple.withOpacity(0.10) : Colors.white,
                side: BorderSide(
                  color: isMale ? _primaryPurple : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                setState(() {
                  _genderController.text = 'Male';
                });
              },
              icon: Icon(
                Icons.male,
                color: isMale ? _primaryPurple : Colors.grey.shade600,
              ),
              label: Text(
                AppStrings.text(context, 'male'),
                style: TextStyle(
                  color: isMale ? _primaryPurple : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                isFemale ? _primaryPurple.withOpacity(0.10) : Colors.white,
                side: BorderSide(
                  color: isFemale ? _primaryPurple : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                setState(() {
                  _genderController.text = 'Female';
                });
              },
              icon: Icon(
                Icons.female,
                color: isFemale ? _primaryPurple : Colors.grey.shade600,
              ),
              label: Text(
                AppStrings.text(context, 'female'),
                style: TextStyle(
                  color: isFemale ? _primaryPurple : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _topColor,
              _bottomColor,
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(context, user?.email ?? ''),
                  const SizedBox(height: 20),
                  _buildAvatarSection(user?.email ?? ''),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: _inputDecoration(
                            AppStrings.text(context, 'username'),
                            Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.text(
                                context,
                                'username_required',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: _inputDecoration(
                            AppStrings.text(context, 'full_name'),
                            Icons.badge_outlined,
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[a-zA-Z\s]+$')
                                  .hasMatch(value)) {
                                return AppStrings.text(
                                  context,
                                  'name_alpha_only',
                                );
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            AppStrings.text(context, 'age'),
                            Icons.calendar_today,
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final age = int.tryParse(value);
                              if (age == null || age < 12 || age > 99) {
                                return AppStrings.text(
                                  context,
                                  'age_validation',
                                );
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                            const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              AppStrings.text(context, 'gender'),
                              style: const TextStyle(
                                color: _textSoft,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        _buildGenderSelector(),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _heightController,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            AppStrings.text(context, 'height_cm'),
                            Icons.height,
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final height = double.tryParse(value);
                              if (height == null ||
                                  height < 100 ||
                                  height > 300) {
                                return AppStrings.text(
                                  context,
                                  'height_validation',
                                );
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _weightController,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            AppStrings.text(context, 'weight_kg'),
                            Icons.monitor_weight,
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final weight = double.tryParse(value);
                              if (weight == null ||
                                  weight < 50 ||
                                  weight > 500) {
                                return AppStrings.text(
                                  context,
                                  'weight_validation',
                                );
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryPurple,
                        elevation: 6,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _primaryPurple,
                        ),
                      )
                          : Text(
                        AppStrings.text(context, 'save_profile'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
