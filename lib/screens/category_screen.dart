import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/mongo_helper.dart';
import '../models/product.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  CategoryScreen({required this.category});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = MongoDBHelper.getProductsByCategory(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Products'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
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
                      Text('Quantity: ${product.quantityCount ?? 0}'),
                      expirationDateFormatted != null
                          ? Text('Exp: $expirationDateFormatted')
                          : SizedBox.shrink(),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          _changeQuantityCount(product, -1, context);
                        },
                      ),
                      FutureBuilder<int>(
                        future: MongoDBHelper.getProductQuantityCount(product.id!),
                        builder: (context, quantitySnapshot) {
                          if (quantitySnapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (quantitySnapshot.hasError) {
                            return Text('Error');
                          } else if (quantitySnapshot.hasData) {
                            int currentQuantity = quantitySnapshot.data ?? 0;
                            return Text('$currentQuantity');
                          } else {
                            return Text('0');
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          _changeQuantityCount(product, 1, context);
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

  void _changeQuantityCount(Product product, int change, BuildContext context) {
    MongoDBHelper.getProductQuantityCount(product.id!).then((currentQuantity) {
      final newQuantityCount = currentQuantity + change;
      if (newQuantityCount >= 0) {
        MongoDBHelper.updateProductQuantityCount(product, newQuantityCount).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated quantity to $newQuantityCount')),
          );
          setState(() {
            // Manually refresh the products list after the update
            _productsFuture = MongoDBHelper.getProductsByCategory(widget.category);
          });
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating quantity: $error')),
          );
        });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching current quantity: $error')),
      );
    });
  }
}

