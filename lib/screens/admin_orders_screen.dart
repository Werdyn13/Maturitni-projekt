import 'package:flutter/material.dart';
import '../services/orders_service.dart';
import 'package:pluto_grid/pluto_grid.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final OrdersService _ordersService = OrdersService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  PlutoGridStateManager? stateManager;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final orders = await _ordersService.getAllOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při načítání objednávek: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'nova':
        return 'Nová';
      case 'potvrzena':
        return 'Potvrzená';
      case 'pripravena':
        return 'Připravená';
      case 'dokoncena':
        return 'Dokončená';
      case 'zrusena':
        return 'Zrušená';
      default:
        return status;
    }
  }

  Future<void> _acceptOrder(int orderId) async {
    try {
      await _ordersService.confirmOrder(orderId);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Objednávka byla přijata'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdit smazání'),
        content: const Text('Opravdu chcete smazat tuto objednávku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _ordersService.deleteOrder(orderId);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Objednávka byla smazána'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // PlutoGrid sloupce
    final columns = <PlutoColumn>[
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.number(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Datum',
        field: 'datum',
        type: PlutoColumnType.text(),
        width: 160,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Zákazník',
        field: 'zakaznik',
        type: PlutoColumnType.text(),
        width: 250,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Email',
        field: 'email',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Celková cena',
        field: 'cena',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${rendererContext.cell.value} Kč',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Stav',
        field: 'stav',
        type: PlutoColumnType.text(),
        width: 130,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final status = rendererContext.cell.value?.toString() ?? '';
          Color bgColor;
          switch (status) {
            case 'nova':
              bgColor = Colors.blue;
              break;
            case 'potvrzena':
              bgColor = Colors.orange;
              break;
            case 'pripravena':
              bgColor = Colors.purple;
              break;
            case 'dokoncena':
              bgColor = Colors.green;
              break;
            case 'zrusena':
              bgColor = Colors.red;
              break;
            default:
              bgColor = Colors.grey;
          }

          return Container(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(status),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Akce',
        field: 'akce',
        type: PlutoColumnType.text(),
        width: 140,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final order = _orders[rendererContext.rowIdx];
          final status = order['stav'].toString();
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (status == 'nova')
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  tooltip: 'Přijmout',
                  onPressed: () => _acceptOrder(order['id']),
                ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Smazat',
                onPressed: () => _deleteOrder(order['id']),
              ),
            ],
          );
        },
      ),
    ];

    // PlutoGrid řádky
    final rows = _orders.map((order) {
      String formattedDate = 'N/A';
      if (order['datum_objednavky'] != null) {
        try {
          final datum = DateTime.parse(order['datum_objednavky']);
          formattedDate = '${datum.day}.${datum.month}.${datum.year} ${datum.hour}:${datum.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          formattedDate = order['datum_objednavky'].toString();
        }
      }
      
      final zakaznik = order['Uzivatel'] != null
          ? '${order['Uzivatel']['jmeno'] ?? ''} ${order['Uzivatel']['prijmeni'] ?? ''}'
          : 'N/A';
      final email = order['Uzivatel'] != null ? (order['Uzivatel']['mail'] ?? 'N/A') : 'N/A';

      return PlutoRow(
        cells: {
          'id': PlutoCell(value: order['id'] ?? 0),
          'datum': PlutoCell(value: formattedDate),
          'zakaznik': PlutoCell(value: zakaznik),
          'email': PlutoCell(value: email),
          'cena': PlutoCell(value: order['celkova_cena'] ?? 0),
          'stav': PlutoCell(value: order['stav'] ?? ''),
          'akce': PlutoCell(value: ''),
        },
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Objednávky',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Celkem objednávek: ${_orders.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Obnovit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Žádné objednávky',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Card(
                    elevation: 2,
                    child: PlutoGrid(
                      key: ValueKey(_orders.length),
                      columns: columns,
                      rows: rows,
                      onLoaded: (PlutoGridOnLoadedEvent event) {
                        stateManager = event.stateManager;
                      },
                      configuration: PlutoGridConfiguration(
                        style: PlutoGridStyleConfig(
                          gridBorderColor: Colors.grey[300]!,
                          gridBorderRadius: BorderRadius.circular(8),
                          rowHeight: 50,
                          columnHeight: 50,
                          cellTextStyle: const TextStyle(fontSize: 14),
                          columnTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          defaultCellPadding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
