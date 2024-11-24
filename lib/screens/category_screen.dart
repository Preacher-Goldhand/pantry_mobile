import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Importujemy pakiet intl
import '../utils/mongo_helper.dart';
import '../models/product.dart';

class CategoryScreen extends StatelessWidget {
  final String category;

  CategoryScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Products'),
      ),
      body: FutureBuilder<List<Product>>(
        future: MongoDBHelper.getProductsByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No products found in this category.'));
          } else {
            final products = snapshot.data!;
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                // Formatowanie daty ważności
                String? expirationDateFormatted;
                if (product.expirationDate != null) {
                  expirationDateFormatted = DateFormat('yyyy/MM/dd').format(product.expirationDate!);
                }

                return ListTile(
                  leading: Icon(Icons.fastfood),
                  title: Text(product.name ?? 'No Name'),
                  subtitle: Text('Brand: ${product.brand ?? 'Unknown'}'),
                  trailing: expirationDateFormatted != null
                      ? Text('Exp: $expirationDateFormatted')
                      : null,
                );
              },
            );
          }
        },
      ),
    );
  }
}
