import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Získat nebo vytvořit aktuální objednávku uživatele (stav = 'nova - čeká na potvrzení')
  Future<Map<String, dynamic>> getCurrentOrder() async {
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
  }

  // Přidat položku do objednávky
  Future<void> addItemToOrder({
    required int zboziId,
    required int mnozstvi,
  }) async {
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

    
    await updateOrderTotalPrice(orderId);
  }

  // Aktualizovat celkovou cenu objednávky
  Future<void> updateOrderTotalPrice(int orderId) async {
    // Získat všechny položky objednávky
    final items = await _supabase
        .from('ObjednavkaZbozi')
        .select('mnozstvi, zbozi_id, Receptury(cena)')
        .eq('objednavka_id', orderId);

    int totalPrice = 0;
    for (var item in items) {
      final mnozstvi = (item['mnozstvi'] as num?)?.toInt() ?? 0;
      final cena = (item['Receptury']?['cena'] as num?) ?? 0;
      totalPrice += (mnozstvi * cena).round();
    }

    // Uložit novou celkovou cenu
    await _supabase
        .from('Objednavky')
        .update({'celkova_cena': totalPrice})
        .eq('id', orderId);
  }

  // Získat všechny objednávky uživatele
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    final userEmail = _supabase.auth.currentUser!.email!;

    // Získat ID uživatele
    final userResponse = await _supabase
        .from('Uzivatel')
        .select('id')
        .eq('mail', userEmail)
        .single();

    final userId = userResponse['id'];

    // Získat všechny objednávky uživatele kromě 'nova' a 'navrh'
    final orders = await _supabase
        .from('Objednavky')
        .select()
        .eq('uzivatel_id', userId)
        .neq('stav', 'nova')
        .neq('stav', 'navrh')
        .order('datum_objednavky', ascending: false);

    return List<Map<String, dynamic>>.from(orders);
  }

  // Získat položky objednávky s detaily produktů
  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final items = await _supabase
        .from('ObjednavkaZbozi')
        .select('*, Receptury(*)')
        .eq('objednavka_id', orderId);

    return List<Map<String, dynamic>>.from(items);
  }

  // Odebrat položku z objednávky
  Future<void> removeItemFromOrder(int itemId, int orderId) async {
    await _supabase
        .from('ObjednavkaZbozi')
        .delete()
        .eq('id', itemId);

    // Aktualizovat celkovou cenu
    await updateOrderTotalPrice(orderId);
  }

  // Potvrdit objednávku (změnit stav)
  Future<void> confirmOrder(int orderId) async {
    await _supabase
        .from('Objednavky')
        .update({'stav': 'potvrzena'})
        .eq('id', orderId);
  }

  // Aktualizovat stav objednávky
  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    await _supabase
        .from('Objednavky')
        .update({'stav': newStatus})
        .eq('id', orderId);
  }

  // Smazat objednávku
  Future<void> deleteOrder(int orderId) async {
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
  }

  // Aktualizovat množství položky; pokud klesne na 0, položku smaže
  Future<void> updateItemQuantity(int itemId, int orderId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItemFromOrder(itemId, orderId);
    } else {
      await _supabase
          .from('ObjednavkaZbozi')
          .update({'mnozstvi': newQuantity})
          .eq('id', itemId);
      await updateOrderTotalPrice(orderId);
    }
  }

  // Získat aktuální košík (objednávku + položky)
  Future<Map<String, dynamic>?> getCurrentCart() async {
    final order = await getCurrentOrder();
    final items = await getOrderItems(order['id']);

    return {
      'order': order,
      'items': items,
    };
  }

  // Získat všechny objednávky (pro admina)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final orders = await _supabase
        .from('Objednavky')
        .select('*, Uzivatel(jmeno, prijmeni, mail)')
        .neq('stav', 'nova')
        .order('datum_objednavky', ascending: false);

    return List<Map<String, dynamic>>.from(orders);
  }

  // Potvrdit objednávku s nastavením opakování
  Future<void> confirmOrderWithRepeat(int orderId, String? opakovat) async {
    await _supabase
        .from('Objednavky')
        .update({'stav': 'potvrzena', 'opakovat': opakovat})
        .eq('id', orderId);
  }

  // Získat navrhované objednávky pro aktuálního uživatele
  Future<List<Map<String, dynamic>>> getDraftOrders() async {
    final userEmail = _supabase.auth.currentUser!.email!;
    final userResponse = await _supabase
        .from('Uzivatel')
        .select('id')
        .eq('mail', userEmail)
        .single();
    final userId = userResponse['id'];

    final orders = await _supabase
        .from('Objednavky')
        .select()
        .eq('uzivatel_id', userId)
        .eq('stav', 'navrh')
        .order('datum_objednavky', ascending: false);

    final result = <Map<String, dynamic>>[];
    for (final order in orders) {
      final items = await getOrderItems(order['id']);
      result.add({'order': order, 'items': items});
    }
    return result;
  }

  // Vytvořit opakující se kopii objednávky jako návrh
  Future<void> repeatOrder(int orderId) async {
    final original = await _supabase
        .from('Objednavky')
        .select()
        .eq('id', orderId)
        .single();

    final newOrder = await _supabase
        .from('Objednavky')
        .insert({
          'uzivatel_id': original['uzivatel_id'],
          'datum_objednavky': DateTime.now().toIso8601String(),
          'stav': 'navrh',
          'celkova_cena': original['celkova_cena'],
          'opakovat': original['opakovat'],
        })
        .select()
        .single();

    final items = await _supabase
        .from('ObjednavkaZbozi')
        .select()
        .eq('objednavka_id', orderId);

    for (final item in items) {
      await _supabase.from('ObjednavkaZbozi').insert({
        'objednavka_id': newOrder['id'],
        'zbozi_id': item['zbozi_id'],
        'mnozstvi': item['mnozstvi'],
      });
    }
  }

  // Přímo potvrdit navrhovanou objednávku (navrh -> potvrzena)
  Future<void> confirmDraftOrder(int orderId) async {
    await _supabase
        .from('Objednavky')
        .update({'stav': 'potvrzena'})
        .eq('id', orderId);
  }

  // Přesunout návrh do košíku (sloučit s aktivní nova objednávkou)
  Future<void> editDraftOrder(int orderId) async {
    final activeCart = await getCurrentOrder();
    final activeId = activeCart['id'] as int;

    final draftItems = await _supabase
        .from('ObjednavkaZbozi')
        .select()
        .eq('objednavka_id', orderId);

    for (final item in draftItems) {
      final zboziId = item['zbozi_id'] as int;
      final mnozstvi = item['mnozstvi'] as int;

      final existing = await _supabase
          .from('ObjednavkaZbozi')
          .select()
          .eq('objednavka_id', activeId)
          .eq('zbozi_id', zboziId);

      if (existing.isNotEmpty) {
        await _supabase
            .from('ObjednavkaZbozi')
            .update({'mnozstvi': (existing.first['mnozstvi'] as int) + mnozstvi})
            .eq('id', existing.first['id']);
      } else {
        await _supabase.from('ObjednavkaZbozi').insert({
          'objednavka_id': activeId,
          'zbozi_id': zboziId,
          'mnozstvi': mnozstvi,
        });
      }
    }

    await deleteOrder(orderId);
    await updateOrderTotalPrice(activeId);
  }

  // Zrušit navrhovanou objednávku
  Future<void> cancelDraftOrder(int orderId) async {
    await deleteOrder(orderId);
  }

  // Odeslat email uživateli, že jeho objednávka je připravena
  Future<void> sendOrderReadyEmail({
    required String userEmail,
    required String userName,
    required int orderId,
    required num orderTotal,
  }) async {
    await _supabase.functions.invoke(
      'send-order-ready-email',
      body: {
        'userEmail': userEmail,
        'userName': userName,
        'orderId': orderId,
        'orderTotal': orderTotal,
      },
    );
  }
}
