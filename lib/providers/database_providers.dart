import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/id_generator.dart';
import '../database/daos/sync_dao.dart';
import '../database/daos/cart_dao.dart';
import '../database/daos/sales_dao.dart';

// Export the SalesSummary class for use in providers
export '../database/daos/sales_dao.dart' show SalesSummary;

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Current session provider for cart management
final sessionProvider = StateProvider<String>((ref) {
  return IdGenerator.generateSessionId();
});

// Cart state management using the CartDao
class CartNotifier extends StateNotifier<List<Cart>> {
  final CartDao _cartDao;
  final String _sessionId;

  CartNotifier(this._cartDao, this._sessionId) : super([]) {
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final items = await _cartDao.getCartItems(_sessionId);
    state = items;
  }

  Future<void> addToCart(String productId, String productName, int quantity, double price) async {
    await _cartDao.addToCart(_sessionId, productId, productName, quantity, price);
    await _loadCartItems();
  }

  Future<void> updateQuantity(int cartId, int newQuantity) async {
    await _cartDao.updateCartItemQuantity(cartId, newQuantity);
    await _loadCartItems();
  }

  Future<void> removeItem(int cartId) async {
    await _cartDao.removeFromCart(cartId);
    await _loadCartItems();
  }

  Future<void> clearCart() async {
    await _cartDao.clearCart(_sessionId);
    state = [];
  }

  Future<double> getTotal() async {
    return await _cartDao.getCartTotal(_sessionId);
  }

  Future<int> getItemCount() async {
    return await _cartDao.getCartItemCount(_sessionId);
  }
}

// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, List<Cart>>((ref) {
  final database = ref.watch(databaseProvider);
  final sessionId = ref.watch(sessionProvider);
  return CartNotifier(database.cartDao, sessionId);
});

// Products provider
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.productsDao.getActiveProducts();
});

// Products by category provider
final productsByCategoryProvider = FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  final database = ref.watch(databaseProvider);
  return database.productsDao.getProductsByCategory(categoryId);
});

// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.select(database.categories).get();
});

// Sales provider for today
final todaysSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.salesDao.getTodaysSales();
});

// Users provider
final usersProvider = FutureProvider<List<User>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.usersDao.getActiveUsers();
});

// Sync statistics provider
final syncStatsProvider = FutureProvider<SyncStats>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.syncDao.getSyncStats();
});

// Current user provider (you'll need to implement authentication)
final currentUserProvider = StateProvider<User?>((ref) => null);

// Low stock products provider
final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.productsDao.getLowStockProducts();
});

// Sales summary provider
final salesSummaryProvider = FutureProvider.family<SalesSummary, DateRange>((ref, dateRange) async {
  final database = ref.watch(databaseProvider);
  return database.salesDao.getSalesSummary(dateRange.start, dateRange.end);
});

// Helper class for date range
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}