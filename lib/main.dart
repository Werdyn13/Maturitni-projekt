import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://rllgcukhsmuqxidqngyy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJsbGdjdWtoc211cXhpZHFuZ3l5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4OTUwNjUsImV4cCI6MjA3NDQ3MTA2NX0.dWUV-oOHiOtiR91DPC3AyDSuYR0lNbFScoD8ZzehQbE',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikace pro pekárnu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _buildInitialScreen(),
    );
  }

  Widget _buildInitialScreen() {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null ? const HomeScreen() : const LoginScreen();
  }
}
