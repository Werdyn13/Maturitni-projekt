import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../widgets/admin_app_bar_widget.dart';
import '../services/auth_service.dart';
import '../services/nastenka_service.dart';
import 'add_task_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final NastenkaService _nastenkaService = NastenkaService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;
  bool _usersLoaded = false;
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
    return const AdminProductsScreen();
  }

  Widget _buildOrdersTab() {
    return const AdminOrdersScreen();
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
