import 'package:supabase_flutter/supabase_flutter.dart';

class RecepturyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Získat všechny receptury
  Future<List<Map<String, dynamic>>> getAllReceptury() async {
    try {
      final response = await _supabase
          .from('Receptury')
          .select()
          .order('nazev');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Přidat novou recepturu
  Future<void> addReceptura({
    required String nazev,
    required String kategorie,
    String? suroviny,
    int? mnozstvi,
    String? color,
  }) async {
    try {
      await _supabase.from('Receptury').insert({
        'nazev': nazev,
        'kategorie': kategorie,
        'suroviny': suroviny,
        'mnozstvi': mnozstvi,
        'color': color,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Aktualizovat recepturu
  Future<void> updateReceptura({
    required int id,
    String? nazev,
    String? kategorie,
    String? suroviny,
    int? mnozstvi,
    String? color,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (nazev != null) updateData['nazev'] = nazev;
      if (kategorie != null) updateData['kategorie'] = kategorie;
      if (suroviny != null) updateData['suroviny'] = suroviny;
      if (mnozstvi != null) updateData['mnozstvi'] = mnozstvi;
      if (color != null) updateData['color'] = color;
      
      await _supabase
          .from('Receptury')
          .update(updateData)
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  // Smazat recepturu
  Future<void> deleteReceptura(int id) async {
    try {
      await _supabase
          .from('Receptury')
          .delete()
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}
