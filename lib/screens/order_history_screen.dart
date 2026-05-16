import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/app_bar_widget.dart';
import '../services/orders_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrdersService _ordersService = OrdersService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _ordersService.getUserOrders();
      // Načítání produktů pro objednávky
      final enriched = await Future.wait(
        orders.map((order) async {
          final items = await _ordersService.getOrderItems(order['id'] as int);
          return {...order, 'items': items};
        }),
      );
      setState(() {
        _orders = enriched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getOrdersForDay(DateTime day) {
    return _orders.where((order) {
      final orderDate = DateTime.parse(order['datum_objednavky']);
      return orderDate.year == day.year &&
          orderDate.month == day.month &&
          orderDate.day == day.day;
    }).toList();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'nova':
        return Colors.blue;
      case 'potvrzena':
        return Colors.orange;
      case 'pripravena':
        return Colors.purple;
      case 'dokoncena':
        return Colors.green;
      case 'zrusena':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedOrders =
        _selectedDay != null ? _getOrdersForDay(_selectedDay!) : <Map<String, dynamic>>[];

    return Scaffold(
      appBar: const AppBarWidget(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Historie objednávek',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Kalendář
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: TableCalendar(
                                  locale: 'cs_CZ',
                                  firstDay: DateTime.utc(2020, 1, 1),
                                  lastDay: DateTime.utc(2030, 12, 31),
                                  focusedDay: _focusedDay,
                                  selectedDayPredicate: (day) =>
                                      isSameDay(_selectedDay, day),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDay = isSameDay(_selectedDay, selectedDay)
                                          ? null
                                          : selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                  },
                                  eventLoader: _getOrdersForDay,
                                  calendarFormat: CalendarFormat.month,
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: 'Měsíc',
                                  },
                                  calendarStyle: const CalendarStyle(
                                    markerDecoration: BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    todayDecoration: BoxDecoration(
                                      color: Color(0xFF757575),
                                      shape: BoxShape.circle,
                                    ),
                                    markersMaxCount: 1,
                                  ),
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    titleTextStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  daysOfWeekStyle: const DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(fontSize: 12),
                                    weekendStyle: TextStyle(
                                        fontSize: 12, color: Colors.red),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Zobrazit objednávky pro vybraný den
                            if (_selectedDay != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${selectedOrders.length} objednávek',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (selectedOrders.isEmpty)
                                Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.event_busy,
                                            size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Žádné objednávky pro tento den',
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
                              else
                                ...selectedOrders
                                    .map((order) => _buildOrderCard(order)),
                            ] else if (_orders.isEmpty) ...[
                              Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(40.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.shopping_basket_outlined,
                                          size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Zatím nemáte žádné objednávky',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Vaše budoucí objednávky se zobrazí v kalendáři',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              Center(
                                child: Text(
                                  'Vyberte den v kalendáři pro zobrazení objednávek',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
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
            child: const Text(
              '© 2025 Bánovská pekárna',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final datum = DateTime.parse(order['datum_objednavky']);
    final formattedDate =
        '${datum.day}.${datum.month}.${datum.year} ${datum.hour}:${datum.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Objednávka #${order['id']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['stav']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order['stav']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 8),
            // Items list
            if (order['items'] != null && (order['items'] as List).isNotEmpty) ...
              (order['items'] as List<Map<String, dynamic>>).map((item) {
                final produkt = item['Receptury'] as Map<String, dynamic>?;
                final nazev = produkt?['nazev'] ?? 'Neznámý produkt';
                final mnozstvi = item['mnozstvi'] ?? 0;
                final cena = produkt?['cena'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          nazev,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${mnozstvi}×',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(mnozstvi * (cena as num)).round()} Kč',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                );
              }).toList()
            else
              Text(
                'Žádné položky',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Celková cena:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${order['celkova_cena']} Kč',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
