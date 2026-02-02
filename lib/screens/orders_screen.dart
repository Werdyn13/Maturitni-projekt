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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentOrder();
  }

  Future<void> _loadCurrentOrder() async {
    try {
      final cart = await _ordersService.getCurrentCart();
      setState(() {
        _currentCart = cart;
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

    try {
      final orderId = _currentCart!['order']['id'];
      await _ordersService.updateOrderStatus(orderId, 'potvrzena');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Objednávka byla úspěšně dokončena!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload a vytvoření nové prázdné objednávky
      await _loadCurrentOrder();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při dokončování objednávky: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    final mnozstvi = item['mnozstvi'] ?? 0;
    final celkovaCena = cena * mnozstvi;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nazev,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Množství: $mnozstvi ks',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cena za kus: $cena Kč',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$celkovaCena Kč',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => _removeItem(item['id'], orderId),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Odebrat položku',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
