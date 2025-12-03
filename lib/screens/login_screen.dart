import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _jmenoController = TextEditingController();
  final TextEditingController _prijmeniController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isRegistering = false;

  // Animace pozadí
  late final AnimationController _bgController;
  late final Animation<Color?> _color1;
  late final Animation<Color?> _color2;

  // Animace login
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Animace pozadí
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _color1 = ColorTween(begin: Colors.black, end: const Color(0xFF5D4037))
        .animate(_bgController);
    _color2 = ColorTween(begin: const Color(0xFF8D6E63), end: const Color(0xFFD7CCC8))
        .animate(_bgController);

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
    _jmenoController.dispose();
    _prijmeniController.dispose();
    _bgController.dispose();
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        jmeno: _jmenoController.text.trim(),
        prijmeni: _prijmeniController.text.trim(),
      );

      _showMessage('Registrace byla úspěšná! Nyní se můžete přihlásit.');
      setState(() {
        _isRegistering = false;
        _jmenoController.clear();
        _prijmeniController.clear();
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
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color1.value!, _color2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildLoginBox(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Bánovská pekárna",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Pečeme s láskou",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 26),

          if (_isRegistering) _buildRegisterFields(),

          _buildInput("Email", Icons.email, _emailController, false),
          const SizedBox(height: 16),
          _buildInput("Password", Icons.lock, _passwordController, true),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return TextButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Login", style: TextStyle(fontSize: 17)),
    );
  }

  Widget _buildCreateAccountButton() {
    return TextButton(
      onPressed: _isLoading ? null : _handleRegister,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Create Account", style: TextStyle(fontSize: 17)),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () => setState(() => _isRegistering = !_isRegistering),
      child: Text(
        _isRegistering ? "Zpátky na login" : "Registrovat se",
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
