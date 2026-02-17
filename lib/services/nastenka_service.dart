import 'package:supabase_flutter/supabase_flutter.dart';

class NastenkaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Získat všechny úkoly
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    try {
      final response = await _supabase
          .from('Nastenka')
          .select('*, Uzivatel(jmeno, prijmeni, mail)')
          .order('na_den');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Přidat nový úkol
  Future<void> addTask({
    required int uzivatelId,
    required String textUkolu,
    required String opakovat,
    required DateTime naDen,
  }) async {
    try {
      await _supabase.from('Nastenka').insert({
        'pro_uzivatele': uzivatelId,
        'text_ukolu': textUkolu,
        'opakovat': opakovat,
        'na_den': naDen.toIso8601String(),
        'splneno': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Smazat úkol
  Future<void> deleteTask(int id) async {
    try {
      await _supabase
          .from('Nastenka')
          .delete()
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  // Označit úkol jako splněný a smazat
  Future<void> completeTask(int id) async {
    try {
      await _supabase
          .from('Nastenka')
          .delete()
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}
