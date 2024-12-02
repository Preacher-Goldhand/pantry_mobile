import 'package:mongo_dart/mongo_dart.dart';

class Product {
  String? id;
  String? name;
  String? brand;
  String? quantity;
  String? ingredients;
  String? category;
  DateTime? expirationDate;
  String? barcode;
  int? quantityCount;
  int? expirationDays;

  Product({
    this.id,
    this.name,
    this.brand,
    this.quantity,
    this.ingredients,
    this.category,
    this.expirationDate,
    this.barcode,
    this.quantityCount,
    this.expirationDays,
  });

  // Convert a Product object to a Map (Serialization)
  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : null,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'ingredients': ingredients,
      'category': category,
      'expirationDate': expirationDate?.toIso8601String(),
      'barcode': barcode,
      'quantityCount': quantityCount,
      'expirationDays': expirationDays,
    };
  }

  // Convert a Map to a Product object (Deserialization)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['_id'] != null ? (map['_id'] as ObjectId).toHexString() : null,
      name: map['name'],
      brand: map['brand'],
      quantity: map['quantity'],
      ingredients: map['ingredients'],
      category: map['category'],
      expirationDate: map['expirationDate'] != null
          ? DateTime.parse(map['expirationDate'])
          : null,
      barcode: map['barcode'],
      quantityCount: map['quantityCount'],
      expirationDays: map['expirationDays'],
    );
  }
}
