import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../widgets/admin_app_bar_widget.dart';
import '../services/auth_service.dart';
import '../services/receptury_service.dart';
import '../services/nastenka_service.dart';
import 'add_task_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final RecepturyService _recepturyService = RecepturyService();
  final NastenkaService _nastenkaService = NastenkaService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _receptury = [];
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;
  bool _usersLoaded = false;
  bool _recepturyLoaded = false;
  bool _tasksLoaded = false;
  
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: const AdminAppBarWidget(),
      backgroundColor: Colors.white,
      body: Row(
        children: [
          SidebarX(
            controller: _controller,
            theme: SidebarXTheme(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              hoverColor: Colors.white.withOpacity(0.8),
              hoverTextStyle: const TextStyle(color: Colors.black),
              textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              selectedTextStyle: const TextStyle(color: Colors.white),
              itemTextPadding: const EdgeInsets.only(left: 30),
              selectedItemTextPadding: const EdgeInsets.only(left: 30),
              itemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[900]!),
              ),
              selectedItemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.black.withOpacity(0.37),
                ),
                gradient: const LinearGradient(
                  colors: [Colors.black, Colors.grey],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 30,
                  )
                ],
              ),
              iconTheme: IconThemeData(
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              selectedIconTheme: const IconThemeData(
                color: Colors.white,
                size: 20,
              ),
            ),
            extendedTheme: const SidebarXTheme(
              width: 250,
              decoration: BoxDecoration(
                color: Color(0xFF212121),
              ),
            ),
            headerBuilder: (context, extended) {
              return SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Administerský panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: extended ? 20 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
            items: [
              SidebarXItem(
                icon: Icons.people,
                label: 'Účty',
              ),
              SidebarXItem(
                icon: Icons.inventory,
                label: 'Produkty',
              ),
              SidebarXItem(
                icon: Icons.shopping_cart,
                label: 'Objednávky',
              ),
              SidebarXItem(
                icon: Icons.dashboard,
                label: 'Nástěnka',
              ),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return _buildContent(_controller.selectedIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return _buildAccountsTab();
      case 1:
        return _buildProductsTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return _buildNastenkaTab();
      default:
        return const Center(child: Text('Select a tab'));
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
        _usersLoaded = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _usersLoaded = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při načítání uživatelů: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAdminStatus(String email, bool currentStatus) async {
    try {
      await _authService.toggleAdminStatus(email, !currentStatus);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin status byl úspěšně změněn'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při změně admin statusu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final colorController = TextEditingController(text: receptura['color'] ?? '');

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
              const SizedBox(height: 16),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Barva (např. červená, hnědá)',
                  border: OutlineInputBorder(),
                ),
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
                  color: colorController.text.isEmpty ? null : colorController.text,
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

  Widget _buildAccountsTab() {
    if (!_usersLoaded && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUsers();
      });
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_usersLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uživatelé',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Celkem uživatelů: ${_users.length}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Jméno',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Příjmení',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Admin',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Nastavení admina',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: _users.map((user) {
                    final isAdmin = user['admin'] == true;
                    final email = user['mail'] ?? '';
                    return DataRow(
                      cells: [
                        DataCell(Text(email)),
                        DataCell(Text(user['jmeno'] ?? 'N/A')),
                        DataCell(Text(user['prijmeni'] ?? 'N/A')),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                isAdmin ? Icons.check_circle : Icons.cancel,
                                color: isAdmin ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(isAdmin ? 'Ano' : 'Ne'),
                            ],
                          ),
                        ),
                        DataCell(
                          Switch(
                            value: isAdmin,
                            activeThumbColor: Colors.green,
                            onChanged: (value) {
                              _toggleAdminStatus(email, isAdmin);
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (!_recepturyLoaded && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadReceptury();
      });
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_recepturyLoaded) {
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
        renderer: (rendererContext) {
          final kategorie = rendererContext.cell.value?.toString() ?? '';
          final receptura = _receptury[rendererContext.rowIdx];
          
          // Nastavení barev pomocí názvů
          Color bgColor = Colors.grey.shade100;
          if (receptura['color'] != null) {
            final colorString = receptura['color'].toString().toLowerCase();
              switch (colorString) {
                case 'červená':
                  bgColor = Colors.red.shade100;
                  break;
                case 'hnědá':
                  bgColor = Colors.brown.shade100;
                  break;
                case 'oranžová':
                  bgColor = Colors.orange.shade100;
                  break;
                case 'žlutá':
                  bgColor = Colors.yellow.shade100;
                  break;
                case 'zelená':
                  bgColor = Colors.green.shade100;
                  break;
                case 'modrá':
                  bgColor = Colors.blue.shade100;
                  break;
                case 'fialová':
                  bgColor = Colors.purple.shade100;
                  break;
                case 'růžová':
                  bgColor = Colors.pink.shade100;
                  break;
                default:
                  bgColor = Colors.grey.shade100;
              }
          }
          
          return Container(
            width: double.infinity,
            color: bgColor,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            child: Text(
              kategorie,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
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
          'id': PlutoCell(value: receptura['id'] ?? 0),
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

  Widget _buildOrdersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Správa objednávek',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Brzy přibudou nové funkce...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _nastenkaService.getAllTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
        _tasksLoaded = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _tasksLoaded = true;
      });
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

  Future<void> _completeTask(int id) async {
    try {
      await _nastenkaService.completeTask(id);
      await _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Úkol byl označen jako splněný'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při označování úkolu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNastenkaTab() {
    if (!_tasksLoaded && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTasks();
      });
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_tasksLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

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
                  const Text(
                    'Nástěnka',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Celkem úkolů: ${_tasks.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTaskScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadTasks();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Přidat úkol'),
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
            child: _tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Nástěnka je prázdná',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final date = DateTime.parse(task['na_den']);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: Checkbox(
                            value: false,
                            onChanged: (value) {
                              if (value == true) {
                                _completeTask(task['id']);
                              }
                            },
                          ),
                          title: Text(
                            task['text_ukolu'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Pro: ${task['pro_uzivatele'] ?? ''}'),
                              Text('Datum: ${date.day}.${date.month}.${date.year}'),
                              if (task['opakovat'] != null && task['opakovat'] != 'Žádné')
                                Text('Opakovat: ${task['opakovat']}'),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );
    if (result == true) {
      _loadTasks();
    }
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
  String? selectedColor;

  bool _nazevError = false;
  bool _kategorieError = false;
  
  final List<String> availableColors = [
    'červená',
    'hnědá',
    'oranžová',
    'žlutá',
    'zelená',
    'modrá',
    'fialová',
    'růžová',
  ];

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
        color: selectedColor,
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedColor,
              decoration: const InputDecoration(
                labelText: 'Barva',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Vyberte barvu'),
              items: availableColors.map((color) {
                return DropdownMenuItem<String>(
                  value: color,
                  child: Text(color),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedColor = value;
                });
              },
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
