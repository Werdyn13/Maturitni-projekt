import 'package:flutter/material.dart';
import '../services/nastenka_service.dart';

class EmployeeTasksScreen extends StatefulWidget {
  const EmployeeTasksScreen({super.key});

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> {
  final NastenkaService _nastenkaService = NastenkaService();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  bool _isSending = false;
  final Set<int> _checkedIds = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final tasks = await _nastenkaService.getTasksForCurrentUser();
      final checked = <int>{};
      for (final t in tasks) {
        if (t['splneno'] == true) checked.add(t['id'] as int);
      }
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _checkedIds.clear();
        _checkedIds.addAll(checked);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při načítání úkolů: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSendMessageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Zpráva adminovi'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Napište zprávu...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSending ? null : () => Navigator.pop(ctx),
              child: const Text('Zrušit'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.black),
              onPressed: _isSending
                  ? null
                  : () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;
                      setDialogState(() => _isSending = true);
                      setState(() => _isSending = true);
                      try {
                        await _nastenkaService.sendMessageToAdmin(text);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Zpráva byla odeslána'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chyba při odesílání: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isSending = false);
                        setDialogState(() => _isSending = false);
                      }
                    },
              child: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Odeslat'),
            ),
          ],
        ),
      ),
    );
  }

  Color _dateColor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    if (taskDay.isBefore(today)) return Colors.red;
    if (taskDay == today) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendMessageDialog,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.message_outlined),
        label: const Text('Zpráva adminovi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: _tasks.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 72,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Žádné úkoly',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Zatím vám nebyly přiděleny žádné úkoly.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        final date = DateTime.parse(task['na_den']);
                        final dateColor = _dateColor(date);
                        final repeat = task['opakovat'];
                        final hasRepeat =
                            repeat != null && repeat != 'Žádné';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: dateColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _checkedIds.contains(task['id'] as int),
                                  activeColor: Colors.black,
                                  onChanged: (value) async {
                                    final id = task['id'] as int;
                                    setState(() {
                                      if (value == true) {
                                        _checkedIds.add(id);
                                      } else {
                                        _checkedIds.remove(id);
                                      }
                                    });
                                    await _nastenkaService.setChecked(id, value ?? false);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['text_ukolu'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 14,
                                              color: dateColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${date.day}.${date.month}.${date.year}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: dateColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (hasRepeat) ...[
                                            const SizedBox(width: 12),
                                            Icon(Icons.repeat,
                                                size: 14,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              repeat,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (hasRepeat && task['platnost_do'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.event_busy,
                                                  size: 13,
                                                  color: Colors.orange[700]),
                                              const SizedBox(width: 4),
                                              Text(
                                                () {
                                                  final d = DateTime.parse(
                                                      task['platnost_do'] as String);
                                                  return 'Platnost do: ${d.day}.${d.month}.${d.year}';
                                                }(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
