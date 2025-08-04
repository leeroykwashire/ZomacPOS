import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/carts_table.dart';
import '../tables/products_table.dart';

part 'cart_dao.g.dart';

@DriftAccessor(tables: [Carts, Products])
class CartDao extends DatabaseAccessor<AppDatabase> with _$CartDaoMixin {
  CartDao(AppDatabase db) : super(db);

  // Get all cart items for a session
  Future<List<Cart>> getCartItems(String sessionId) =>
    (select(carts)..where((c) => c.sessionId.equals(sessionId))).get();

  // Get cart items with product details
  Future<List<CartWithProduct>> getCartItemsWithProducts(String sessionId) {
    final query = select(carts).join([
      leftOuterJoin(products, products.id.equalsExp(carts.productId))
    ])..where(carts.sessionId.equals(sessionId));
    
    return query.map((row) {
      final cart = row.readTable(carts);
      final product = row.readTableOrNull(products);
      return CartWithProduct(cart: cart, product: product);
    }).get();
  }

  // Add item to cart
  Future<void> addToCart(String sessionId, String productId, String productName, int quantity, double price) async {
    final existingItem = await (select(carts)
      ..where((c) => c.sessionId.equals(sessionId) & c.productId.equals(productId)))
      .getSingleOrNull();

    if (existingItem != null) {
      // Update existing item
      final newQty = existingItem.qty + quantity;
      final newSubtotal = newQty * price;
      
      await (update(carts)..where((c) => c.id.equals(existingItem.id)))
        .write(CartsCompanion(
          qty: Value(newQty),
          subtotal: Value(newSubtotal),
        ));
    } else {
      // Add new item
      await into(carts).insert(CartsCompanion.insert(
        productId: productId,
        productName: productName,
        qty: quantity,
        price: price,
        subtotal: quantity * price,
        sessionId: sessionId,
      ));
    }
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(int cartId, int newQuantity) async {
    final cartItem = await (select(carts)..where((c) => c.id.equals(cartId))).getSingle();
    final newSubtotal = newQuantity * cartItem.price;
    
    if (newQuantity <= 0) {
      await removeFromCart(cartId);
    } else {
      await (update(carts)..where((c) => c.id.equals(cartId)))
        .write(CartsCompanion(
          qty: Value(newQuantity),
          subtotal: Value(newSubtotal),
        ));
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(int cartId) =>
    (delete(carts)..where((c) => c.id.equals(cartId))).go();

  // Clear entire cart for session
  Future<void> clearCart(String sessionId) =>
    (delete(carts)..where((c) => c.sessionId.equals(sessionId))).go();

  // Get cart total
  Future<double> getCartTotal(String sessionId) async {
    final cartItems = await getCartItems(sessionId);
    return cartItems.fold<double>(0, (sum, item) => sum + item.subtotal);
  }

  // Get cart item count
  Future<int> getCartItemCount(String sessionId) async {
    final cartItems = await getCartItems(sessionId);
    return cartItems.fold<int>(0, (sum, item) => sum + item.qty);
  }

  // Check if product is in cart
  Future<bool> isProductInCart(String sessionId, String productId) async {
    final item = await (select(carts)
      ..where((c) => c.sessionId.equals(sessionId) & c.productId.equals(productId)))
      .getSingleOrNull();
    return item != null;
  }

  // Get total cart items count across all sessions (for dashboard)
  Future<int> getCartItemsCount() async {
    final result = await (selectOnly(carts)
      ..addColumns([carts.qty.sum()])).getSingleOrNull();
    return result?.read(carts.qty.sum()) ?? 0;
  }

  // Get cart summary
  Future<CartSummary> getCartSummary(String sessionId) async {
    final items = await getCartItems(sessionId);
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final itemCount = items.fold<int>(0, (sum, item) => sum + item.qty);
    
    return CartSummary(
      itemCount: itemCount,
      total: total,
      items: items,
    );
  }
}

// Helper classes
class CartWithProduct {
  final Cart cart;
  final Product? product;

  CartWithProduct({required this.cart, this.product});
}

class CartSummary {
  final int itemCount;
  final double total;
  final List<Cart> items;

  CartSummary({
    required this.itemCount,
    required this.total,
    required this.items,
  });
}
