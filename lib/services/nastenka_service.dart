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

  // Přidat nový úkol (pro více uživatelů najednou)
  Future<void> addTask({
    required List<int> uzivatelIds,
    required String textUkolu,
    required String opakovat,
    required DateTime naDen,
  }) async {
    try {
      // Opakující se úkoly mají platnost 6 měsíců
      final String? platnostDo = opakovat != 'Žádné'
          ? DateTime(naDen.year, naDen.month + 6, naDen.day).toIso8601String()
          : null;

      final rows = uzivatelIds.map((id) => {
                'pro_uzivatele': id,
                'text_ukolu': textUkolu,
                'opakovat': opakovat,
                'na_den': naDen.toIso8601String(),
                'splneno': false,
                if (platnostDo != null) 'platnost_do': platnostDo,
              })
          .toList();
      await _supabase.from('Nastenka').insert(rows);
    } catch (e) {
      rethrow;
    }
  }

  // Nastavit zaskrtnutí úkolu zaměstnancem
  Future<void> setChecked(int id, bool value) async {
    await _supabase
        .from('Nastenka')
        .update({'splneno': value})
        .eq('id', id);
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

  // Označit úkol jako splněný.
  // Pokud se opakuje, posune na_den na podle hodnoty opakování.
  // Pokud příští datum přesáhne platnost_do, nebo se neopakuje, smaže ho.
  Future<void> completeTask(int id,
      {String? opakovat, DateTime? naDen, DateTime? platnostDo}) async {
    try {
      DateTime? nextDate;
      if (naDen != null) {
        switch (opakovat) {
          case 'denně':
            nextDate = naDen.add(const Duration(days: 1));
            break;
          case 'týdně':
            nextDate = naDen.add(const Duration(days: 7));
            break;
          case 'měsíčně':
            nextDate = DateTime(naDen.year, naDen.month + 1, naDen.day);
            break;
          default:
            nextDate = null;
        }
      }

      // Smazat pokud: příští datum přesahuje platnost
      final expired =
          nextDate != null && platnostDo != null && nextDate.isAfter(platnostDo);

      if (nextDate != null && !expired) {
        await _supabase.from('Nastenka').update({
          'na_den': nextDate.toIso8601String(),
          'splneno': false,
        }).eq('id', id);
      } else {
        await _supabase.from('Nastenka').delete().eq('id', id);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Odeslat zprávu adminovi e-mailem přes Resend edge function
  Future<void> sendMessageToAdmin(String message) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Uživatel není přihlášen');

    final userResponse = await _supabase
        .from('Uzivatel')
        .select('jmeno, prijmeni')
        .eq('mail', user.email!)
        .maybeSingle();

    final String senderName = userResponse != null
        ? '${userResponse['jmeno']} ${userResponse['prijmeni']}'
        : user.email!;

    await _supabase.functions.invoke(
      'send-message-to-admin',
      body: {
        'senderName': senderName,
        'senderEmail': user.email,
        'message': message,
      },
    );
  }

  // Získat úkoly pro přihlášeného uživatele
  Future<List<Map<String, dynamic>>> getTasksForCurrentUser() async {
    try {
      final email = _supabase.auth.currentUser?.email;
      if (email == null) return [];

      final userResponse = await _supabase
          .from('Uzivatel')
          .select('id')
          .eq('mail', email)
          .maybeSingle();

      if (userResponse == null) return [];

      final userId = userResponse['id'] as int;

      final response = await _supabase
          .from('Nastenka')
          .select('*')
          .eq('pro_uzivatele', userId)
          .order('na_den');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }
}
