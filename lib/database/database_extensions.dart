import 'app_database.dart';

// Extension methods for easier data manipulation
extension ProductExtension on Product {
  double get totalValue => price * qty;
  
  bool get isLowStock => qty <= minQty; // Use minQty field from table
  
  double calculateTaxAmount(double quantity) {
    return (price * quantity * taxRate) / 100;
  }
  
  double calculateSubtotal(double quantity) {
    final subtotal = price * quantity;
    final tax = calculateTaxAmount(quantity);
    return subtotal + tax;
  }
  
  Map<String, dynamic> toSyncJson() {
    return {
      'id': syncId ?? id,
      'name': name,
      'price': price,
      'qty': qty,
      'currency_id': currencyId,
      'category_id': categoryId,
      'company_id': companyId,
      'sku': sku,
      'cost': cost,
      'tax_rate': taxRate,
      'description': description,
      'barcode': barcode,
      'min_qty': minQty,
      'track_stock': trackStock,
      'is_active': isActive,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

extension SaleExtension on Sale {
  String get formattedReceiptNumber {
    return 'RCP-${id.substring(0, 8).toUpperCase()}';
  }
  
  Map<String, dynamic> toSyncJson() {
    return {
      'id': syncId ?? id,
      'receipt_number': receiptNumber,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'amount_paid': amountPaid,
      'change': change,
      'status': status,
      'payment_method': paymentMethod,
      'notes': notes,
      'cashier_id': cashierId,
      'customer_id': customerId,
      'company_id': companyId,
      'sale_date': saleDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
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
      'id': id.toString(),
      'product_id': productId,
      'product_name': productName,
      'qty': qty,
      'price': price,
      'subtotal': subtotal,
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Helper classes for complex operations
class CartCalculator {
  static double calculateSubtotal(List<Cart> cartItems) {
    return cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }
  
  static double calculateTotalTax(List<Cart> cartItems, List<Product> products) {
    double totalTax = 0.0;
    for (final item in cartItems) {
      final product = products.firstWhere((p) => p.id == item.productId);
      totalTax += (item.subtotal * product.taxRate) / (100 + product.taxRate);
    }
    return totalTax;
  }
  
  static Map<String, double> calculateTotals(List<Cart> cartItems, List<Product> products) {
    final subtotal = calculateSubtotal(cartItems);
    final tax = calculateTotalTax(cartItems, products);
    return {
      'subtotal': subtotal - tax,
      'tax': tax,
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