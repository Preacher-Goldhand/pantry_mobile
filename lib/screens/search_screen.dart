import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:pantry/utils/mongo_helper.dart';
import 'package:pantry/models/product.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;

  String? _productName;
  String? _brandName;
  String? _quantity;
  String? _ingredients;
  String? _error;
  String? _selectedCategory = 'Dry';
  DateTime? _selectedDate;

  void _clearResult() {
    _productName = null;
    _brandName = null;
    _quantity = null;
    _ingredients = null;
    _error = null;
  }

  Future<void> _searchBarcode(String barcode) async {
    final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['status'] == 1) {
            _productName = data['product']['product_name'] ?? 'No name available';
            _brandName = data['product']['brands'] ?? 'No brand available';
            _quantity = data['product']['quantity'] ?? 'No quantity available';
            _ingredients = data['product']['ingredients_text'] ?? 'No ingredients available';
            _error = null;
          } else {
            _clearResult();
            _error = 'Product not found.';
          }
        });
      } else {
        setState(() {
          _clearResult();
          _error = 'Connection error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _clearResult();
        _error = 'Error: $e';
      });
    }
  }

  Future<void> _saveToPantry() async {
    if (_productName != null && _selectedCategory != null) {
      // Tworzymy obiekt typu Product
      final product = Product(
        name: _productName,
        brand: _brandName,
        quantity: _quantity,
        ingredients: _ingredients,
        category: _selectedCategory,
        expirationDate: _selectedDate,
        barcode: _barcodeController.text,
      );

      try {
        // Przekazujemy obiekt Product do MongoDBHelper
        await MongoDBHelper.insertProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please ensure product details and category are selected.')),
      );
    }
  }


  void _openQRScanner() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: Text('QR Code Scanner')),
        body: QRView(
          key: _qrKey,
          onQRViewCreated: (QRViewController controller) {
            _controller = controller;
            controller.scannedDataStream.listen((scanData) {
              controller.pauseCamera();
              Navigator.of(context).pop();
              setState(() {
                _barcodeController.text = scanData.code ?? '';
              });
              _clearResult();
              _searchBarcode(scanData.code ?? '');
            });
          },
        ),
      );
    })).then((_) {
      _controller?.resumeCamera();
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _openQRScanner,
            icon: Icon(Icons.qr_code_scanner),
            label: Text('Scan barcode'),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _barcodeController,
            decoration: InputDecoration(
              labelText: 'Enter barcode',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _barcodeController.clear();
                    _clearResult();
                    _error = null;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final barcode = _barcodeController.text.trim();
              if (barcode.isNotEmpty) {
                _clearResult();
                _searchBarcode(barcode);
              } else {
                setState(() {
                  _error = 'Please enter a barcode';
                });
              }
            },
            child: Text('Find'),
          ),
          SizedBox(height: 30),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Colors.red),
            )
          else if (_productName != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: $_productName'),
                Text('Brand: $_brandName'),
                Text('Quantity: $_quantity'),
                Text('Ingredients: $_ingredients'),
                DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  items: <String>['Dry', 'Drink', 'Fats', 'Dairy', 'Other']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                ElevatedButton(
                  onPressed: _selectDate,
                  child: Text(
                    _selectedDate == null
                        ? 'Select expiration date'
                        : 'Expiration date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveToPantry,
                  child: Text('Save to Pantry'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
