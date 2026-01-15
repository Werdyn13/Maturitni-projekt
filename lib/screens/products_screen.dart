import 'package:flutter/material.dart';
import '../widgets/app_bar_widget.dart';
import '../services/receptury_service.dart';

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
            color: Colors.brown[50],
            child: Text(
              widget.category,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
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
                              color: Colors.brown[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Žádné produkty',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.brown[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 600,
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              return _buildProductRow(_products[index]);
                            },
                          ),
                        ),
                      ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.brown[700],
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
  Widget _buildProductRow(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        dense: true,
        leading: Icon(
          widget.icon,
          size: 32,
          color: Colors.brown[600],
        ),
        title: Text(
          product['nazev'] ?? 'Bez názvu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.brown[800],
          ),
        ),
        subtitle: product['mnozstvi'] != null
            ? Text(
                'Množství: ${product['mnozstvi']} ks',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.brown[600],
                ),
              )
            : null,
      ),
    );
  }
}
