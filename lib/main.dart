import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/employee_home_screen.dart';
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
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('cs', 'CZ'), Locale('en', 'US')],
      locale: const Locale('cs', 'CZ'),
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.black,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        cardColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
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
      if (profile == null || profile['potvrzeno'] != true) {
        await Supabase.instance.client.auth.signOut();
        return const LoginScreen();
      }
      final isAdmin = profile['admin'] == true;
      final isEmployee = profile['zamestnanec'] == true;

      if (isAdmin) {
        return const DashboardScreen();
      }
      if (isEmployee) {
        return const EmployeeHomeScreen();
      }
      return const HomeScreen();
    }

    return const HomeScreen();
  }
}
