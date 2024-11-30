import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/mongo_helper.dart';
import '../models/product.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  CategoryScreen({required this.category, required String searchQuery});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Product>> _productsFuture;
  String _sortOrder = 'Ascending'; // Default sorting order

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    // Load products with the selected sorting option
    _productsFuture = MongoDBHelper.getProductsByCategory(
      widget.category,
      ascending: _sortOrder == 'Ascending', // Ascending if 'Ascending' selected
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Products'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sorting dropdown menu placed below the category title
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _sortOrder,
              icon: Icon(Icons.sort),
              onChanged: (String? newValue) {
                setState(() {
                  _sortOrder = newValue!;
                  _loadProducts();  // Reload products after changing sorting order
                });
              },
              items: [
                DropdownMenuItem<String>(
                  value: 'Ascending',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 20),  // Up arrow for Ascending
                      SizedBox(width: 8),
                      Text('Exp Date'),  // "Exp Date" with arrow up
                    ],
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'Descending',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, size: 20),  // Down arrow for Descending
                      SizedBox(width: 8),
                      Text('Exp Date'),  // "Exp Date" with arrow down
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Product list displayed below the sorting dropdown
          Expanded(
            child: FutureBuilder<List<Product>>(
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
                                ? GestureDetector(
                              onTap: () => _pickDate(product, context),  // Add Date Picker functionality
                              child: Text('Exp: $expirationDateFormatted', style: TextStyle(color: Colors.blue)),
                            )
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
                            FutureBuilder<int>(  // Display current quantity
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
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmationDialog(product, context);
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
          ),
        ],
      ),
    );
  }

  // Change product quantity (increase or decrease)
  void _changeQuantityCount(Product product, int change, BuildContext context) {
    MongoDBHelper.getProductQuantityCount(product.id!).then((currentQuantity) {
      final newQuantityCount = currentQuantity + change;
      if (newQuantityCount >= 0) {
        MongoDBHelper.updateProductQuantityCount(product, newQuantityCount).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated quantity to $newQuantityCount')),
          );
          setState(() {
            // Refresh the products list after update
            _loadProducts();
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

  // Show confirmation dialog before deleting product
  void _showDeleteConfirmationDialog(Product product, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${product.name}?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deleteProduct(product, context);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Delete the product
  void _deleteProduct(Product product, BuildContext context) {
    MongoDBHelper.deleteProduct(product.id!).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} has been deleted')),
      );
      setState(() {
        // Refresh the list after deletion
        _loadProducts();
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $error')),
      );
    });
  }

  // Date picker for changing expiration date
  Future<void> _pickDate(Product product, BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: product.expirationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null && selectedDate != product.expirationDate) {
      // Update the expiration date of the product in the database
      MongoDBHelper.updateProductExpirationDate(product, selectedDate).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expiration date updated to ${DateFormat('yyyy-MM-dd').format(selectedDate)}')),
        );
        setState(() {
          // Refresh the products list after updating the date
          _loadProducts();
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating expiration date: $error')),
        );
      });
    }
  }
}