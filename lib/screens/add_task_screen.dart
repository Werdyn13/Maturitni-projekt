import 'package:flutter/material.dart';
import '../services/nastenka_service.dart';
import '../services/auth_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final NastenkaService _nastenkaService = NastenkaService();
  final AuthService _authService = AuthService();
  
  final textUkoluController = TextEditingController();

  final Set<int> selectedUserIds = {};
  String selectedRepeat = 'Žádné';
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _textUkoluError = false;
  bool _userError = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    textUkoluController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _authService.getEmployees();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _textUkoluError = textUkoluController.text.isEmpty;
      _userError = selectedUserIds.isEmpty;
    });

    if (_textUkoluError || _userError) {
      return;
    }

    try {
      await _nastenkaService.addTask(
        uzivatelIds: selectedUserIds.toList(),
        textUkolu: textUkoluController.text,
        opakovat: selectedRepeat,
        naDen: selectedDate,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Úkol byl úspěšně přidán'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při přidávání úkolu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Přidat nový úkol'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vytvořit nový úkol',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      const Text(
                        'Pro zaměstnance *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selectedUserIds.isNotEmpty) ...[                        
                        const SizedBox(width: 8),
                        Text(
                          '(${selectedUserIds.length} vybráno)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _userError ? Colors.red : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _users.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Žádní zaměstnanci nenalezeni'),
                          )
                        : Column(
                            children: _users.map((user) {
                              final id = user['id'] as int;
                              final jmeno = user['jmeno'] ?? '';
                              final prijmeni = user['prijmeni'] ?? '';
                              final isSelected = selectedUserIds.contains(id);
                              return CheckboxListTile(
                                dense: true,
                                title: Text('$jmeno $prijmeni'),
                                value: isSelected,
                                activeColor: Colors.black,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      selectedUserIds.add(id);
                                    } else {
                                      selectedUserIds.remove(id);
                                    }
                                    if (_userError && selectedUserIds.isNotEmpty) {
                                      _userError = false;
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  ),
                  if (_userError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12),
                      child: Text(
                        'Vyberte alespoň jednoho zaměstnance',
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                      ),
                    ),
                  const SizedBox(height: 24),

                  const Text(
                    'Text úkolu *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textUkoluController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Zadejte text úkolu',
                      errorText: _textUkoluError ? 'Text úkolu je povinný' : null,
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      if (_textUkoluError && value.isNotEmpty) {
                        setState(() => _textUkoluError = false);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Opakovat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRepeat,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Žádné', child: Text('Žádné')),
                      DropdownMenuItem(value: 'denně', child: Text('Denně')),
                      DropdownMenuItem(value: 'týdně', child: Text('Týdně')),
                      DropdownMenuItem(value: 'měsíčně', child: Text('Měsíčně')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedRepeat = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Na den',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Zrušit'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Přidat úkol'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
