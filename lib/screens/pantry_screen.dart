import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'package:pantry/models/product.dart';
import 'package:pantry/utils/mongo_helper.dart';

class PantryScreen extends StatefulWidget {
  @override
  _PantryScreenState createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _searchQuery = '';
  List<Product> _foundProducts = [];
  bool _isLoading = false;
  bool _isSearchActive = false;

  Future<void> _searchProducts(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final products = await MongoDBHelper.getProductsByCategoryAndSearch('', query);
      setState(() {
        _foundProducts = products;
      });
    } catch (e) {
      print('Error while searching products: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _foundProducts = [];
      _isSearchActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: _searchQuery),
                        onChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Search in Pantry',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: _clearSearch,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () {
                        if (_searchQuery.isNotEmpty) {
                          setState(() {
                            _isSearchActive = true;
                          });
                          _searchProducts(_searchQuery);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.3,
                    children: [
                      PantryTile(label: 'Fridge', icon: Icons.local_florist, category: 'Fridge'),
                      PantryTile(label: 'Dry', icon: Icons.grain, category: 'Dry'),
                      PantryTile(label: 'Frozen', icon: Icons.icecream, category: 'Frozen'),
                      PantryTile(label: 'Drinks', icon: Icons.local_drink, category: 'Drinks'),
                      PantryTile(label: 'Fresh', icon: Icons.bakery_dining, category: 'Fresh'),
                      PantryTile(label: 'Other', icon: Icons.food_bank, category: 'Other'),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSearchActive)
              Container(
                color: Colors.black.withOpacity(0.5),
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
                      onPressed: _clearSearch,
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
            builder: (context) => CategoryScreen(
              category: category,
              searchQuery: '',
            ),
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
