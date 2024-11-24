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
}
