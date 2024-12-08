import 'package:mongo_dart/mongo_dart.dart';
import 'package:pantry/models/product.dart';

class MongoDBHelper {
  static final _dbUrl = 'mongodb://10.0.2.2:27017/PantryApp';
  static final _collectionName = 'products';

  static Future<DbCollection> connect() async {
    Db db = Db(_dbUrl);
    await db.open();
    return db.collection(_collectionName);
  }

  // Inserting a product
  static Future<void> insertProduct(Product product) async {
    try {
      DbCollection collection = await connect();
      Map<String, dynamic> productMap = product.toMap();
      await collection.insert(productMap);
      print('Product saved to pantry');
    } catch (e) {
      print('Failed to save product: $e');
    }
  }

  // Deleting products
  static Future<void> deleteProduct(String productId) async {
    try {
      DbCollection collection = await connect();
      var objectId = ObjectId.fromHexString(productId);
      var result = await collection.remove(where.eq('_id', objectId));
      if (result['n'] > 0) {
        print('Product deleted successfully');
      } else {
        print('Failed to delete product');
      }
    } catch (e) {
      print('Error deleting product: $e');
    }
  }

  // Update product expiration date
  static Future<void> updateProductExpirationDate(Product product, DateTime newExpirationDate) async {
    try {
      DbCollection collection = await connect();

      if (product.id == null) {
        print('Product does not have a valid ID');
        return;
      }

      var objectId = ObjectId.fromHexString(product.id!);
      var result = await collection.update(
        where.eq('_id', objectId),
        modify.set('expirationDate', newExpirationDate.toIso8601String()),
      );

      if (result['nModified'] > 0) {
        print('Successfully updated expirationDate to $newExpirationDate');
      } else {
        print('No documents were modified.');
      }
    } catch (e) {
      print('Failed to update expiration date: $e');
    }
  }

  // Update product quantity count
  static Future<void> updateProductQuantityCount(Product product, int newQuantityCount) async {
    try {
      DbCollection collection = await connect();

      if (product.id == null) {
        print('Product does not have a valid ID');
        return;
      }

      var objectId = ObjectId.fromHexString(product.id!);
      var result = await collection.update(
        where.eq('_id', objectId),
        modify.set('quantityCount', newQuantityCount),
      );

      if (result['nModified'] > 0) {
        print('Successfully updated quantityCount to $newQuantityCount');
      } else {
        print('No documents were modified.');
      }
    } catch (e) {
      print('Failed to update quantity count: $e');
    }
  }

  // Update product expiration days
  static Future<void> updateExpirationDays(Product product, int newExpirationDays) async {
    try {
      DbCollection collection = await connect();

      if (product.id == null) {
        print('Product does not have a valid ID');
        return;
      }

      var objectId = ObjectId.fromHexString(product.id!);
      var result = await collection.update(
        where.eq('_id', objectId),
        modify.set('expirationDays', newExpirationDays),
      );

      if (result['nModified'] > 0) {
        print('Successfully updated expirationDays to $newExpirationDays');
      } else {
        print('No documents were modified.');
      }
    } catch (e) {
      print('Failed to update expiration days: $e');
    }
  }


  // Fetch products by category with optional sorting by expiration date
  static Future<List<Product>> getProductsByCategory(String category, {bool ascending = true}) async {
    try {
      DbCollection collection = await connect();
      var cursor = collection.find({'category': category});
      var products = await cursor.toList();

      if (ascending) {
        products.sort((a, b) {
          DateTime dateA = DateTime.parse(a['expirationDate'] ?? '1970-01-01');
          DateTime dateB = DateTime.parse(b['expirationDate'] ?? '1970-01-01');
          return dateA.compareTo(dateB);
        });
      } else {
        products.sort((a, b) {
          DateTime dateA = DateTime.parse(a['expirationDate'] ?? '1970-01-01');
          DateTime dateB = DateTime.parse(b['expirationDate'] ?? '1970-01-01');
          return dateB.compareTo(dateA);
        });
      }

      // Convert fetched documents to Product models
      return products.map((doc) => Product.fromMap(doc)).toList();
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  static Future<List<Product>> getProductsByCategoryAndSearch(String category, String searchQuery) async {
    try {
      DbCollection collection = await connect();

      if (searchQuery.length < 2) {
        return [];
      }
      var query = {
        'name': {'\$regex': searchQuery, '\$options': 'i'},
      };

      var products = await collection.find(query).toList();
      print('Fetching products with search query: $searchQuery');
      return products.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Failed to fetch products: $e');
      return [];
    }
  }

  // Fetch all products
  static Future<List<Product>> getAllProducts() async {
    try {
      DbCollection collection = await connect();
      var products = await collection.find().toList();
      return products.map((productMap) => Product.fromMap(productMap)).toList();
    } catch (e) {
      print('Failed to fetch products: $e');
      return [];
    }
  }

  // Fetch product by _id
  static Future<Product?> getProductById(String id) async {
    try {
      DbCollection collection = await connect();
      var objectId = ObjectId.fromHexString(id);
      var productMap = await collection.findOne(where.eq('_id', objectId));

      if (productMap != null) {
        return Product.fromMap(productMap);
      }
      return null;
    } catch (e) {
      print('Failed to fetch product by ID: $e');
      return null;
    }
  }

  // Fetch product's current quantity count by product id
  static Future<int> getProductQuantityCount(String productId) async {
    try {
      DbCollection collection = await connect();
      var objectId = ObjectId.fromHexString(productId);
      var product = await collection.findOne(where.eq('_id', objectId));
      return product?['quantityCount'] ?? 0;
    } catch (e) {
      print('Error fetching product quantity count: $e');
      return 0; // Return 0 if there's an error
    }
  }
}
