import 'package:flutter/material.dart';
import '../widgets/app_bar_widget.dart';
import '../services/receptury_service.dart';
import '../services/orders_service.dart';

class ProductsScreen extends StatefulWidget {
  final String category;
  final IconData icon;

  const ProductsScreen({
    super.key,
    required this.category,
    required this.icon,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final RecepturyService _recepturyService = RecepturyService();
  final OrdersService _ordersService = OrdersService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final allReceptury = await _recepturyService.getAllReceptury();
      final filteredProducts = allReceptury
          .where((r) => r['kategorie']?.toString() == widget.category)
          .toList();

      setState(() {
        _products = filteredProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product, int quantity) async {
    try {
      await _ordersService.addItemToOrder(
        zboziId: product['id'],
        mnozstvi: quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['nazev']} ($quantity ks) přidáno do košíku'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.grey[100],
            child: Text(
              widget.category,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Seznam produktů v dané kategorii
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.icon,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Žádné produkty',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 1200,
                          ),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(_products[index]);
                            },
                          ),
                        ),
                      ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: const Text(
              '© 2025 Bánovská pekárna',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Karta produktu
  Widget _buildProductCard(Map<String, dynamic> product) {
    final TextEditingController quantityController = TextEditingController(text: '1');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ikona produktu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 48,
                color: Colors.black,
              ),
            ),

            // Název produktu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                product['nazev'] ?? 'Bez názvu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Množství
            if (product['mnozstvi'] != null)
              Text(
                'Množství: ${product['mnozstvi']} ks',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.brown[600],
                ),
              ),

            const SizedBox(height: 12),

            // Input pro množství a tlačítko Koupit
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final inputText = quantityController.text.trim();
                      final quantity = int.tryParse(inputText);

                      if (quantity == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Zadejte platné číslo'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else if (quantity <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Množství musí být větší než 0'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        _addToCart(product, quantity);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Koupit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
          ],
        ),
      )
    );
  }
}
