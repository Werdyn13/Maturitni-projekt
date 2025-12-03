import 'package:flutter/material.dart';
import '../widgets/app_bar_widget.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user != null && user.email != null) {
      final profile = await _authService.getUserProfile(user.email!);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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
}
