import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
            return Center(child: Text('No products in this category.'));
          } else {
            final products = snapshot.data!;
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final expirationDateFormatted = product.expirationDate != null
                    ? DateFormat('yyyy-MM-dd').format(product.expirationDate!)
                    : null;

                return ListTile(
                  leading: Icon(Icons.fastfood),
                  title: Text(product.name ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Brand: ${product.brand ?? 'Unknown'}'),
                      Text('Quantity: ${product.quantity ?? 0}'),
                      // Przenosimy date ważności w miejsce ilości sztuk
                      expirationDateFormatted != null
                          ? Text('Exp: $expirationDateFormatted')
                          : SizedBox.shrink(),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mechanizm do zwiększania/zmniejszania ilości sztuk
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          // Zmniejsz ilość sztuk w produkcie
                          _updateQuantityCount(product, -1, context);
                        },
                      ),
                      Text('${product.quantityCount ?? 0}'),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          // Zwiększ ilość sztuk w produkcie
                          _updateQuantityCount(product, 1, context);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _updateQuantityCount(Product product, int change, BuildContext context) {
    // Funkcja do aktualizacji quantityCount w bazie danych
    final newQuantityCount = (product.quantityCount ?? 0) + change;
    if (newQuantityCount >= 0) {
      // Upewnij się, że liczba sztuk nie jest ujemna
      MongoDBHelper.updateProductQuantityCount(product, newQuantityCount).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated quantity to $newQuantityCount')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $error')),
        );
      });
    }
  }
}
