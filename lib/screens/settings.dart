import 'package:bodylog/screens/auth.dart';
import 'package:bodylog/screens/help_center.dart';
import 'package:bodylog/screens/profile.dart';
import 'package:bodylog/services/app_strings.dart';
import 'package:bodylog/services/auth_service.dart';
import 'package:bodylog/services/language_provider.dart';
import 'package:bodylog/services/settings_db.dart';
import 'package:bodylog/theme_provider.dart';
import 'package:bodylog/widgets/app_gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _primaryPurple = Color(0xFF764BA2);
  static const Color _textDark = Color(0xFF2D3142);

  bool _darkMode = false;
  String _language = 'English';
  bool _isLoading = true;

  final SettingsDatabase _db = SettingsDatabase.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _db.getSettings();

      if (!mounted) return;

      setState(() {
        _darkMode = settings?['dark_mode'] == 1;
        _language = settings?['language'] ?? 'English';
        _isLoading = false;
      });

      themeProvider.updateTheme(_darkMode);
      languageProvider.setLanguage(_language);
    } catch (e) {
      debugPrint('Settings load skipped/failed: $e');

      if (!mounted) return;
      setState(() {
        _darkMode = false;
        _language = 'English';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    themeProvider.updateTheme(_darkMode);
    languageProvider.setLanguage(_language);

    try {
      await _db.updateSettings(
        darkMode: _darkMode,
        language: _language,
      );
    } catch (e) {
      debugPrint('Settings save skipped/failed: $e');
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });

    themeProvider.updateTheme(value);
    _saveSettings();
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(AppStrings.text(context, 'change_password')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.text(context, 'new_password'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.text(context, 'confirm_password'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppStrings.text(context, 'cancel'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                    final newPass = passwordController.text.trim();
                    final confirmPass = confirmPasswordController.text.trim();

                    if (newPass.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppStrings.text(context, 'password_min_6'),
                          ),
                        ),
                      );
                      return;
                    }

                    if (newPass != confirmPass) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppStrings.text(context, 'password_not_match'),
                          ),
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    try {
                      await Supabase.instance.client.auth.updateUser(
                        UserAttributes(password: newPass),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.text(
                                context,
                                'password_changed_successfully',
                              ),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    } finally {
                      setDialogState(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(AppStrings.text(context, 'save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHelpPlaceholder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HelpCenterPage(language: _language),
      ),
    );
  }

  void _showAboutPlaceholder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.text(context, 'about')),
            backgroundColor: _primaryPurple,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.text(context, 'about_bodylog'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(AppStrings.text(context, 'about_bodylog_para_1')),
                    const SizedBox(height: 16),
                    Text(AppStrings.text(context, 'about_bodylog_para_2')),
                    const SizedBox(height: 32),
                    Text(
                      AppStrings.text(context, 'about_footer'),
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRateUsDialog() {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(AppStrings.text(context, 'rate_us')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateBuilder(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppStrings.text(context, 'leave_comment'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.text(context, 'cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final user = Supabase.instance.client.auth.currentUser;

                    if (user != null) {
                      try {
                        await Supabase.instance.client.from('app_ratings').insert({
                          'user_id': user.id,
                          'rating': selectedRating,
                          'comment': commentController.text.trim(),
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.text(context, 'thank_you_rating'),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving rating: $e')),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppStrings.text(context, 'submit')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 48,
          ),
          title: Text(AppStrings.text(context, 'confirm_deletion')),
          content: Text(
            AppStrings.text(context, 'delete_account_warning'),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.text(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleDeleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppStrings.text(context, 'delete')),
            ),
          ],
        );
      },
    );
  }

  void _handleLogOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _handleDeleteAccount() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final authService = AuthService();
      await authService.deleteAccount();

      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
              (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.text(context, 'account_deleted_successfully'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.white),
        )
            : Column(
          children: [
            _buildTopBar(AppStrings.text(context, 'settings')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                children: [
                  _buildSectionTitle(AppStrings.text(context, 'account')),
                  const SizedBox(height: 12),
                  _buildCard([
                    _buildListTile(
                      icon: Icons.person_outline,
                      title: AppStrings.text(context, 'edit_profile'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.lock_outline,
                      title: AppStrings.text(context, 'change_password'),
                      onTap: _showChangePasswordDialog,
                    ),
                  ], isDark),
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    AppStrings.text(context, 'preferences'),
                  ),
                  const SizedBox(height: 12),
                  _buildCard([
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: AppStrings.text(context, 'dark_mode'),
                      value: _darkMode,
                      onChanged: _toggleDarkMode,
                    ),
                    _buildDivider(),
                    _buildLanguageDropdownTile(
                      AppStrings.text(context, 'language'),
                    ),
                  ], isDark),
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    AppStrings.text(context, 'app_info_support'),
                  ),
                  const SizedBox(height: 12),
                  _buildCard([
                    _buildListTile(
                      icon: Icons.help_outline,
                      title: AppStrings.text(
                        context,
                        'help_support_center',
                      ),
                      onTap: _showHelpPlaceholder,
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.info_outline,
                      title: AppStrings.text(context, 'about'),
                      onTap: _showAboutPlaceholder,
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.star_outline,
                      title: AppStrings.text(context, 'rate_us'),
                      onTap: _showRateUsDialog,
                    ),
                    _buildDivider(),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 26,
                      ),
                      title: Text(
                        AppStrings.text(context, 'delete_account'),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: _showDeleteAccountDialog,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 2,
                      ),
                    ),
                  ], isDark),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogOut,
                      icon: const Icon(Icons.logout),
                      label: Text(
                        AppStrings.text(context, 'log_out'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isDark ? const Color(0xFF1F1F1F) : Colors.white,
                        foregroundColor: Colors.redAccent,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String title) {
    return Padding(
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
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.92),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F1F1F).withOpacity(0.95)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: _primaryPurple,
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : _textDark,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? Colors.white54 : const Color(0xFF9AA0AC),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: _primaryPurple,
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : _textDark,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: _primaryPurple,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
    );
  }

  Widget _buildLanguageDropdownTile(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: const Icon(
        Icons.language_outlined,
        color: _primaryPurple,
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : _textDark,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          value: _language,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: _primaryPurple,
          ),
          style: TextStyle(
            color: isDark ? Colors.white : _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _language = newValue;
              });
              languageProvider.setLanguage(newValue);
              _saveSettings();
            }
          },
          items: const [
            DropdownMenuItem(value: 'English', child: Text('🇺🇸 English')),
            DropdownMenuItem(value: 'Malay', child: Text('🇲🇾 Malay')),
            DropdownMenuItem(value: 'Chinese', child: Text('🇨🇳 中文')),
            DropdownMenuItem(value: 'Spanish', child: Text('🇪🇸 Español')),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white12 : Colors.grey.shade200,
      indent: 18,
      endIndent: 18,
    );
  }
}
