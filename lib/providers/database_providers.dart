import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/sync_service.dart';
import '../database/tables/all_tables.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final database = ref.read(databaseProvider);
  return SyncService(database);
});

// Products providers
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getAllProducts();
});

final productsByCategoryProvider = FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  final database = ref.read(databaseProvider);
  return await database.getProductsByCategory(categoryId);
});

final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getLowStockProducts();
});

// Categories providers
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getAllCategories();
});

final activeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getActiveCategories();
});

// Sales providers
final salesProvider = FutureProvider<List<Sale>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getAllSales();
});

final salesByUserProvider = FutureProvider.family<List<Sale>, String>((ref, userId) async {
  final database = ref.read(databaseProvider);
  return await database.getSalesByUser(userId);
});

// Cart provider with state notifier for real-time updates
final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<List<Cart>>>((ref) {
  final database = ref.read(databaseProvider);
  return CartNotifier(database);
});

class CartNotifier extends StateNotifier<AsyncValue<List<Cart>>> {
  final AppDatabase _database;
  String? _currentUserId;

  CartNotifier(this._database) : super(const AsyncValue.loading());

  void setUser(String userId) {
    _currentUserId = userId;
    _loadCart();
  }

  Future<void> _loadCart() async {
    if (_currentUserId == null) return;
    
    try {
      state = const AsyncValue.loading();
      final cart = await _database.getUserCart(_currentUserId!);
      state = AsyncValue.data(cart);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addToCart(Product product, int quantity) async {
    if (_currentUserId == null) return;

    try {
      final subtotal = product.price * quantity;
      
      await _database.into(_database.carts).insert(CartsCompanion.insert(
        id: IdGenerator.generateLocalId(),
        userId: _currentUserId!,
        productId: product.id,
        qty: Value(quantity),
        price: product.price,
        subtotal: subtotal,
      ));
      
      await _loadCart();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateCartItem(String cartId, int newQuantity) async {
    try {
      final cartItem = await (_database.select(_database.carts)
            ..where((c) => c.id.equals(cartId)))
          .getSingle();
      
      final newSubtotal = cartItem.price * newQuantity;
      
      await (_database.update(_database.carts)
            ..where((c) => c.id.equals(cartId)))
          .write(CartsCompanion(
            qty: Value(newQuantity),
            subtotal: Value(newSubtotal),
          ));
      
      await _loadCart();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeFromCart(String cartId) async {
    try {
      await (_database.delete(_database.carts)
            ..where((c) => c.id.equals(cartId)))
          .go();
      
      await _loadCart();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearCart() async {
    if (_currentUserId == null) return;
    
    try {
      await _database.clearUserCart(_currentUserId!);
      await _loadCart();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Sync status provider
final syncStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getSyncStatistics();
});

// Currencies provider
final currenciesProvider = FutureProvider<List<Currency>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getAllCurrencies();
});

final defaultCurrencyProvider = FutureProvider<Currency?>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getDefaultCurrency();
});

// Customers provider
final customersProvider = FutureProvider<List<CashCustomer>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getAllCustomers();
});

// Expenses providers
final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getAllExpenses();
});

// Cash drawer provider
final activeCashDrawerProvider = FutureProvider.family<CashDrawer?, String>((ref, tellerId) async {
  final database = ref.read(databaseProvider);
  return await database.getActiveCashDrawer(tellerId);
});

// Users provider
final usersProvider = FutureProvider<List<User>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getAllUsers();
});

// Companies provider
final companiesProvider = FutureProvider<List<Company>>((ref) async {
  final database = ref.read(databaseProvider);
  return await database.getAllCompanies();
});