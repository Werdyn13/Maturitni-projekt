import 'package:supabase_flutter/supabase_flutter.dart';

class SmenyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Načte všechny směny pro daný týden (pondělí – neděle)
  Future<List<Map<String, dynamic>>> getShiftsForWeek(DateTime weekMonday) async {
    final start = DateTime(weekMonday.year, weekMonday.month, weekMonday.day);
    final end = start.add(const Duration(days: 7));

    final shifts = await _supabase
        .from('Smeny')
        .select('*, Uzivatel(id, jmeno, prijmeni, mail)')
        .gte('datum', start.toIso8601String())
        .lt('datum', end.toIso8601String())
        .order('datum', ascending: true);

    return List<Map<String, dynamic>>.from(shifts);
  }

  Future<List<Map<String, dynamic>>> getShiftsForCurrentUserAndWeek(DateTime weekMonday) async {
    final userEmail = _supabase.auth.currentUser!.email!;

    final userResponse = await _supabase
        .from('Uzivatel')
        .select('id')
        .eq('mail', userEmail)
        .single();

    final userId = userResponse['id'];
    final start = DateTime(weekMonday.year, weekMonday.month, weekMonday.day);
    final end = start.add(const Duration(days: 7));

    final shifts = await _supabase
        .from('Smeny')
        .select()
        .eq('zamestnanec', userId)
        .gte('datum', start.toIso8601String())
        .lt('datum', end.toIso8601String())
        .order('datum', ascending: true);

    return List<Map<String, dynamic>>.from(shifts);
  }

  // Admin: přidat směnu
  Future<void> addShift({
    required int zamestnanecId,
    required DateTime datum,
    String? druhSmeny,
  }) async {
    await _supabase.from('Smeny').insert({
      'zamestnanec': zamestnanecId,
      'datum': DateTime(datum.year, datum.month, datum.day).toIso8601String(),
      'druh_smeny': druhSmeny,
    });
  }

  // Admin: aktualizovat druh směny
  Future<void> updateShift(int id, String druhSmeny) async {
    await _supabase.from('Smeny').update({'druh_smeny': druhSmeny}).eq('id', id);
  }

  // Admin: smazat směnu podle id
  Future<void> deleteShift(int id) async {
    await _supabase.from('Smeny').delete().eq('id', id);
  }
}

