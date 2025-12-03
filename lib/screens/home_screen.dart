import 'package:flutter/material.dart';
import '../widgets/app_bar_widget.dart';
import 'products_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Hero Section
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.brown[100],
                image: const DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/1200x300/8D6E63/FFFFFF?text=Fresh+Baked+Goods'),
                  fit: BoxFit.cover,
                  opacity: 0.7,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bánovská pekárna',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[900],
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pečeme s láskou každý den',
                      style: TextStyle(
                        fontSize: 24,
                        fontStyle: FontStyle.italic,
                        color: Colors.brown[800],
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Products Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Naše produkty',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildProductCard(
                          icon: Icons.lunch_dining,
                          title: 'Chleba',
                          description: 'Čerstvý domácí chléb',
                        ),
                        _buildProductCard(
                          icon: Icons.bakery_dining,
                          title: 'Rohlík',
                          description: 'Tradiční rohlíky',
                        ),
                        _buildProductCard(
                          icon: Icons.cookie,
                          title: 'Ostatní Pečivo',
                          description: 'Různé druhy pečiva',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildProductCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductsScreen(
                category: title,
                icon: icon,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          height: 220,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: Colors.brown[700]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.brown[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
