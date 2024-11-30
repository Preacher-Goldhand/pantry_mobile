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
  bool _isSearchActive = false; // Flaga aktywnego wyszukiwania

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

  // Funkcja czyszcząca zapytanie wyszukiwania
  void _clearSearch() {
    setState(() {
      _searchQuery = ''; // Wyczyść zapytanie
      _foundProducts = []; // Wyczyść wyniki wyszukiwania
      _isSearchActive = false; // Zamknij wyszukiwanie
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // Siatka kategorii
            Column(
              children: [
                Row(
                  children: [
                    // Pole wyszukiwania
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: _searchQuery), // Ustawia tekst na _searchQuery
                        onChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Search in Pantry',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: _clearSearch, // Wyczyść zapytanie
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Strzałka do uruchomienia wyszukiwania
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () {
                        if (_searchQuery.isNotEmpty) {
                          setState(() {
                            _isSearchActive = true; // Aktywuj wyniki wyszukiwania
                          });
                          _searchProducts(_searchQuery); // Rozpocznij wyszukiwanie
                        }
                      },
                    ),
                  ],
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
              ],
            ),

            // Widok wyników wyszukiwania przykrywający siatkę
            if (_isSearchActive)
              Container(
                color: Colors.black.withOpacity(0.5), // Przezroczysty czarny tło
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    Expanded(
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : _foundProducts.isEmpty
                          ? Center(child: Text('No products found.'))
                          : ListView.builder(
                        itemCount: _foundProducts.length,
                        itemBuilder: (context, index) {
                          final product = _foundProducts[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(product.name ?? 'No name'),
                              subtitle: Text(product.category ?? 'Unknown category'),
                              trailing: Icon(Icons.arrow_forward),
                              onTap: () {
                                // Akcja na kliknięcie w produkt
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryScreen(
                                      category: product.category ?? 'Unknown category',
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
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white, size: 30),
                      onPressed: _clearSearch, // Zamknięcie wyników wyszukiwania
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
