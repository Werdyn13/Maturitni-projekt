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

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _ordersService.updateOrderStatus(orderId, newStatus);
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stav objednávky byl změněn'),
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

  Future<void> _showOrderDetails(int orderId) async {
    try {
      final items = await _ordersService.getOrderItems(orderId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Obsah objednávky'),
          content: SizedBox(
            width: double.maxFinite,
            child: items.isEmpty
                ? const Center(
                    child: Text('Objednávka neobsahuje žádné položky'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final product = item['Receptury'] ?? {};
                      final mnozstvi = item['mnozstvi'] ?? 0;
                      final cena = product['cena'] ?? 0;
                      final celkovaHodnota = mnozstvi * cena;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['nazev'] ?? 'Bez názvu',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Počet kusů: $mnozstvi',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Cena za kus: $cena Kč',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Celk: $celkovaHodnota Kč',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zavřít'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při načítání položek: $e'),
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


    final columns = <PlutoColumn>[
      PlutoColumn(
        title: 'Datum',
        field: 'datum',
        type: PlutoColumnType.text(),
        width: 160,
        enableEditingMode: false,
        enableSorting: true,
      ),
      PlutoColumn(
        title: 'Zákazník',
        field: 'zakaznik',
        type: PlutoColumnType.text(),
        width: 250,
        enableSorting: true,
        renderer: (rendererContext) {
          final email = _orders[rendererContext.rowIdx]['Uzivatel']?['mail'] ?? ' ';

          return Tooltip(
            message: email,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(rendererContext.cell.value?.toString() ?? ''),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Celková cena',
        field: 'cena',
        type: PlutoColumnType.number(),
        width: 120,
        enableSorting: true,
        renderer: (rendererContext) {
          return Align(
            alignment: Alignment.centerRight,
            child: Text('${rendererContext.cell.value} Kč',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
      PlutoColumn(
        title: 'Stav',
        field: 'stav',
        type: PlutoColumnType.text(),
        width: 130,
        enableSorting: true,
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

          return Center(
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
                    fontSize: 12),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Akce',
        field: 'akce',
        type: PlutoColumnType.text(),
        width: 200,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          final order = _orders[rendererContext.rowIdx];
          final status = order['stav'].toString();

          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: DropdownButton<String>(
                  value: status,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'nova', child: Text('Nová', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'potvrzena', child: Text('Potvrzená', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'pripravena', child: Text('Připravená', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'dokoncena', child: Text('Dokončená', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'zrusena', child: Text('Zrušená', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (newStatus) {
                    if (newStatus != null && newStatus != status) {
                      _updateOrderStatus(order['id'], newStatus);
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Zobrazit obsah',
                onPressed: () => _showOrderDetails(order['id']),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _deleteOrder(order['id']),
              ),
            ],
          );
        },
      ),
    ];

    final rows = _orders.map((order) {
      String formattedDate = 'N/A';

      if (order['datum_objednavky'] != null) {
        try {
          final datum = DateTime.parse(order['datum_objednavky']);
          formattedDate =
              '${datum.day}.${datum.month}.${datum.year} ${datum.hour}:${datum.minute.toString().padLeft(2, '0')}';
        } catch (_) {
          formattedDate = order['datum_objednavky'].toString();
        }
      }

      final zakaznik = order['Uzivatel'] != null
          ? '${order['Uzivatel']['jmeno'] ?? ''} ${order['Uzivatel']['prijmeni'] ?? ''}'
          : 'N/A';

      return PlutoRow(
        cells: {
          'datum': PlutoCell(value: formattedDate),
          'zakaznik': PlutoCell(value: zakaznik),
          'cena': PlutoCell(value: order['celkova_cena'] ?? 0),
          'stav': PlutoCell(value: order['stav'] ?? ''),
          'akce': PlutoCell(value: ''),
        },
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Objednávky',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold),
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

          const SizedBox(height: 24),

          
          Expanded(
            child: Card(
              child: PlutoGrid(
                columns: columns,
                rows: rows,
                onLoaded: (event) {
                  stateManager = event.stateManager;
                  stateManager!.setShowColumnFilter(true);
                },
                configuration: PlutoGridConfiguration(
                  columnSize: const PlutoGridColumnSizeConfig(
                    autoSizeMode: PlutoAutoSizeMode.scale,
                  ),
                  columnFilter: PlutoGridColumnFilterConfig(),
                  style: PlutoGridStyleConfig(
                    gridBorderRadius: BorderRadius.circular(8),
                    rowHeight: 50,
                    columnHeight: 50,
                  ),
                  scrollbar: const PlutoGridScrollbarConfig(
                    isAlwaysShown: true,
                    scrollbarThickness: 8,
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