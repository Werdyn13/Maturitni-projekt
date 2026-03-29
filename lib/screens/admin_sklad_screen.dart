import 'package:flutter/material.dart';
import '../services/sklad_service.dart';

class AdminSkladScreen extends StatefulWidget {
  const AdminSkladScreen({super.key});

  @override
  State<AdminSkladScreen> createState() => _AdminSkladScreenState();
}

class _AdminSkladScreenState extends State<AdminSkladScreen> {
  final SkladService _skladService = SkladService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await _skladService.getSklad();
      setState(() {
        _items = items;
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

  Future<void> _deleteItem(int id) async {
    try {
      await _skladService.deleteItem(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddDialog({Map<String, dynamic>? existing}) async {
    final nazevController =
        TextEditingController(text: existing?['nazev'] ?? '');
    final dodavatelController =
        TextEditingController(text: existing?['dodavatel'] ?? '');
    final stavController = TextEditingController(
        text: existing?['aktualni_stav']?.toString() ?? '');
    final jednotkaController =
        TextEditingController(text: existing?['jednotka'] ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Přidat ingredienci' : 'Upravit ingredienci'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nazevController,
                  decoration: const InputDecoration(
                    labelText: 'Název *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Povinné pole' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dodavatelController,
                  decoration: const InputDecoration(
                    labelText: 'Dodavatel',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: stavController,
                        decoration: const InputDecoration(
                          labelText: 'Množství *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Povinné pole';
                          }
                          if (int.tryParse(v.trim()) == null) {
                            return 'Zadejte číslo';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: jednotkaController,
                        decoration: const InputDecoration(
                          labelText: 'Jednotka *',
                          border: OutlineInputBorder(),
                          hintText: 'kg, l, ks…',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Povinné pole' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                final data = {
                  'nazev': nazevController.text.trim(),
                  'dodavatel': dodavatelController.text.trim().isEmpty
                      ? null
                      : dodavatelController.text.trim(),
                  'aktualni_stav': int.parse(stavController.text.trim()),
                  'jednotka': jednotkaController.text.trim(),
                };
                if (existing == null) {
                  await _skladService.addItem(data);
                } else {
                  await _skladService.updateItem(existing['id'] as int, data);
                }
                await _load();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                      content: Text('Chyba: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: Text(existing == null ? 'Přidat' : 'Uložit'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '–';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Záhlaví
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sklad',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Celkem položek: ${_items.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Obnovit',
                    onPressed: _load,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Přidat ingredienci'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Obsah
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Sklad je prázdný',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(Colors.grey[50]),
                            columns: const [
                              DataColumn(
                                  label: Text('Název',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Množství',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Jednotka',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Dodavatel',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Přidáno',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Akce',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: _items.map((item) {
                              return DataRow(cells: [
                                DataCell(Text(item['nazev'] ?? '–')),
                                DataCell(Text(
                                    item['aktualni_stav']?.toString() ?? '–')),
                                DataCell(Text(item['jednotka'] ?? '–')),
                                DataCell(Text(item['dodavatel'] ?? '–')),
                                DataCell(
                                    Text(_formatDate(item['created_at']?.toString()))),

                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 20),
                                        tooltip: 'Upravit',
                                        onPressed: () =>
                                            _showAddDialog(existing: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 20),
                                        tooltip: 'Smazat',
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Smazat položku?'),
                                              content: Text(
                                                  'Položka „${item['nazev']}\" bude trvale smazána.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          ctx, false),
                                                  child: const Text('Zrušit'),
                                                ),
                                                TextButton(
                                                  style:
                                                      TextButton.styleFrom(
                                                          foregroundColor:
                                                              Colors.red),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          ctx, true),
                                                  child:
                                                      const Text('Smazat'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            _deleteItem(
                                                item['id'] as int);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
