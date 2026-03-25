import 'package:flutter/material.dart';
import '../services/smeny_service.dart';
import '../services/auth_service.dart';

class AdminShiftsScreen extends StatefulWidget {
  const AdminShiftsScreen({super.key});

  @override
  State<AdminShiftsScreen> createState() => _AdminShiftsScreenState();
}

class _AdminShiftsScreenState extends State<AdminShiftsScreen> {
  final SmenyService _smenyService = SmenyService();
  final AuthService _authService = AuthService();

  // Klíč: 'userId_RRRR-MM-DD', hodnota: řádek směny
  Map<String, Map<String, dynamic>> _shiftMap = {};
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  late DateTime _weekMonday;

  static const _dayNames = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
  static const _druhOptions = ['Ranní', 'Odpolední', 'Noční'];

  @override
  void initState() {
    super.initState();
    _weekMonday = _getMonday(DateTime.now());
    _load();
  }

  DateTime _getMonday(DateTime d) {
    return DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: d.weekday - 1));
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _smenyService.getShiftsForWeek(_weekMonday),
        _authService.getEmployees(),
      ]);
      final shifts = results[0];
      final employees = results[1];

      final map = <String, Map<String, dynamic>>{};
      for (final s in shifts) {
        final uzivatel = s['Uzivatel'] as Map<String, dynamic>?;
        if (uzivatel == null) continue;
        final uid = uzivatel['id'].toString();
        final dt = DateTime.tryParse(s['datum'] ?? '');
        if (dt == null) continue;
        final key =
            '${uid}_${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        map[key] = s;
      }

      setState(() {
        _shiftMap = map;
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _dayKey(int offset) {
    final d = _weekMonday.add(Duration(days: offset));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _weekLabel() {
    final end = _weekMonday.add(const Duration(days: 6));
    return '${_weekMonday.day}.${_weekMonday.month}. – ${end.day}.${end.month}.${end.year}';
  }

  bool _isToday(int offset) {
    final d = _weekMonday.add(Duration(days: offset));
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  (Color, String) _shiftStyle(String? druh) {
    switch (druh) {
      case 'Ranní':
        return (Colors.orange, 'R');
      case 'Odpolední':
        return (Colors.blue, 'O');
      case 'Noční':
        return (Colors.indigo, 'N');
      default:
        return (Colors.teal, druh?.substring(0, 1).toUpperCase() ?? '?');
    }
  }

  Future<void> _onCellTap(
      Map<String, dynamic> employee, int dayOffset) async {
    final empId = employee['id'] as int;
    final empName =
        '${employee['jmeno'] ?? ''} ${employee['prijmeni'] ?? ''}'.trim();
    final date = _weekMonday.add(Duration(days: dayOffset));
    final key =
        '${empId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final existing = _shiftMap[key];

    final messenger = ScaffoldMessenger.of(context);

    if (existing != null) {
      // Existující směna – zobrazit dialog pro změnu/odebrání
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
              '${existing['druh_smeny'] ?? 'Směna'} – $empName\n${date.day}.${date.month}.${date.year}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Změnit druh:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _druhOptions.map((d) {
                  final (color, _) = _shiftStyle(d);
                  final isActive = existing['druh_smeny'] == d;
                  return ChoiceChip(
                    label: Text(d),
                    selected: isActive,
                    selectedColor: color.withOpacity(0.2),
                    onSelected: (_) => Navigator.pop(ctx, d),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Zrušit'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, '__delete__'),
              child: const Text('Odebrat směnu'),
            ),
          ],
        ),
      );

      if (choice == null) return;
      try {
        if (choice == '__delete__') {
          await _smenyService.deleteShift(existing['id'] as int);
        } else {
          // Aktualizace = smazat starou + vložit novou se stejným datem, ale jiným druhem
          await _smenyService.deleteShift(existing['id'] as int);
          await _smenyService.addShift(
            zamestnanecId: empId,
            datum: date,
            druhSmeny: choice,
          );
        }
        await _load();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      // Prázdná buňka – přidat novou směnu
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
              'Přidat směnu – $empName\n${date.day}.${date.month}.${date.year}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: _druhOptions.map((d) {
                  final (color, _) = _shiftStyle(d);
                  return ChoiceChip(
                    label: Text(d),
                    selected: false,
                    selectedColor: color.withOpacity(0.2),
                    onSelected: (_) => Navigator.pop(ctx, d),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Zrušit'),
            ),
          ],
        ),
      );

      if (choice == null) return;
      try {
        await _smenyService.addShift(
          zamestnanecId: empId,
          datum: date,
          druhSmeny: choice,
        );
        await _load();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Směny',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Obnovit',
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Navigace po týdnech
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _weekMonday =
                      _weekMonday.subtract(const Duration(days: 7)));
                  _load();
                },
              ),
              Text(
                _weekLabel(),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() =>
                      _weekMonday = _weekMonday.add(const Duration(days: 7)));
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tabulka
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _employees.isEmpty
                    ? const Center(child: Text('Žádní zaměstnanci'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(Colors.grey[100]),
                            border: TableBorder.all(
                                color: Colors.grey.shade200, width: 1),
                            columnSpacing: 0,
                            columns: [
                              const DataColumn(
                                label: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('Zaměstnanec',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              ...List.generate(7, (i) {
                                final d =
                                    _weekMonday.add(Duration(days: i));
                                final today = _isToday(i);
                                return DataColumn(
                                  label: Container(
                                    width: 80,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    decoration: today
                                        ? BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          )
                                        : null,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_dayNames[i],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: today
                                                  ? Colors.white
                                                  : Colors.black,
                                            )),
                                        Text(
                                            '${d.day}.${d.month}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: today
                                                  ? Colors.white70
                                                  : Colors.grey,
                                            )),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                            rows: _employees.map((emp) {
                              final empId = emp['id'].toString();
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        '${emp['jmeno'] ?? ''} ${emp['prijmeni'] ?? ''}'
                                            .trim(),
                                      ),
                                    ),
                                  ),
                                  ...List.generate(7, (i) {
                                    final key =
                                        '${empId}_${_dayKey(i)}';
                                    final shift = _shiftMap[key];
                                    final druh =
                                        shift?['druh_smeny'] as String?;

                                    Widget cellContent;
                                    if (shift == null) {
                                      cellContent = Container(
                                        width: 80,
                                        height: 48,
                                        alignment: Alignment.center,
                                        child: Icon(Icons.add,
                                            size: 16,
                                            color: Colors.grey[300]),
                                      );
                                    } else {
                                      final (color, letter) =
                                          _shiftStyle(druh);
                                      cellContent = Container(
                                        width: 80,
                                        height: 48,
                                        alignment: Alignment.center,
                                        child: Tooltip(
                                          message: druh ?? 'Směna',
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color:
                                                  color.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: color
                                                      .withOpacity(0.5)),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              letter,
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return DataCell(
                                      InkWell(
                                        onTap: () => _onCellTap(emp, i),
                                        child: cellContent,
                                      ),
                                    );
                                  }),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                for (final druh in _druhOptions) ...[
                  Builder(builder: (_) {
                    final (color, letter) = _shiftStyle(druh);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: color.withOpacity(0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Text(letter,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        Text(druh,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 16),
                      ],
                    );
                  }),
                ],
                const SizedBox(width: 16),
                Icon(Icons.touch_app, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('Klikněte na buňku pro přidání/změnu/odebrání směny',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
