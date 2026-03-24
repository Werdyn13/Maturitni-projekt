import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'employee_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _jmenoController = TextEditingController();
  final TextEditingController _prijmeniController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isRegistering = false;

  // Animace login
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Animace pro login
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _jmenoController.dispose();
    _prijmeniController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Prosím vložte email a heslo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Kontrola role uzivatele
      final profile = await _authService.getUserProfile(_emailController.text.trim());
      final isAdmin = profile?['admin'] == true;
      final isEmployee = profile?['zamestnanec'] == true;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) {
              if (isAdmin) {
                return const DashboardScreen();
              }
              if (isEmployee) {
                return const EmployeeHomeScreen();
              }
              return const HomeScreen();
            },
          ),
        );
      }
    } catch (e) {
      _showMessage('Přihlášení se nepovedlo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _jmenoController.text.isEmpty ||
        _prijmeniController.text.isEmpty) {
      _showMessage('Prosím vyplňte všechna pole');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Hesla se neshodují');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        jmeno: _jmenoController.text.trim(),
        prijmeni: _prijmeniController.text.trim(),
      );

      _showMessage('Registrace byla úspěšná! Váš účet čeká na schválení administrátorem.');
      setState(() {
        _isRegistering = false;
        _jmenoController.clear();
        _prijmeniController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      _showMessage('Registrace se nepovedla: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _buildLoginBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginBox() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Bánovská pekárna",
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pečeme s láskou",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 26),

          if (_isRegistering) _buildRegisterFields(),

          _buildInput("Email", Icons.email, _emailController, false),
          const SizedBox(height: 16),
          _buildInput("Heslo", Icons.lock, _passwordController, true),
          if (_isRegistering) ...[
            const SizedBox(height: 16),
            _buildInput("Potvrďte heslo", Icons.lock_outline, _confirmPasswordController, true),
          ],
          const SizedBox(height: 22),

          if (!_isRegistering) _buildLoginButton(),
          if (_isRegistering) _buildCreateAccountButton(),

          const SizedBox(height: 12),
          _buildToggleButton(),
        ],
      ),
    );
  }

  Widget _buildRegisterFields() {
    return Column(
      children: [
        _buildInput("Jméno", Icons.person, _jmenoController, false),
        const SizedBox(height: 16),
        _buildInput("Příjmení", Icons.person_outline, _prijmeniController, false),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInput(
      String label, IconData icon, TextEditingController controller, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.grey[900], fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text("Vytvořit účet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () => setState(() => _isRegistering = !_isRegistering),
      child: Text(
        _isRegistering ? "Zpátky na login" : "Registrovat se",
        style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}
