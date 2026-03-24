import 'package:flutter/material.dart';
import '../widgets/app_bar_widget.dart';
import '../services/orders_service.dart';
import 'order_history_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrdersService _ordersService = OrdersService();
  Map<String, dynamic>? _currentCart;
  List<Map<String, dynamic>> _draftOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentOrder();
  }

  Future<void> _loadCurrentOrder() async {
    try {
      final cart = await _ordersService.getCurrentCart();
      final drafts = await _ordersService.getDraftOrders();
      setState(() {
        _currentCart = cart;
        _draftOrders = drafts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOrder() async {
    if (_currentCart == null || _currentCart!['items'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nelze dokončit prázdnou objednávku'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Zobrazit dialog pro výběr opakování
    String? pickedOpakovat;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Opakování objednávky'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chcete tuto objednávku automaticky opakovat?'),
              const SizedBox(height: 12),
              for (final opt in ['Žádné', 'Týdně', 'Měsíčně'])
                RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  groupValue: pickedOpakovat ?? 'Žádné',
                  onChanged: (v) => setDialogState(() => pickedOpakovat = v),
                  dense: true,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Potvrdit objednávku'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final orderId = _currentCart!['order']['id'];
      final opakovat = (pickedOpakovat == null || pickedOpakovat == 'Žádné')
          ? null
          : pickedOpakovat;
      await _ordersService.confirmOrderWithRepeat(orderId, opakovat);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Objednávka byla úspěšně odeslána!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCurrentOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při odesilání objednávky: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(int itemId, int orderId, int currentQty, int delta) async {
    try {
      await _ordersService.updateItemQuantity(itemId, orderId, currentQty + delta);
      await _loadCurrentOrder();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při změně množství: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeItem(int itemId, int orderId) async {
    try {
      await _ordersService.removeItemFromOrder(itemId, orderId);
      await _loadCurrentOrder();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Položka byla odebrána'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při odebírání položky: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDraft(int orderId) async {
    try {
      await _ordersService.confirmDraftOrder(orderId);
      await _loadCurrentOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Objednávka potvrzena'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editDraft(int orderId) async {
    try {
      await _ordersService.editDraftOrder(orderId);
      await _loadCurrentOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Objednávka přesunuta do košíku'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelDraft(int orderId) async {
    try {
      await _ordersService.cancelDraftOrder(orderId);
      await _loadCurrentOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navrhovaná objednávka zrušena'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _currentCart?['items'] as List<Map<String, dynamic>>? ?? [];
    final order = _currentCart?['order'] as Map<String, dynamic>?;
    final totalPrice = order?['celkova_cena'] ?? 0;

    return Scaffold(
      appBar: const AppBarWidget(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Aktuální objednávka',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const OrderHistoryScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.history),
                                  label: const Text(
                                    'Historie objednávek',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            if (_draftOrders.isNotEmpty) ...[  
                              const Text(
                                'Navrhované objednávky',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._draftOrders.map((d) => _buildDraftCard(d)),
                              const Divider(height: 48, thickness: 1),
                            ],
                            if (items.isEmpty)
                              Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(40.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Vaše objednávka je prázdná',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Přidejte produkty z nabídky',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              ...items.map((item) => _buildOrderItemCard(item, order!['id'])),
                              const SizedBox(height: 24),
                              Card(
                                elevation: 4,
                                color: Colors.grey[100],
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Celková cena:',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        '$totalPrice Kč',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton.icon(
                                  onPressed: _completeOrder,
                                  icon: const Icon(Icons.check_circle, size: 28),
                                  label: const Text(
                                    'Dokončit objednávku',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              children: [
                Text(
                  '© 2025 Bánovská pekárna',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(Map<String, dynamic> item, int orderId) {
    final receptura = item['Receptury'] as Map<String, dynamic>;
    final nazev = receptura['nazev'] ?? 'Neznámý produkt';
    final cena = receptura['cena'] ?? 0;
    final mnozstvi = item['mnozstvi'] as int? ?? 0;
    final celkovaCena = cena * mnozstvi;
    final itemId = item['id'] as int;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nazev,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cena Kč / ks',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            
            IconButton(
              onPressed: () => _updateQuantity(itemId, orderId, mnozstvi, -1),
              icon: const Icon(Icons.remove, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                shape: const CircleBorder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$mnozstvi',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _updateQuantity(itemId, orderId, mnozstvi, 1),
              icon: const Icon(Icons.add, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                shape: const CircleBorder(),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 72,
              child: Text(
                '$celkovaCena Kč',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _removeItem(itemId, orderId),
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              color: Colors.grey[400],
              tooltip: 'Odebrat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> draft) {
    final order = draft['order'] as Map<String, dynamic>;
    final items = draft['items'] as List<Map<String, dynamic>>;
    final orderId = order['id'] as int;
    final opakovat = order['opakovat'] as String?;
    final totalPrice = order['celkova_cena'] ?? 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.replay, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  opakovat != null ? 'Opakovaná objednávka ($opakovat)' : 'Navrhovaná objednávka',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '$totalPrice Kč',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) {
              final receptura = item['Receptury'] as Map<String, dynamic>? ?? {};
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${receptura['nazev'] ?? 'Produkt'} × ${item['mnozstvi']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              );
            }),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelDraft(orderId),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Zrušit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editDraft(orderId),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Upravit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDraft(orderId),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Potvrdit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
