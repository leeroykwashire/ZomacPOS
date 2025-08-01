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

  // Update product stock
  Future<void> updateStock(String productId, int newQty) =>
    (update(products)..where((p) => p.id.equals(productId)))
      .write(ProductsCompanion(qty: Value(newQty), updatedAt: Value(DateTime.now())));

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

  // Create product
  Future<String> createProduct(ProductsCompanion product) async {
    return await into(products).insertReturning(product).then((p) => p.id);
  }

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
