import 'package:flutter/material.dart';
import '../widgets/app_bar_widget.dart';
import '../services/receptury_service.dart';
import 'products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecepturyService _recepturyService = RecepturyService();
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final receptury = await _recepturyService.getAllReceptury();
      final categoriesSet = receptury
          .map((r) => r['Kategorie']?['nazev']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet();
      
      setState(() {
        _categories = categoriesSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'chleby':
        return Icons.lunch_dining;
      case 'rohlík':
      default:
        return Icons.bakery_dining;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;
    return Scaffold(
      appBar: const AppBarWidget(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            
            Container(
              height: screenHeight * 0.25,
              decoration: BoxDecoration(
                color: Colors.grey[200],
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
                        fontSize: screenWidth < 450 ? 26.0 : 42.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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
                        fontSize: screenWidth < 450 ? 15.0 : 20.0,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[800],
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
            // Sekce kategorií produktů
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Naše produkty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth < 480 ? 2 : 3;
                            final aspectRatio = columns == 2 ? 0.62 : 0.75;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: aspectRatio,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return _buildProductCard(
                                  icon: _getIconForCategory(category),
                                  title: category,
                                  description: 'Prozkoumejte naši nabídku',
                                );
                              },
                            );
                          },
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
            color: Colors.black,
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
        child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 36, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
