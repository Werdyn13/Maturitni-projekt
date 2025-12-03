import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _supabase.auth.currentSession != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? jmeno,
    String? prijmeni,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      // Create profile in Uzivatel table if sign up was successful
      if (response.user != null) {
        await _supabase.from('Uzivatel').insert({
          'jmeno': jmeno ?? '',
          'prijmeni': prijmeni ?? '',
          'mail': email,
          'admin': false,
        });
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Get user profile from Uzivatel table by email
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    try {
      final response = await _supabase
          .from('Uzivatel')
          .select()
          .eq('mail', email)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }
}
