import 'tables/all_tables.dart';

// Extension methods for easier data manipulation
extension ProductExtension on Product {
  double get totalValue => price * qty;
  
  bool get isLowStock => qty <= 10; // Configurable threshold
  
  double calculateVatAmount(double quantity) {
    return (price * quantity * vatRate) / 100;
  }
  
  double calculateSubtotal(double quantity) {
    final subtotal = price * quantity;
    final vat = calculateVatAmount(quantity);
    return subtotal + vat;
  }
  
  Map<String, dynamic> toSyncJson() {
    return {
      'id': syncId ?? id,
      'name': name,
      'price': price,
      'qty': qty,
      'currency_id': currencyId,
      'warehouse_id': warehouseId,
      'category_id': categoryId,
      'company_id': companyId,
      'sku': sku,
      'cost_price': costPrice,
      'vat_rate': vatRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

extension SaleExtension on Sale {
  String get formattedReceiptNumber {
    return receiptNumber ?? 'RCP-${id.substring(0, 8).toUpperCase()}';
  }
  
  Map<String, dynamic> toSyncJson() {
    return {
      'id': syncId ?? id,
      'user_id': userId,
      'company_id': companyId,
      'total_amount': totalAmount,
      'status': status,
      'payment_method': paymentMethod,
      'notes': notes,
      'cash_customer_id': cashCustomerId,
      'vat_amount': vatAmount,
      'receipt_number': receiptNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

extension CashDrawerExtension on CashDrawer {
  double get totalExpected => openingBalance + cashSalesTotal;
  
  double get variance {
    if (closingBalance == null) return 0.0;
    return closingBalance! - totalExpected;
  }
  
  bool get isBalanced => variance.abs() < 0.01; // Allow for small rounding differences
}

extension UserExtension on User {
  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';
  bool get isSuperuser => role == 'superuser';
}

extension CartExtension on Cart {
  double get itemTotal => price * qty;
  
  Map<String, dynamic> toSyncJson() {
    return {
      'id': syncId ?? id,
      'user_id': userId,
      'product_id': productId,
      'qty': qty,
      'price': price,
      'subtotal': subtotal,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Helper classes for complex operations
class CartCalculator {
  static double calculateSubtotal(List<Cart> cartItems) {
    return cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }
  
  static double calculateTotalVat(List<Cart> cartItems, List<Product> products) {
    double totalVat = 0.0;
    for (final item in cartItems) {
      final product = products.firstWhere((p) => p.id == item.productId);
      totalVat += (item.subtotal * product.vatRate) / (100 + product.vatRate);
    }
    return totalVat;
  }
  
  static Map<String, double> calculateTotals(List<Cart> cartItems, List<Product> products) {
    final subtotal = calculateSubtotal(cartItems);
    final vat = calculateTotalVat(cartItems, products);
    return {
      'subtotal': subtotal - vat,
      'vat': vat,
      'total': subtotal,
    };
  }
}

// Enums for better type safety
enum UserRole { admin, cashier, superuser }
enum SaleStatus { pending, completed, cancelled, refunded }
enum PaymentMethod { cash, card, mobileMoney, split }
enum VarianceType { surplus, shortage, match }
enum SyncOperation { create, update, delete }
enum SyncState { pending, syncing, synced, conflict, error }