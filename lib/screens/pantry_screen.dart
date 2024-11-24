import 'package:flutter/material.dart';

class PantryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: GridView.count(
          crossAxisCount: 2, // Dwa kafelki w jednym wierszu
          crossAxisSpacing: 16.0, // Odstęp poziomy między kafelkami
          mainAxisSpacing: 16.0, // Odstęp pionowy między kafelkami
          childAspectRatio: 1.3, // Zmniejszenie proporcji kafelków
          children: [
            PantryTile(
              label: 'Fresh',
              icon: Icons.local_florist, // Ikona rośliny
              onTap: () {
                // Nawigacja do ekranu Fresh
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(category: 'Fresh'),
                  ),
                );
              },
            ),
            PantryTile(
              label: 'Dry',
              icon: Icons.grain, // Ikona ziarna
              onTap: () {
                // Nawigacja do ekranu Dry
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(category: 'Dry'),
                  ),
                );
              },
            ),
            PantryTile(
              label: 'Drinks',
              icon: Icons.local_drink, // Ikona napoju
              onTap: () {
                // Nawigacja do ekranu Drinks
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(category: 'Drinks'),
                  ),
                );
              },
            ),
            PantryTile(
              label: 'Fats',
              icon: Icons.bakery_dining, // Ikona tłuszczów (np. masło)
              onTap: () {
                // Nawigacja do ekranu Fats
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(category: 'Fats'),
                  ),
                );
              },
            ),
            PantryTile(
              label: 'Dairy',
              icon: Icons.icecream, // Ikona nabiału (lody)
              onTap: () {
                // Nawigacja do ekranu Dairy
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(category: 'Dairy'),
                  ),
                );
              },
            ),
            PantryTile(
              label: 'Other',
              icon: Icons.food_bank, // Ikona tłuszczów (np. masło)
              onTap: () {
                // Nawigacja do ekranu Fats
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(category: 'Other'),
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}

// Kafelek, który zawiera ikonę i tekst
class PantryTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  PantryTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  _PantryTileState createState() => _PantryTileState();
}

class _PantryTileState extends State<PantryTile> {
  bool _isSelected = false; // Stan, który będzie śledził, czy kafelek jest wybrany

  void _toggleSelection() {
    setState(() {
      _isSelected = !_isSelected; // Zmiana stanu po kliknięciu
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _toggleSelection(); // Zmiana stanu po kliknięciu
        widget.onTap(); // Wywołanie funkcji onTap przekazanej z nadrzędnego widgetu
      },
      child: Card(
        color: _isSelected ? Colors.blue : Colors.blueAccent, // Podświetlanie kafelka po kliknięciu
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 40, // Zmniejszenie rozmiaru ikony
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ekran kategorii
class CategoryScreen extends StatelessWidget {
  final String category;

  CategoryScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Products'),
      ),
      body: Center(
        child: Text(
          'Products in category: $category',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
