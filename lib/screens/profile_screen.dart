import 'package:flutter/material.dart';
import '../widgets/app_bar_widget.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final TextEditingController _jmenoController = TextEditingController();
  final TextEditingController _prijmeniController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _jmenoController.dispose();
    _prijmeniController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user != null && user.email != null) {
      final profile = await _authService.getUserProfile(user.email!);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
        if (profile != null) {
          _jmenoController.text = profile['jmeno'] ?? '';
          _prijmeniController.text = profile['prijmeni'] ?? '';
          _emailController.text = profile['mail'] ?? '';
        }
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_userProfile == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _authService.updateUserProfile(
        email: _userProfile!['mail'],
        jmeno: _jmenoController.text,
        prijmeni: _prijmeniController.text,
        newEmail: _emailController.text,
      );
      
      await _loadUserProfile();
      
      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil byl úspěšně aktualizován'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při ukládání: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      if (_userProfile != null) {
        _jmenoController.text = _userProfile!['jmeno'] ?? '';
        _prijmeniController.text = _userProfile!['prijmeni'] ?? '';
        _emailController.text = _userProfile!['mail'] ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Profil',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                            const SizedBox(height: 40),
                            if (_userProfile != null) ...[
                              if (_isEditing) ...[
                                _buildEditField(
                                  icon: Icons.person,
                                  title: 'Jméno',
                                  controller: _jmenoController,
                                ),
                                const SizedBox(height: 16),
                                _buildEditField(
                                  icon: Icons.person_outline,
                                  title: 'Příjmení',
                                  controller: _prijmeniController,
                                ),
                                const SizedBox(height: 16),
                                _buildEditField(
                                  icon: Icons.email,
                                  title: 'Email',
                                  controller: _emailController,
                                ),
                                const SizedBox(height: 16),
                                _buildProfileCard(
                                  icon: Icons.admin_panel_settings,
                                  title: 'Admin',
                                  content: _userProfile!['admin'] == true ? 'Ano' : 'Ne',
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _saveProfile,
                                      icon: const Icon(Icons.save),
                                      label: const Text('Uložit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: _cancelEdit,
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Zrušit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                _buildProfileCard(
                                  icon: Icons.person,
                                  title: 'Jméno',
                                  content: _userProfile!['jmeno'] ?? 'N/A',
                                ),
                                const SizedBox(height: 16),
                                _buildProfileCard(
                                  icon: Icons.person_outline,
                                  title: 'Příjmení',
                                  content: _userProfile!['prijmeni'] ?? 'N/A',
                                ),
                                const SizedBox(height: 16),
                                _buildProfileCard(
                                  icon: Icons.email,
                                  title: 'Email',
                                  content: _userProfile!['mail'] ?? 'N/A',
                                ),
                                const SizedBox(height: 16),
                                _buildProfileCard(
                                  icon: Icons.admin_panel_settings,
                                  title: 'Admin',
                                  content: _userProfile!['admin'] == true ? 'Ano' : 'Ne',
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() => _isEditing = true);
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Upravit profil'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (_userProfile!['admin'] == true) ...[
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => const DashboardScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.dashboard),
                                  label: const Text('Přejít na Dashboard'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ] else ...[
                              Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'Profil nebyl nalezen',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.brown[600],
                                    ),
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
            color: Colors.brown[700],
            child: Column(
              children: [
                Text(
                  '© 2025 Bánovská pekárna',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.brown[700]),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.brown[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required IconData icon,
    required String title,
    required TextEditingController controller,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.brown[700]),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.brown[700]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
