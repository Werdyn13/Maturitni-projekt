import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../services/receptury_service.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final RecepturyService _recepturyService = RecepturyService();
  List<Map<String, dynamic>> _receptury = [];
  bool _isLoading = false;
  bool _recepturyLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadReceptury();
  }

  Future<void> _loadReceptury() async {
    setState(() => _isLoading = true);
    try {
      final receptury = await _recepturyService.getAllReceptury();
      setState(() {
        _receptury = receptury;
        _isLoading = false;
        _recepturyLoaded = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _recepturyLoaded = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při načítání receptur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReceptura(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdit smazání'),
        content: const Text('Opravdu chcete smazat tento produkt?'),
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
      await _recepturyService.deleteReceptura(id);
      await _loadReceptury();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produkt byl úspěšně smazán'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při mazání produktu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditRecepturaDialog(Map<String, dynamic> receptura) {
    final nazevController = TextEditingController(text: receptura['nazev']);
    final kategorieController = TextEditingController(text: receptura['kategorie']);
    final surovinyController = TextEditingController(text: receptura['suroviny'] ?? '');
    final mnozstviController = TextEditingController(
      text: receptura['mnozstvi']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upravit produkt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nazevController,
                decoration: const InputDecoration(
                  labelText: 'Název',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: kategorieController,
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: surovinyController,
                decoration: const InputDecoration(
                  labelText: 'Suroviny',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: mnozstviController,
                decoration: const InputDecoration(
                  labelText: 'Množství',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _recepturyService.updateReceptura(
                  id: receptura['id'],
                  nazev: nazevController.text,
                  kategorie: kategorieController.text,
                  suroviny: surovinyController.text.isEmpty ? null : surovinyController.text,
                  mnozstvi: mnozstviController.text.isEmpty 
                    ? null 
                    : int.tryParse(mnozstviController.text),
                );
                await _loadReceptury();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produkt byl úspěšně upraven'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chyba při aktualizaci produktu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
  }

  void _showAddRecepturaDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddRecepturaDialog(
        recepturyService: _recepturyService,
        onSuccess: _loadReceptury,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_recepturyLoaded) {
  return const Center(child: CircularProgressIndicator());
}


    // PlutoGrid sloupce
    final columns = <PlutoColumn>[
      PlutoColumn(
        title: 'Název',
        field: 'nazev',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Kategorie',
        field: 'kategorie',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Suroviny',
        field: 'suroviny',
        type: PlutoColumnType.text(),
        width: 300,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Množství',
        field: 'mnozstvi',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Akce',
        field: 'akce',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final receptura = _receptury[rendererContext.rowIdx];
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                tooltip: 'Upravit',
                onPressed: () => _showEditRecepturaDialog(receptura),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Smazat',
                onPressed: () => _deleteReceptura(receptura['id']),
              ),
            ],
          );
        },
      ),
    ];

    // PlutoGrid řádky
    final rows = _receptury.map((receptura) {
      return PlutoRow(
        cells: {
          'nazev': PlutoCell(value: receptura['nazev'] ?? ''),
          'kategorie': PlutoCell(value: receptura['kategorie'] ?? ''),
          'suroviny': PlutoCell(value: receptura['suroviny'] ?? ''),
          'mnozstvi': PlutoCell(
            value: receptura['mnozstvi'] != null 
              ? receptura['mnozstvi'].toString() 
              : '',
          ),
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
                    'Produkty',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Celkem produktů: ${_receptury.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddRecepturaDialog,
                icon: const Icon(Icons.add),
                label: const Text('Přidat produkt'),
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
            child: Card(
              elevation: 2,
              child: PlutoGrid(
                columns: columns,
                rows: rows,
                onLoaded: (PlutoGridOnLoadedEvent event) {
                },
                configuration: PlutoGridConfiguration(
                  style: PlutoGridStyleConfig(
                    gridBorderColor: Colors.grey.shade300,
                    gridBackgroundColor: Colors.white,
                    rowColor: Colors.white,
                    activatedColor: Colors.grey.shade100,
                    checkedColor: Colors.grey.shade200,
                    cellColorInEditState: Colors.white,
                    columnHeight: 50,
                    rowHeight: 60,
                    defaultColumnTitlePadding: const EdgeInsets.all(8),
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

class _AddRecepturaDialog extends StatefulWidget {
  final RecepturyService recepturyService;
  final VoidCallback onSuccess;

  const _AddRecepturaDialog({
    required this.recepturyService,
    required this.onSuccess,
  });

  @override
  State<_AddRecepturaDialog> createState() => _AddRecepturaDialogState();
}

class _AddRecepturaDialogState extends State<_AddRecepturaDialog> {
  final nazevController = TextEditingController();
  final kategorieController = TextEditingController();
  final surovinyController = TextEditingController();
  final mnozstviController = TextEditingController();

  bool _nazevError = false;
  bool _kategorieError = false;

  @override
  void dispose() {
    nazevController.dispose();
    kategorieController.dispose();
    surovinyController.dispose();
    mnozstviController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _nazevError = nazevController.text.isEmpty;
      _kategorieError = kategorieController.text.isEmpty;
    });

    if (_nazevError || _kategorieError) {
      return;
    }

    try {
      await widget.recepturyService.addReceptura(
        nazev: nazevController.text,
        kategorie: kategorieController.text,
        suroviny: surovinyController.text.isEmpty ? null : surovinyController.text,
        mnozstvi: mnozstviController.text.isEmpty 
          ? null 
          : int.tryParse(mnozstviController.text),
      );
      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produkt byl úspěšně přidán'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při přidávání produktu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Přidat nový produkt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nazevController,
              decoration: InputDecoration(
                labelText: 'Název *',
                border: const OutlineInputBorder(),
                errorBorder: _nazevError
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
                focusedErrorBorder: _nazevError
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
              ),
              onChanged: (value) {
                if (_nazevError && value.isNotEmpty) {
                  setState(() => _nazevError = false);
                }
              },
            ),
            if (_nazevError)
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  'Název je povinný',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: kategorieController,
              decoration: InputDecoration(
                labelText: 'Kategorie *',
                border: const OutlineInputBorder(),
                errorBorder: _kategorieError
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
                focusedErrorBorder: _kategorieError
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
              ),
              onChanged: (value) {
                if (_kategorieError && value.isNotEmpty) {
                  setState(() => _kategorieError = false);
                }
              },
            ),
            if (_kategorieError)
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  'Kategorie je povinná',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: surovinyController,
              decoration: const InputDecoration(
                labelText: 'Suroviny',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: mnozstviController,
              decoration: const InputDecoration(
                labelText: 'Množství',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zrušit'),
        ),
        TextButton(
          onPressed: _handleSubmit,
          child: const Text('Přidat'),
        ),
      ],
    );
  }
}
