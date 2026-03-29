import 'package:supabase_flutter/supabase_flutter.dart';

class SkladService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Načte všechny položky skladu seřazené podle názvu
  Future<List<Map<String, dynamic>>> getSklad() async {
    final response = await _supabase
        .from('Sklad')
        .select()
        .order('nazev', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Přidá novou ingredienci
  Future<void> addItem(Map<String, dynamic> data) async {
  final response = await _supabase
      .from('Sklad')
      .insert(data)
      .select();
  }

  // Upraví existující ingredienci
  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    await _supabase.from('Sklad').update(data).eq('id', id);
  }

  // Smaže ingredienci podle id
  Future<void> deleteItem(int id) async {
    await _supabase.from('Sklad').delete().eq('id', id);
  }
}
