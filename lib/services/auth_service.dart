import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Získat aktuálního uživatele
  User? get currentUser => _supabase.auth.currentUser;

  // Zkontrolovat, zda je uživatel přihlášen
  bool get isSignedIn => _supabase.auth.currentSession != null;

  // Registrace pomocí emailu a hesla
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
      
      // Vytvořit profil v tabulce Uzivatel, pokud byla registrace úspěšná
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

  // Přihlášení pomocí emailu a hesla
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

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Získat profil uživatele pomocí emailu
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

  // Aktualizovat profil uživatele
  Future<void> updateUserProfile({
    required String email,
    String? jmeno,
    String? prijmeni,
    String? newEmail,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (jmeno != null) updateData['jmeno'] = jmeno;
      if (prijmeni != null) updateData['prijmeni'] = prijmeni;
      if (newEmail != null && newEmail != email) {
        updateData['mail'] = newEmail;
      }
      
      await _supabase
          .from('Uzivatel')
          .update(updateData)
          .eq('mail', email);
    } catch (e) {
      rethrow;
    }
  }
}
