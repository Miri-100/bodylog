import 'package:bodylog/screens/auth.dart';
import 'package:bodylog/screens/dashboard.dart';
import 'package:bodylog/services/language_provider.dart';
import 'package:bodylog/services/settings_db.dart';
import 'package:bodylog/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  try {
    final settings = await SettingsDatabase.instance.getSettings();
    if (settings != null) {
      themeProvider.updateTheme(settings['dark_mode'] == 1);
      languageProvider.setLanguage(settings['language'] ?? 'English');
    }
  } catch (e) {
    debugPrint('Failed to load local settings: $e');
  }

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        themeProvider,
        languageProvider,
      ]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BodyLog',
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: languageProvider.locale,
          home: StreamBuilder<AuthState>(
            stream: supabase.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final session = snapshot.data?.session;
              if (session != null) {
                return const DashboardPage();
              }
              return const AuthScreen();
            },
          ),
        );
      },
    );
  }
}
