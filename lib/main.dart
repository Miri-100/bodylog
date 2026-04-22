import 'package:bodylog/screens/auth.dart';
import 'package:bodylog/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rfgjlakkcrzexgvfeaan.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmZ2psYWtrY3J6ZXhndmZlYWFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0MDYzMDgsImV4cCI6MjA5MTk4MjMwOH0.bNhBUnsr4DGYOP7HHcJp1uFnYdfzOySNaEFLpLDiIBk',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BodyLog',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = supabase.auth.currentSession;

          if (session != null) {
            return const DashboardPage();
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
