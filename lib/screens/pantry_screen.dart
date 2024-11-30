import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'package:pantry/models/product.dart';
import 'package:pantry/utils/mongo_helper.dart';

class PantryScreen extends StatefulWidget {
  @override
  _PantryScreenState createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _searchQuery = ''; // Przechowuje zapytanie wyszukiwania
  List<Product> _foundProducts = []; // Przechowuje wyniki wyszukiwania
  bool _isLoading = false; // Status ładowania danych

  Future<void> _searchProducts(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Pobierz produkty pasujące do wyszukiwania
      final products = await MongoDBHelper.getProductsByCategoryAndSearch('', query);
      setState(() {
        _foundProducts = products;
      });
    } catch (e) {
      print('Błąd podczas wyszukiwania produktów: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Pole wyszukiwania
            TextField(
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                if (query.isNotEmpty) {
                  _searchProducts(query);
                } else {
                  setState(() {
                    _foundProducts = [];
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Wyszukaj produkty',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Siatka kategorii
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.3,
                children: [
                  PantryTile(label: 'Fresh', icon: Icons.local_florist, category: 'Fresh'),
                  PantryTile(label: 'Dry', icon: Icons.grain, category: 'Dry'),
                  PantryTile(label: 'Drinks', icon: Icons.local_drink, category: 'Drinks'),
                  PantryTile(label: 'Fats', icon: Icons.bakery_dining, category: 'Fats'),
                  PantryTile(label: 'Dairy', icon: Icons.icecream, category: 'Dairy'),
                  PantryTile(label: 'Other', icon: Icons.food_bank, category: 'Other'),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Wyniki wyszukiwania
            if (_searchQuery.isNotEmpty)
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _foundProducts.isEmpty
                    ? Center(child: Text('Nie znaleziono produktów.'))
                    : ListView.builder(
                  itemCount: _foundProducts.length,
                  itemBuilder: (context, index) {
                    final product = _foundProducts[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(product.name ?? 'Brak nazwy'),
                        subtitle: Text(product.category ?? 'Nieznana kategoria'),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          // Akcja na kliknięcie w produkt
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryScreen(
                                category: product.category ?? 'Nieznana kategoria',
                                searchQuery: product.name ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PantryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String category;

  PantryTile({required this.label, required this.icon, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(category: category, searchQuery: '',),
          ),
        );
      },
      child: Card(
        color: Colors.blueAccent,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
