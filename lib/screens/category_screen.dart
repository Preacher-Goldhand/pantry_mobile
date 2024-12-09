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
  String _sortOrder = 'Ascending';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    _productsFuture = MongoDBHelper.getProductsByCategory(
      widget.category,
      ascending: _sortOrder == 'Ascending',
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _sortOrder,
              icon: Icon(Icons.sort),
              onChanged: (String? newValue) {
                setState(() {
                  _sortOrder = newValue!;
                  _loadProducts();
                });
              },
              items: [
                DropdownMenuItem(
                  value: 'Ascending',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 20),
                      SizedBox(width: 8),
                      Text('Exp Date'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Descending',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, size: 20),
                      SizedBox(width: 8),
                      Text('Exp Date'),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

                      return ListTile(
                        leading: Icon(Icons.fastfood),
                        title: Text(product.name ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.brand != null && product.brand!.isNotEmpty)
                              Text('Brand: ${product.brand}'),
                            if (product.quantity != null &&
                                product.quantity!.isNotEmpty &&
                                product.quantity != "0")
                              Text('Quantity: ${product.quantity}'),
                            if (product.grammage != null && product.unit != null)
                              Text('Quantity: ${product.grammage} ${product.unit}'),
                            if (product.expirationDays != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text('Days to expire: '),
                                  DropdownButton<int>(
                                    value: product.expirationDays,
                                    underline: SizedBox(),
                                    items: [2, 3, 5].map((int value) {
                                      return DropdownMenuItem<int>(
                                        value: value,
                                        child: Text(
                                          value.toString(),
                                          style: TextStyle(
                                            decoration: TextDecoration.underline,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (int? newValue) {
                                      if (newValue != null) {
                                        _updateExpirationDays(product, newValue);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            if (product.expirationDays == null &&
                                product.expirationDate != null)
                              GestureDetector(
                                onTap: () {
                                  _pickDate(product, context);
                                },
                                child: Text(
                                  'Exp Date: ${DateFormat('yyyy-MM-dd').format(product.expirationDate!)}',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
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
                                if (quantitySnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (quantitySnapshot.hasError) {
                                  return Text('Error');
                                } else if (quantitySnapshot.hasData) {
                                  int currentQuantity =
                                      quantitySnapshot.data ?? 0;
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

  void _changeQuantityCount(Product product, int change, BuildContext context) {
    MongoDBHelper.getProductQuantityCount(product.id!).then((currentQuantity) {
      final newQuantityCount = currentQuantity + change;
      if (newQuantityCount >= 0) {
        MongoDBHelper.updateProductQuantityCount(product, newQuantityCount)
            .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated quantity to $newQuantityCount')),
          );
          setState(() {
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

  void _deleteProduct(Product product, BuildContext context) {
    MongoDBHelper.deleteProduct(product.id!).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} has been deleted')),
      );
      setState(() {
        _loadProducts();
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $error')),
      );
    });
  }

  void _pickDate(Product product, BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: product.expirationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null && selectedDate != product.expirationDate) {
      MongoDBHelper.updateProductExpirationDate(product, selectedDate).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Expiration date updated to ${DateFormat('yyyy-MM-dd').format(selectedDate)}')),
        );
        setState(() {
          _loadProducts();
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating expiration date: $error')),
        );
      });
    }
  }

  void _updateExpirationDays(Product product, int newDays) {
    MongoDBHelper.updateExpirationDays(product, newDays).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated expiration days to $newDays')),
      );
      setState(() {
        _loadProducts();
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating expiration days: $error')),
      );
    });
  }
}
