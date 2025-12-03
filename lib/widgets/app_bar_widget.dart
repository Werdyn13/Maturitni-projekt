import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.bakery_dining),
        tooltip: 'Home',
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
      ),
      backgroundColor: Colors.brown[700],
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_basket),
          tooltip: 'Orders',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const OrdersScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.email),
          tooltip: 'Contact',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ContactScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Profile',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            await authService.signOut();
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
