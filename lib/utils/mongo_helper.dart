import 'package:mongo_dart/mongo_dart.dart';
import 'package:pantry/models/product.dart';  // Import the Product model

class MongoDBHelper {
  static final _dbUrl = 'mongodb://10.0.2.2:27017/PantryApp'; // MongoDB address
  static final _collectionName = 'products'; // Collection name

  // Connect function to handle db initialization
  static Future<DbCollection> connect() async {
    Db db = Db(_dbUrl); // Create a Db instance
    await db.open(); // Open the database connection
    return db.collection(_collectionName); // Return the collection object
  }

  // Inserting a product
  static Future<void> insertProduct(Product product) async {
    try {
      DbCollection collection = await connect(); // Get the collection through the connect function

      // Convert the Product to Map before inserting
      Map<String, dynamic> productMap = product.toMap();

      // Insert product into the collection
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
      var objectId = ObjectId.fromHexString(productId);  // Use productId to create ObjectId
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
      DbCollection collection = await connect(); // Get the collection through the connect function

      // Ensure the product has a valid ObjectId
      if (product.id == null) {
        print('Product does not have a valid ID');
        return;
      }

      var objectId = ObjectId.fromHexString(product.id!); // Force unwrapping because it's ensured to be non-null

      // Update the expirationDate field in the product
      var result = await collection.update(
        where.eq('_id', objectId),
        modify.set('expirationDate', newExpirationDate.toIso8601String()),
      );

      // Check if the update was successful by inspecting the result
      if (result['nModified'] > 0) {
        print('Successfully updated expirationDate to $newExpirationDate');
      } else {
        print('No documents were modified.');
      }
    } catch (e) {
      print('Failed to update expiration date: $e');
    }
  }
  // Fetch products by category
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      DbCollection collection = await connect();
      var products = await collection.find({'category': category}).toList();
      print(products);
      print('Fetching products for category: $category');
      return products.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Failed to fetch products: $e');
      return [];
    }
  }

  static Future<List<Product>> getProductsByCategoryAndSearch(String category, String searchQuery) async {
    try {
      DbCollection collection = await connect();

      // Dodajemy warunek, że searchQuery musi mieć co najmniej 2 znaki
      if (searchQuery.length < 2) {
        print('Search query must have at least 2 characters.');
        return []; // Możesz zwrócić pustą listę lub przekazać komunikat o błędzie
      }

      // Tworzymy zapytanie z regex dla pola 'name' z minimalną długością 2 znaków
      var query = {
        'name': {'\$regex': searchQuery, '\$options': 'i'}, // Case-insensitive search dla nazwy
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
      DbCollection collection = await connect(); // Get the collection through the connect function
      var products = await collection.find().toList();

      // Deserialize the list of products
      return products.map((productMap) => Product.fromMap(productMap)).toList();
    } catch (e) {
      print('Failed to fetch products: $e');
      return [];
    }
  }

  // Fetch product by _id
  static Future<Product?> getProductById(String id) async {
    try {
      DbCollection collection = await connect(); // Get the collection through the connect function

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

  // Update product quantity count
  static Future<void> updateProductQuantityCount(Product product, int newQuantityCount) async {
    try {
      DbCollection collection = await connect(); // Get the collection through the connect function

      // Ensure the product has a valid ObjectId
      if (product.id == null) {
        print('Product does not have a valid ID');
        return;
      }

      var objectId = ObjectId.fromHexString(product.id!); // Force unwrapping because it's ensured to be non-null

      // Update the quantityCount field in the product
      var result = await collection.update(
        where.eq('_id', objectId),
        modify.set('quantityCount', newQuantityCount),
      );

      // Check if the update was successful by inspecting the result
      if (result['nModified'] > 0) {
        print('Successfully updated quantityCount to $newQuantityCount');
      } else {
        print('No documents were modified.');
      }
    } catch (e) {
      print('Failed to update quantity count: $e');
    }
  }

  // Fetch product's current quantity count by product id
  static Future<int> getProductQuantityCount(String productId) async {
    try {
      DbCollection collection = await connect(); // Get the collection through the connect function

      // Convert string productId to ObjectId for querying
      var objectId = ObjectId.fromHexString(productId);

      // Find the product by ID
      var product = await collection.findOne(where.eq('_id', objectId));

      // If product is found and has a valid 'quantityCount', return it, otherwise return 0
      return product?['quantityCount'] ?? 0;
    } catch (e) {
      print('Error fetching product quantity count: $e');
      return 0; // Return 0 if there's an error
    }
  }
}
