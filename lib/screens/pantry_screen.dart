import 'package:flutter/material.dart';
import 'package:pantry/utils/mongo_helper.dart';
import 'package:pantry/models/product.dart';
import 'category_screen.dart';

class PantryScreen extends StatefulWidget {
  @override
  _PantryScreenState createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  bool _isAddingProduct = false; // Kontrola widoczności formularza
  String _selectedCategory = 'Dry';
  String? _productName;
  String? _brandName;
  int _quantityCount = 1;
  DateTime? _expirationDate;
  bool _useDays = false;
  int _selectedExpirationDays = 3;
  double? _grammage;
  String _selectedUnit = 'g'; // Domyślna jednostka

  void _toggleAddProduct() {
    setState(() {
      _isAddingProduct = !_isAddingProduct;
    });
  }

  void _increaseQuantity() {
    setState(() {
      _quantityCount++;
    });
  }

  void _decreaseQuantity() {
    setState(() {
      if (_quantityCount > 1) _quantityCount--;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_productName == null || _productName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product name is required')),
      );
      return;
    }

    if (_grammage == null || _grammage! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grammage is required and must be greater than 0')),
      );
      return;
    }

    if (_selectedUnit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unit is required')),
      );
      return;
    }

    final product = Product(
      name: _productName,
      brand: _brandName,
      category: _selectedCategory,
      quantityCount: _quantityCount,
      expirationDate: _useDays ? null : _expirationDate,
      expirationDays: _useDays ? _selectedExpirationDays : null,
      grammage: _grammage,
      unit: _selectedUnit,
    );

    try {
      await MongoDBHelper.insertProduct(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product added successfully')),
      );
      _toggleAddProduct(); // Zamknięcie formularza
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAddProduct,
        child: Icon(_isAddingProduct ? Icons.close : Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            if (!_isAddingProduct)
              Column(
                children: [
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
            if (_isAddingProduct)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (value) => setState(() => _productName = value),
                        decoration: InputDecoration(labelText: 'Product Name'),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        onChanged: (value) => setState(() => _brandName = value),
                        decoration: InputDecoration(
                          labelText: 'Brand (Optional)',
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: Icon(Icons.remove), onPressed: _decreaseQuantity),
                          Text('Quantity: $_quantityCount'),
                          IconButton(icon: Icon(Icons.add), onPressed: _increaseQuantity),
                        ],
                      ),
                      SizedBox(height: 8),
                      DropdownButton<String>(
                        value: _selectedCategory,
                        onChanged: (value) => setState(() => _selectedCategory = value!),
                        items: ['Fridge', 'Dry', 'Frozen', 'Drinks', 'Fresh', 'Other']
                            .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                            .toList(),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _useDays,
                            onChanged: (value) => setState(() => _useDays = value!),
                          ),
                          Text('Use Expiration Days'),
                        ],
                      ),
                      if (_useDays)
                        DropdownButton<int>(
                          value: _selectedExpirationDays,
                          onChanged: (value) =>
                              setState(() => _selectedExpirationDays = value!),
                          items: [2, 3, 5].map((days) {
                            return DropdownMenuItem(value: days, child: Text('$days Days'));
                          }).toList(),
                        )
                      else
                        ElevatedButton(
                          onPressed: _selectDate,
                          child: Text(
                            _expirationDate == null
                                ? 'Select Expiration Date'
                                : 'Selected Date: ${_expirationDate!.toLocal().toString().split(' ')[0]}',
                          ),
                        ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              onChanged: (value) => setState(() => _grammage = double.tryParse(value)),
                              decoration: InputDecoration(
                                labelText: 'Grammage',
                                hintText: 'Enter value',
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedUnit,
                            onChanged: (value) => setState(() => _selectedUnit = value!),
                            items: ['g', 'kg', 'ml', 'l', 'pcs']
                                .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                                .toList(),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveProduct,
                        child: Text('Save to Pantry'),
                      ),
                    ],
                  ),
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


