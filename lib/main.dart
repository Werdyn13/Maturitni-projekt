import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      home: FutureBuilder(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }

  Future<Widget> _getInitialScreen() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const LoginScreen();
    }

    final authService = AuthService();
    final userEmail = session.user.email;
    if (userEmail != null) {
      final profile = await authService.getUserProfile(userEmail);
      final isAdmin = profile?['admin'] == true;
      return isAdmin ? const DashboardScreen() : const HomeScreen();
    }

    return const HomeScreen();
  }
}
