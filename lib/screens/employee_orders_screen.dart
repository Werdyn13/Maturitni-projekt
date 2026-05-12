import 'package:flutter/material.dart';
import '../services/orders_service.dart';

class EmployeeOrdersScreen extends StatefulWidget {
  const EmployeeOrdersScreen({super.key});

  @override
  State<EmployeeOrdersScreen> createState() => _EmployeeOrdersScreenState();
}

class _EmployeeOrdersScreenState extends State<EmployeeOrdersScreen> {
  final OrdersService _ordersService = OrdersService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final orders = await _ordersService.getAllOrders();
      final confirmedOrders = orders
          .where((order) => order['stav']?.toString() == 'potvrzena')
          .toList();
      setState(() {
        _orders = confirmedOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba pri nacitani objednavek: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showOrderDetails(int orderId) async {
    try {
      final items = await _ordersService.getOrderItems(orderId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Obsah objednavky'),
          content: SizedBox(
            width: double.maxFinite,
            child: items.isEmpty
                ? const Center(child: Text('Objednavka neobsahuje zadne polozky'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final product = item['Receptury'] ?? {};
                      final mnozstvi = item['mnozstvi'] ?? 0;

                      return ListTile(
                        title: Text(product['nazev']?.toString() ?? 'Bez nazvu'),
                        subtitle: Text('Pocet kusu: $mnozstvi'),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zavrit'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba pri nacitani polozek: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatOrderDate(dynamic dateValue) {
    if (dateValue == null) {
      return 'N/A';
    }

    try {
      final parsed = DateTime.parse(dateValue.toString());
      return '${parsed.day}.${parsed.month}.${parsed.year} ${parsed.hour}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Objednavky',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Obnovit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _orders.isEmpty
                ? const Center(
                    child: Text(
                      'Nejsou dostupne zadne objednavky',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final createdAt = _formatOrderDate(order['datum_objednavky']);

                      final user = order['Uzivatel'];
                      final creatorName = user != null
                          ? '${user['jmeno'] ?? ''} ${user['prijmeni'] ?? ''}'.trim()
                          : 'Neznamy';

                      return Card(
                        child: ListTile(
                          title: Text(
                            'Objednávka #${order['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vytvořeno: $createdAt'),
                              Text('Zákazník: $creatorName'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: TextButton.icon(
                            onPressed: () => _showOrderDetails(order['id'] as int),
                            icon: const Icon(Icons.visibility),
                            label: const Text('Obsah'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
