import 'package:supabase_flutter/supabase_flutter.dart';

class RecepturyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Získat všechny receptury
  Future<List<Map<String, dynamic>>> getAllReceptury() async {
    try {
      final response = await _supabase
          .from('Receptury')
          .select('*, Kategorie(nazev)')
          .order('nazev');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Přidat novou recepturu
  Future<void> addReceptura({
    required String nazev,
    required int kategorieId,
    String? suroviny,
    int? mnozstvi,
    double? cena,
  }) async {
    try {
      await _supabase.from('Receptury').insert({
        'nazev': nazev,
        'kategorie_id': kategorieId,
        'suroviny': suroviny,
        'mnozstvi': mnozstvi,
        'cena': cena,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Aktualizovat recepturu
  Future<void> updateReceptura({
    required int id,
    String? nazev,
    int? kategorieId,
    String? suroviny,
    int? mnozstvi,
    double? cena,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (nazev != null) updateData['nazev'] = nazev;
      if (kategorieId != null) updateData['kategorie_id'] = kategorieId;
      if (suroviny != null) updateData['suroviny'] = suroviny;
      if (mnozstvi != null) updateData['mnozstvi'] = mnozstvi;
      if (cena != null) updateData['cena'] = cena;
      
      await _supabase
          .from('Receptury')
          .update(updateData)
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  // Získat všechny kategorie
  Future<List<Map<String, dynamic>>> getKategorie() async {
    try {
      final response = await _supabase
          .from('Kategorie')
          .select()
          .order('nazev');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Smazat recepturu
  Future<void> deleteReceptura(int id) async {
    try {
      // Najít všechny objednávky, které tento produkt obsahují
      final affectedRows = await _supabase
          .from('ObjednavkaZbozi')
          .select('objednavka_id')
          .eq('zbozi_id', id);

      final affectedOrderIds = affectedRows
          .map<int>((r) => r['objednavka_id'] as int)
          .toSet()
          .toList();

      // Smazat položky objednávek odkazující na tento produkt
      await _supabase
          .from('ObjednavkaZbozi')
          .delete()
          .eq('zbozi_id', id);

      // Přepočítat celkovou cenu každé dotčené objednávky
      for (final orderId in affectedOrderIds) {
        final items = await _supabase
            .from('ObjednavkaZbozi')
            .select('mnozstvi, Receptury(cena)')
            .eq('objednavka_id', orderId);

        int totalPrice = 0;
        for (final item in items) {
          final mnozstvi = (item['mnozstvi'] as num?)?.toInt() ?? 0;
          final cena = (item['Receptury']?['cena'] as num?) ?? 0;
          totalPrice += (mnozstvi * cena).round();
        }

        await _supabase
            .from('Objednavky')
            .update({'celkova_cena': totalPrice})
            .eq('id', orderId);
      }

      await _supabase
          .from('Receptury')
          .delete()
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}
