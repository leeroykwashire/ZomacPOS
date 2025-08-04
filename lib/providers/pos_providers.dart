import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/cart_dao.dart';
import '../providers/database_providers.dart';

// Cart summary provider for a specific session
final cartSummaryProvider = FutureProvider.family<CartSummary, String>((ref, sessionId) async {
  final cartDao = ref.read(cartDaoProvider);
  return cartDao.getCartSummary(sessionId);
});

// Filtered products provider for POS
final filteredProductsProvider = FutureProvider.family<List<Product>, String>((ref, searchQuery) async {
  final database = ref.read(databaseProvider);
  final productsDao = database.productsDao;
  
  if (searchQuery.isEmpty) {
    return productsDao.getActiveProducts();
  }
  
  return productsDao.searchProducts(searchQuery);
});

// Product by barcode provider
final productByBarcodeProvider = FutureProvider.family<Product?, String>((ref, barcode) async {
  final database = ref.read(databaseProvider);
  final productsDao = database.productsDao;
  return productsDao.getProductByBarcode(barcode);
});

// Cart DAO provider
final cartDaoProvider = Provider<CartDao>((ref) {
  final database = ref.read(databaseProvider);
  return database.cartDao;
});

// POS Service provider
final posServiceProvider = Provider<POSService>((ref) {
  return POSService(ref);
});

// POS Service class
class POSService {
  final Ref _ref;

  POSService(this._ref);

  Future<Sale> processSale({
    required String sessionId,
    required CartSummary cartSummary,
    required String paymentMethod,
    String? customerName,
    String? customerPhone,
    required String cashierId,
  }) async {
    final database = _ref.read(databaseProvider);
    final salesDao = database.salesDao;
    final cartDao = database.cartDao;
    final productsDao = database.productsDao;

    // Calculate totals
    final subtotal = cartSummary.total;
    final taxRate = 0.10; // 10% tax
    final taxAmount = subtotal * taxRate;
    final totalAmount = subtotal + taxAmount;

    try {
      // Create the sale record
      final saleId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final sale = await salesDao.createSale(
        saleId: saleId,
        customerId: null, // We don't have customer management yet
        customerName: customerName,
        customerPhone: customerPhone,
        totalAmount: totalAmount,
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: 0.0,
        paymentMethod: paymentMethod,
        status: 'completed',
        cashierId: cashierId,
        notes: null,
      );

      // Create sale items from cart
      for (final cartItem in cartSummary.items) {
        await salesDao.addSaleItem(
          saleId: saleId,
          productId: cartItem.productId,
          productName: cartItem.productName,
          qty: cartItem.qty,
          price: cartItem.price,
          cost: 0.0, // We'll need to get this from product
          discount: 0.0,
          tax: (cartItem.subtotal * taxRate),
          subtotal: cartItem.subtotal,
        );

        // Update product stock
        await productsDao.updateProductStock(
          cartItem.productId,
          -cartItem.qty, // Negative to reduce stock
        );
      }

      // Clear the cart
      await cartDao.clearCart(sessionId);

      return sale;
    } catch (e) {
      throw Exception('Failed to process sale: $e');
    }
  }
}

// Receipt data class
class Receipt {
  final Sale sale;
  final List<SalesItem> items;
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final DateTime printTime;

  Receipt({
    required this.sale,
    required this.items,
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    required this.printTime,
  });
}

// Receipt service provider
final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService(ref);
});

class ReceiptService {
  final Ref _ref;

  ReceiptService(this._ref);

  Future<Receipt> generateReceipt(String saleId) async {
    final database = _ref.read(databaseProvider);
    final salesDao = database.salesDao;

    final sale = await salesDao.getSaleById(saleId);
    if (sale == null) {
      throw Exception('Sale not found');
    }

    final items = await salesDao.getSaleItems(saleId);

    return Receipt(
      sale: sale,
      items: items,
      businessName: 'ZomacPOS',
      businessAddress: '123 Business St, City, State 12345',
      businessPhone: '(555) 123-4567',
      printTime: DateTime.now(),
    );
  }

  String formatReceiptText(Receipt receipt) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('==============================');
    buffer.writeln('       ${receipt.businessName}');
    buffer.writeln('   ${receipt.businessAddress}');
    buffer.writeln('     ${receipt.businessPhone}');
    buffer.writeln('==============================');
    buffer.writeln();
    
    // Sale info
    buffer.writeln('Date: ${_formatDateTime(receipt.sale.createdAt)}');
    buffer.writeln('Sale ID: ${receipt.sale.id}');
    buffer.writeln('Cashier: ${receipt.sale.cashierId}');
    // Customer info is stored in notes field
    if (receipt.sale.notes != null && receipt.sale.notes!.contains('Customer:')) {
      final lines = receipt.sale.notes!.split('\n');
      for (final line in lines) {
        if (line.contains('Customer:') || line.contains('Phone:')) {
          buffer.writeln(line);
        }
      }
    }
    buffer.writeln();
    
    // Items
    buffer.writeln('Items:');
    buffer.writeln('------------------------------');
    for (final item in receipt.items) {
      buffer.writeln(item.productName);
      buffer.writeln('  ${item.qty} x \$${item.price.toStringAsFixed(2)} = \$${item.subtotal.toStringAsFixed(2)}');
    }
    buffer.writeln('------------------------------');
    
    // Totals
    buffer.writeln('Subtotal: \$${receipt.sale.subtotal.toStringAsFixed(2)}');
    buffer.writeln('Tax: \$${receipt.sale.tax.toStringAsFixed(2)}');
    buffer.writeln('Total: \$${receipt.sale.total.toStringAsFixed(2)}');
    buffer.writeln();
    
    // Payment
    buffer.writeln('Payment: ${receipt.sale.paymentMethod.toUpperCase()}');
    buffer.writeln();
    
    // Footer
    buffer.writeln('==============================');
    buffer.writeln('     Thank you for your');
    buffer.writeln('        business!');
    buffer.writeln('==============================');
    buffer.writeln('Printed: ${_formatDateTime(receipt.printTime)}');
    
    return buffer.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
