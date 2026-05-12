import 'package:flutter/material.dart';
import '../services/smeny_service.dart';

class EmployeeShiftsScreen extends StatefulWidget {
  const EmployeeShiftsScreen({super.key});

  @override
  State<EmployeeShiftsScreen> createState() => _EmployeeShiftsScreenState();
}

class _EmployeeShiftsScreenState extends State<EmployeeShiftsScreen> {
  final SmenyService _smenyService = SmenyService();

  // Klíč: 'RRRR-MM-DD', hodnota: řádek směny
  Map<String, Map<String, dynamic>> _shiftMap = {};
  bool _isLoading = true;
  late DateTime _weekMonday;

  static const _dayNames = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

  @override
  void initState() {
    super.initState();
    _weekMonday = _getMonday(DateTime.now());
    _load();
  }

  DateTime _getMonday(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final shifts =
          await _smenyService.getShiftsForCurrentUserAndWeek(_weekMonday);
      final map = <String, Map<String, dynamic>>{};
      for (final s in shifts) {
        final dt = DateTime.tryParse(s['datum'] ?? '');
        if (dt == null) continue;
        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        map[key] = s;
      }
      setState(() {
        _shiftMap = map;
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
    return '${_weekMonday.day}.${_weekMonday.month}.  ${end.day}.${end.month}.${end.year}';
  }

  bool _isToday(int offset) {
    final d = _weekMonday.add(Duration(days: offset));
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  (Color, String, String) _shiftStyle(String? druh) {
    switch (druh) {
      case 'Ranní':
        return (Colors.orange, 'R', 'Ranní');
      case 'Odpolední':
        return (Colors.blue, 'O', 'Odpolední');
      case 'Noční':
        return (Colors.indigo, 'N', 'Noční');
      default:
        return (Colors.teal, druh?.substring(0, 1).toUpperCase() ?? '?',
            druh ?? 'Směna');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Navigace po týdnech
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
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
        ),
        // 7 karet (dny v týdnu)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _isLoading
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()))
              : Row(
                  children: List.generate(7, (i) {
                    final today = _isToday(i);
                    final d = _weekMonday.add(Duration(days: i));
                    final key = _dayKey(i);
                    final shift = _shiftMap[key];
                    final druh = shift?['druh_smeny'] as String?;
                    final hasShift = shift != null;
                    final (color, letter, label) = _shiftStyle(druh);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: today
                              ? Colors.black
                              : hasShift
                                  ? color.withOpacity(0.08)
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: today
                              ? null
                              : Border.all(
                                  color: hasShift
                                      ? color.withOpacity(0.3)
                                      : Colors.grey.shade200,
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _dayNames[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: today ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d.day}.${d.month}',
                              style: TextStyle(
                                fontSize: 11,
                                color: today
                                    ? Colors.white70
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (hasShift)
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: today
                                      ? Colors.white.withOpacity(0.15)
                                      : color.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: today
                                        ? Colors.white.withOpacity(0.4)
                                        : color.withOpacity(0.5),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    color: today ? Colors.white : color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: 34,
                                height: 34,
                                child: Center(
                                  child: Text(
                                    '',
                                    style: TextStyle(
                                      color: today
                                          ? Colors.white38
                                          : Colors.grey.shade300,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              hasShift ? label : '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: today ? Colors.white70 : color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
        ),
        const SizedBox(height: 24),
        // Přehled směn v tomto týdnu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _isLoading
              ? const SizedBox.shrink()
              : _buildWeekSummary(),
        ),
      ],
    );
  }

  Widget _buildWeekSummary() {
    if (_shiftMap.isEmpty) {
      return Center(
        child: Text(
          'Tento týden nemáte žádné směny.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      );
    }

    final entries = <Map<String, dynamic>>[];
    for (var i = 0; i < 7; i++) {
      final key = _dayKey(i);
      final shift = _shiftMap[key];
      if (shift != null) {
        final d = _weekMonday.add(Duration(days: i));
        entries.add({'day': i, 'date': d, 'shift': shift});
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vaše směny tento týden',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        ...entries.map((e) {
          final d = e['date'] as DateTime;
          final shift = e['shift'] as Map<String, dynamic>;
          final druh = shift['druh_smeny'] as String?;
          final (color, _, label) = _shiftStyle(druh);
          final isToday = _isToday(e['day'] as int);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? Colors.black : color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: isToday
                  ? null
                  : Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text(
                  '${_dayNames[e['day'] as int]}, ${d.day}.${d.month}.${d.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isToday ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.white.withOpacity(0.15)
                        : color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isToday ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
