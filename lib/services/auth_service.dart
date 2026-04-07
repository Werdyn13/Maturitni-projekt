import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kLoginTime = 'login_timestamp';
const _kSessionDays = 5;

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
        'potvrzeno': false,
      });
    }

    return response;
  }

  // Přihlášení pomocí emailu a hesla
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Zkontrolovat, zda byl účet schválen adminem
    final profile = await getUserProfile(email);
    if (profile == null || profile['potvrzeno'] != true) {
      await _supabase.auth.signOut();
      throw Exception('Váš účet čeká na schválení administrátorem.');
    }

    // Uložit čas přihlášení
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLoginTime, DateTime.now().toIso8601String());

    return response;
  }

  // Odhlášení uživatele
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoginTime);
  }

  // Zkontrolovat, zda nevypršela platnost relace (5 dní)
  static Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLoginTime);
    if (raw == null) return true;
    final loginTime = DateTime.tryParse(raw);
    if (loginTime == null) return true;
    return DateTime.now().difference(loginTime).inDays >= _kSessionDays;
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
  }) async {
    final updateData = <String, dynamic>{};
    if (jmeno != null) updateData['jmeno'] = jmeno;
    if (prijmeni != null) updateData['prijmeni'] = prijmeni;
    await _supabase.from('Uzivatel').update(updateData).eq('mail', email);
  }

  // Získat všechny uživatele (pro admina)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _supabase.from('Uzivatel').select().order('mail');
    return List<Map<String, dynamic>>.from(response);
  }

  // Získat pouze zaměstnance
  Future<List<Map<String, dynamic>>> getEmployees() async {
    final response = await _supabase
        .from('Uzivatel')
        .select()
        .eq('zamestnanec', true)
        .order('prijmeni');
    return List<Map<String, dynamic>>.from(response);
  }

  // Změnit admin status uživatele
  Future<void> toggleAdminStatus(String email, bool newAdminStatus) async {
    await _supabase.from('Uzivatel').update({'admin': newAdminStatus}).eq('mail', email);
  }

  // Získat čekající uživatele (potvrzeno == false)
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final response = await _supabase
        .from('Uzivatel')
        .select()
        .eq('potvrzeno', false)
        .order('mail');
    return List<Map<String, dynamic>>.from(response);
  }

  // Schválit uživatele
  Future<void> approveUser(String email) async {
    await _supabase.from('Uzivatel').update({'potvrzeno': true}).eq('mail', email);
  }

  // Odmítnout / smazat čekajícího uživatele
  Future<void> rejectUser(String email) async {
    await _supabase.from('Uzivatel').delete().eq('mail', email);
  }

  Future<void> toggleEmployeeStatus(String email, bool newStatus) async {
  await _supabase
      .from('Uzivatel')
      .update({'zamestnanec': newStatus})
      .eq('mail', email);
}
}
