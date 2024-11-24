import 'package:flutter/material.dart';
import 'category_screen.dart';

class PantryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            builder: (context) => CategoryScreen(category: category),
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
