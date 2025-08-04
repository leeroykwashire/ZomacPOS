import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_providers.dart';

// Products Provider
final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  final database = ref.watch(databaseProvider);
  return ProductsNotifier(database);
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final AppDatabase _database;

  ProductsNotifier(this._database) : super(const AsyncValue.loading()) {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      state = const AsyncValue.loading();
      final products = await _database.productsDao.getAllProducts();
      state = AsyncValue.data(products);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addProduct(ProductsCompanion product) async {
    try {
      await _database.productsDao.insertProduct(product);
      await _loadProducts(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateProduct(String id, ProductsCompanion product) async {
    try {
      await _database.productsDao.updateProduct(id, product);
      await _loadProducts(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _database.productsDao.deleteProduct(id);
      await _loadProducts(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  void refresh() => _loadProducts();
}

// Categories Provider
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<Category>>>((ref) {
  final database = ref.watch(databaseProvider);
  return CategoriesNotifier(database);
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final AppDatabase _database;

  CategoriesNotifier(this._database) : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final categories = await _database.categoriesDao.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addCategory(CategoriesCompanion category) async {
    try {
      await _database.categoriesDao.insertCategory(category);
      await _loadCategories(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateCategory(String id, CategoriesCompanion category) async {
    try {
      await _database.categoriesDao.updateCategory(id, category);
      await _loadCategories(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _database.categoriesDao.deleteCategory(id);
      await _loadCategories(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  void refresh() => _loadCategories();

  // Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    return await _database.productsDao.getProductsByCategory(categoryId);
  }
}

// Low Stock Products Provider
final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await database.productsDao.getLowStockProducts();
});

// Search Products Provider
final searchProductsProvider = StateProvider.family<AsyncValue<List<Product>>, String>((ref, query) {
  return const AsyncValue.loading();
});

// Product Search Notifier
final productSearchNotifier = StateNotifierProvider<ProductSearchNotifier, AsyncValue<List<Product>>>((ref) {
  final database = ref.watch(databaseProvider);
  return ProductSearchNotifier(database);
});

class ProductSearchNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final AppDatabase _database;

  ProductSearchNotifier(this._database) : super(const AsyncValue.data([]));

  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final products = await _database.productsDao.searchProducts(query);
      state = AsyncValue.data(products);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

// Single Product Provider
final productProvider = FutureProvider.family<Product?, String>((ref, productId) async {
  final database = ref.watch(databaseProvider);
  return await database.productsDao.getProductById(productId);
});

// Product Statistics Provider
final productStatsProvider = FutureProvider<ProductStats>((ref) async {
  final database = ref.watch(databaseProvider);
  
  final totalProducts = await database.productsDao.getTotalProductsCount();
  final lowStockProducts = await database.productsDao.getLowStockProducts();
  final outOfStockProducts = await database.productsDao.getOutOfStockProducts();
  final activeProducts = await database.productsDao.getActiveProductsCount();
  
  return ProductStats(
    totalProducts: totalProducts,
    lowStockCount: lowStockProducts.length,
    outOfStockCount: outOfStockProducts.length,
    activeProducts: activeProducts,
  );
});

// Product Stats Model
class ProductStats {
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final int activeProducts;

  ProductStats({
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.activeProducts,
  });

  int get inactiveProducts => totalProducts - activeProducts;
}
