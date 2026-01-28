import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Získat nebo vytvořit aktuální objednávku uživatele (stav = 'nova - čeká na potvrzení')
  Future<Map<String, dynamic>> getCurrentOrder() async {
    try {
      final userEmail = _supabase.auth.currentUser!.email!;

      // Získat ID uživatele z tabulky Uzivatel
      final userResponse = await _supabase
          .from('Uzivatel')
          .select('id')
          .eq('mail', userEmail)
          .single();

      final userId = userResponse['id'];

      // Hledat existující objednávku se stavem 'nova'
      final ordersResponse = await _supabase
          .from('Objednavky')
          .select()
          .eq('uzivatel_id', userId)
          .eq('stav', 'nova')
          .order('datum_objednavky', ascending: false)
          .limit(1);

      if (ordersResponse.isNotEmpty) {
        return ordersResponse.first;
      }

      // Vytvořit novou objednávku, pokud neexistuje
      final newOrder = await _supabase
          .from('Objednavky')
          .insert({
            'uzivatel_id': userId,
            'datum_objednavky': DateTime.now().toIso8601String(),
            'stav': 'nova',
            'celkova_cena': 0,
          })
          .select()
          .single();

      return newOrder;
    } catch (e) {
      rethrow;
    }
  }

  // Přidat položku do objednávky
  Future<void> addItemToOrder({
    required int zboziId,
    required int mnozstvi,
  }) async {
    try {
      // Získat aktuální objednávku
      final order = await getCurrentOrder();
      final orderId = order['id'];

      // Zkontrolovat, jestli položka už v objednávce není
      final existingItems = await _supabase
          .from('ObjednavkaZbozi')
          .select()
          .eq('objednavka_id', orderId)
          .eq('zbozi_id', zboziId);

      if (existingItems.isNotEmpty) {
        // Aktualizovat množství
        final currentMnozstvi = existingItems.first['mnozstvi'] as int;
        await _supabase
            .from('ObjednavkaZbozi')
            .update({'mnozstvi': currentMnozstvi + mnozstvi})
            .eq('id', existingItems.first['id']);
      } else {
        // Vložit novou položku
        await _supabase.from('ObjednavkaZbozi').insert({
          'objednavka_id': orderId,
          'zbozi_id': zboziId,
          'mnozstvi': mnozstvi,
        });
      }

      // Aktualizovat celkovou cenu objednávky
      await updateOrderTotalPrice(orderId);
    } catch (e) {
      rethrow;
    }
  }

  // Aktualizovat celkovou cenu objednávky
  Future<void> updateOrderTotalPrice(int orderId) async {
    try {
      // Získat všechny položky objednávky
      final items = await _supabase
          .from('ObjednavkaZbozi')
          .select('mnozstvi, zbozi_id, Receptury(cena)')
          .eq('objednavka_id', orderId);

      double totalPrice = 0;
      for (var item in items) {
        final mnozstvi = item['mnozstvi'] as int;
        final cena = item['Receptury']['cena'] as num;
        totalPrice += mnozstvi * cena;
      }

      
      await _supabase
          .from('Objednavky')
          .update({'celkova_cena': totalPrice})
          .eq('id', orderId);
    } catch (e) {
      rethrow;
    }
  }

  // Získat všechny objednávky uživatele
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final userEmail = _supabase.auth.currentUser!.email!;

      // Získat ID uživatele
      final userResponse = await _supabase
          .from('Uzivatel')
          .select('id')
          .eq('mail', userEmail)
          .single();

      final userId = userResponse['id'];

      // Získat všechny objednávky uživatele kromě 'nova'
      final orders = await _supabase
          .from('Objednavky')
          .select()
          .eq('uzivatel_id', userId)
          .neq('stav', 'nova')
          .order('datum_objednavky', ascending: false);

      return List<Map<String, dynamic>>.from(orders);
    } catch (e) {
      rethrow;
    }
  }

  // Získat položky objednávky s detaily produktů
  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    try {
      final items = await _supabase
          .from('ObjednavkaZbozi')
          .select('*, Receptury(*)')
          .eq('objednavka_id', orderId);

      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      rethrow;
    }
  }

  // Odebrat položku z objednávky
  Future<void> removeItemFromOrder(int itemId, int orderId) async {
    try {
      await _supabase
          .from('ObjednavkaZbozi')
          .delete()
          .eq('id', itemId);

      // Aktualizovat celkovou cenu
      await updateOrderTotalPrice(orderId);
    } catch (e) {
      rethrow;
    }
  }

  // Potvrdit objednávku (změnit stav)
  Future<void> confirmOrder(int orderId) async {
    try {
      await _supabase
          .from('Objednavky')
          .update({'stav': 'potvrzena'})
          .eq('id', orderId);
    } catch (e) {
      rethrow;
    }
  }

  // Smazat objednávku
  Future<void> deleteOrder(int orderId) async {
    try {
      // Nejprve smazat všechny položky objednávky
      await _supabase
          .from('ObjednavkaZbozi')
          .delete()
          .eq('objednavka_id', orderId);

      // Pak smazat objednávku
      await _supabase
          .from('Objednavky')
          .delete()
          .eq('id', orderId);
    } catch (e) {
      rethrow;
    }
  }

  
  Future<Map<String, dynamic>?> getCurrentCart() async {
    try {
      final order = await getCurrentOrder();
      final items = await getOrderItems(order['id']);
      
      return {
        'order': order,
        'items': items,
      };
    } catch (e) {
      return null;
    }
  }

  // Získat všechny objednávky (pro admina)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final orders = await _supabase
          .from('Objednavky')
          .select('*, Uzivatel(jmeno, prijmeni, mail)')
          .order('datum_objednavky', ascending: false);

      return List<Map<String, dynamic>>.from(orders);
    } catch (e) {
      rethrow;
    }
  }
}
