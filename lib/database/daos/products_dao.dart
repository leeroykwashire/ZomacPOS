import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/products_table.dart';
import '../tables/categories_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products, Categories])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(AppDatabase db) : super(db);

  // Get all products
  Future<List<Product>> getAllProducts() => select(products).get();

  // Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) =>
    (select(products)..where((p) => p.categoryId.equals(categoryId))).get();

  // Get active products only
  Future<List<Product>> getActiveProducts() =>
    (select(products)..where((p) => p.isActive.equals(true))).get();

  // Search products by name or SKU
  Future<List<Product>> searchProducts(String query) =>
    (select(products)..where((p) => 
      p.name.like('%$query%') | p.sku.like('%$query%') | p.barcode.like('%$query%')))
    .get();

  // Get low stock products  
  Future<List<Product>> getLowStockProducts() async {
    final query = select(products)..where((p) => 
      p.trackStock.equals(true));
    
    final allProducts = await query.get();
    return allProducts.where((p) => p.qty <= p.minQty).toList();
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) =>
    (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();

  // Get product by barcode
  Future<Product?> getProductByBarcode(String barcode) =>
    (select(products)..where((p) => p.barcode.equals(barcode))).getSingleOrNull();

  // Get product by SKU
  Future<Product?> getProductBySku(String sku) =>
    (select(products)..where((p) => p.sku.equals(sku))).getSingleOrNull();

  // Update product stock
  Future<void> updateStock(String productId, int newQty) =>
    (update(products)..where((p) => p.id.equals(productId)))
      .write(ProductsCompanion(qty: Value(newQty), updatedAt: Value(DateTime.now())));

  // Update product stock by quantity change (for sales)
  Future<void> updateProductStock(String productId, int quantityChange) async {
    final product = await getProductById(productId);
    if (product != null) {
      final newQty = product.qty + quantityChange;
      await updateStock(productId, newQty);
    }
  }

  // Decrease stock (for sales)
  Future<void> decreaseStock(String productId, int quantity) async {
    final product = await getProductById(productId);
    if (product != null && product.trackStock) {
      final newQty = product.qty - quantity;
      await updateStock(productId, newQty);
    }
  }

  // Increase stock (for restocking)
  Future<void> increaseStock(String productId, int quantity) async {
    final product = await getProductById(productId);
    if (product != null) {
      final newQty = product.qty + quantity;
      await updateStock(productId, newQty);
    }
  }

  // Generate automatic SKU if not provided
  Future<String> _generateSKU() async {
    final count = await getTotalProductsCount();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return 'SKU${(count + 1).toString().padLeft(4, '0')}$timestamp';
  }

  // Generate automatic barcode if not provided
  Future<String> _generateBarcode() async {
    final count = await getTotalProductsCount();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    return '${(count + 1).toString().padLeft(6, '0')}$timestamp';
  }

  // Check if SKU already exists
  Future<bool> skuExists(String sku) async {
    final result = await (select(products)..where((p) => p.sku.equals(sku))).getSingleOrNull();
    return result != null;
  }

  // Check if barcode already exists
  Future<bool> barcodeExists(String barcode) async {
    final result = await (select(products)..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
    return result != null;
  }

  // Generate unique SKU
  Future<String> generateUniqueSKU() async {
    String sku;
    do {
      sku = await _generateSKU();
    } while (await skuExists(sku));
    return sku;
  }

  // Generate unique barcode
  Future<String> generateUniqueBarcode() async {
    String barcode;
    do {
      barcode = await _generateBarcode();
    } while (await barcodeExists(barcode));
    return barcode;
  }

  // Create product with automatic SKU/barcode generation
  Future<String> createProduct(ProductsCompanion product) async {
    // Generate SKU if not provided
    String? sku = product.sku.present ? product.sku.value : null;
    if (sku == null || sku.isEmpty) {
      sku = await generateUniqueSKU();
    }

    // Generate barcode if not provided
    String? barcode = product.barcode.present ? product.barcode.value : null;
    if (barcode == null || barcode.isEmpty) {
      barcode = await generateUniqueBarcode();
    }

    // Create product with generated values
    final enhancedProduct = product.copyWith(
      sku: Value(sku),
      barcode: Value(barcode),
    );

    return await into(products).insertReturning(enhancedProduct).then((p) => p.id);
  }

  // Insert product (alias for createProduct)
  Future<String> insertProduct(ProductsCompanion product) => createProduct(product);

  // Update product
  Future<void> updateProduct(String productId, ProductsCompanion product) =>
    (update(products)..where((p) => p.id.equals(productId)))
      .write(product.copyWith(updatedAt: Value(DateTime.now())));

  // Delete product (soft delete)
  Future<void> deleteProduct(String productId) =>
    (update(products)..where((p) => p.id.equals(productId)))
      .write(ProductsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

  // Get total products count
  Future<int> getTotalProductsCount() async {
    final result = await (selectOnly(products)
      ..addColumns([products.id.count()])).getSingleOrNull();
    return result?.read(products.id.count()) ?? 0;
  }

  // Get active products count
  Future<int> getActiveProductsCount() async {
    final result = await (selectOnly(products)
      ..addColumns([products.id.count()])
      ..where(products.isActive.equals(true))).getSingleOrNull();
    return result?.read(products.id.count()) ?? 0;
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    final query = select(products)..where((p) => 
      p.trackStock.equals(true) & p.qty.equals(0));
    return await query.get();
  }

  // Get products with categories (join)
  Future<List<ProductWithCategory>> getProductsWithCategories() {
    final query = select(products).join([
      leftOuterJoin(categories, categories.id.equalsExp(products.categoryId))
    ]);
    
    return query.map((row) {
      final product = row.readTable(products);
      final category = row.readTableOrNull(categories);
      return ProductWithCategory(product: product, category: category);
    }).get();
  }

  // Get products by company
  Future<List<Product>> getProductsByCompany(String companyId) =>
    (select(products)..where((p) => p.companyId.equals(companyId))).get();
}

// Helper class for products with categories
class ProductWithCategory {
  final Product product;
  final Category? category;

  ProductWithCategory({required this.product, this.category});
}
