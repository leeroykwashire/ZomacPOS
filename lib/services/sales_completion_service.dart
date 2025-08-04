import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/cart_dao.dart';
import '../database/daos/products_dao.dart';
import '../database/daos/sales_dao.dart';
import '../database/daos/stock_movements_dao.dart';
import 'receipt_printing_service.dart';

class SalesCompletionService {
  final AppDatabase _database;
  final CartDao _cartDao;
  final ProductsDao _productsDao;
  final SalesDao _salesDao;
  final StockMovementsDao _stockMovementsDao;

  SalesCompletionService(this._database)
      : _cartDao = _database.cartDao,
        _productsDao = _database.productsDao,
        _salesDao = _database.salesDao,
        _stockMovementsDao = _database.stockMovementsDao;

  /// Complete a sale transaction from cart
  Future<SaleCompletionResult> completeSale({
    required String sessionId,
    required String paymentMethod,
    required double amountPaid,
    String? customerId,
    double discountAmount = 0.0,
    double taxRate = 0.0,
    String? notes,
    bool printReceipt = true,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
  }) async {
    try {
      // Get cart items
      final cartItems = await _cartDao.getCartItemsWithProducts(sessionId);
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Calculate totals
      final subtotal = cartItems.fold<double>(
        0.0,
        (sum, item) => sum + item.cart.subtotal,
      );
      final taxAmount = subtotal * taxRate;
      final total = subtotal + taxAmount - discountAmount;

      if (amountPaid < total) {
        throw Exception('Insufficient payment amount');
      }

      final changeAmount = amountPaid - total;

      // Start transaction
      return await _database.transaction(() async {
        // Create sale record
        final saleId = await _salesDao.createSale(SalesCompanion.insert(
          saleDate: DateTime.now(),
          subtotal: subtotal,
          taxAmount: taxAmount,
          discountAmount: discountAmount,
          total: total,
          paymentMethod: paymentMethod,
          amountPaid: amountPaid,
          changeAmount: changeAmount,
          customerId: Value(customerId),
          notes: Value(notes),
        ));

        final sale = await _salesDao.getSaleById(saleId);
        final saleItems = <SaleItem>[];
        final products = <Product>[];

        // Process each cart item
        for (final cartItem in cartItems) {
          final cart = cartItem.cart;
          final product = cartItem.product;

          if (product == null) {
            throw Exception('Product not found for cart item: ${cart.productName}');
          }

          // Create sale item
          await _salesDao.addSaleItem(SaleItemsCompanion.insert(
            saleId: saleId,
            productId: cart.productId,
            productName: cart.productName,
            qty: cart.qty,
            salePrice: cart.price,
            lineTotal: cart.subtotal,
          ));

          // Update product stock if tracking is enabled
          if (product.trackStock) {
            final newQty = product.qty - cart.qty;
            
            await _productsDao.updateProduct(product.copyWith(qty: newQty));

            // Record stock movement
            await _stockMovementsDao.recordMovement(StockMovementsCompanion.insert(
              productId: product.id,
              movementType: 'SALE',
              quantity: -cart.qty,
              movementDate: DateTime.now(),
              reason: Value('Sale #$saleId'),
              referenceId: Value(saleId.toString()),
            ));
          }

          // Collect items for receipt
          saleItems.add(SaleItem(
            id: 0, // Will be set by database
            saleId: saleId,
            productId: cart.productId,
            productName: cart.productName,
            qty: cart.qty,
            salePrice: cart.price,
            lineTotal: cart.subtotal,
          ));
          
          products.add(product);
        }

        // Clear the cart
        await _cartDao.clearCart(sessionId);

        // Print receipt if requested
        if (printReceipt) {
          try {
            await ReceiptPrintingService.printReceipt(
              sale,
              saleItems,
              products,
              businessName: businessName,
              businessAddress: businessAddress,
              businessPhone: businessPhone,
            );
          } catch (e) {
            // Don't fail the sale if receipt printing fails
            print('Receipt printing failed: $e');
          }
        }

        return SaleCompletionResult(
          success: true,
          sale: sale,
          saleItems: saleItems,
          message: 'Sale completed successfully',
          receiptGenerated: printReceipt,
        );
      });
    } catch (e) {
      return SaleCompletionResult(
        success: false,
        message: 'Sale failed: $e',
        receiptGenerated: false,
      );
    }
  }

  /// Process a quick cash sale (bypassing cart)
  Future<SaleCompletionResult> processQuickCashSale({
    required List<QuickSaleItem> items,
    required double amountPaid,
    double discountAmount = 0.0,
    double taxRate = 0.0,
    String? customerId,
    String? notes,
    bool printReceipt = true,
  }) async {
    try {
      // Calculate totals
      final subtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      final taxAmount = subtotal * taxRate;
      final total = subtotal + taxAmount - discountAmount;

      if (amountPaid < total) {
        throw Exception('Insufficient payment amount');
      }

      final changeAmount = amountPaid - total;

      return await _database.transaction(() async {
        // Create sale record
        final saleId = await _salesDao.createSale(SalesCompanion.insert(
          saleDate: DateTime.now(),
          subtotal: subtotal,
          taxAmount: taxAmount,
          discountAmount: discountAmount,
          total: total,
          paymentMethod: 'CASH',
          amountPaid: amountPaid,
          changeAmount: changeAmount,
          customerId: Value(customerId),
          notes: Value(notes),
        ));

        final sale = await _salesDao.getSaleById(saleId);
        final saleItems = <SaleItem>[];
        final products = <Product>[];

        // Process each item
        for (final item in items) {
          // Get product details
          final product = await _productsDao.getProductById(item.productId);
          if (product == null) {
            throw Exception('Product not found: ${item.productId}');
          }

          // Create sale item
          await _salesDao.addSaleItem(SaleItemsCompanion.insert(
            saleId: saleId,
            productId: item.productId,
            productName: product.name,
            qty: item.quantity,
            salePrice: item.price,
            lineTotal: item.price * item.quantity,
          ));

          // Update stock
          if (product.trackStock) {
            final newQty = product.qty - item.quantity;
            await _productsDao.updateProduct(product.copyWith(qty: newQty));

            // Record stock movement
            await _stockMovementsDao.recordMovement(StockMovementsCompanion.insert(
              productId: product.id,
              movementType: 'SALE',
              quantity: -item.quantity,
              movementDate: DateTime.now(),
              reason: Value('Quick Sale #$saleId'),
              referenceId: Value(saleId.toString()),
            ));
          }

          saleItems.add(SaleItem(
            id: 0,
            saleId: saleId,
            productId: item.productId,
            productName: product.name,
            qty: item.quantity,
            salePrice: item.price,
            lineTotal: item.price * item.quantity,
          ));
          
          products.add(product);
        }

        // Print receipt if requested
        if (printReceipt) {
          try {
            await ReceiptPrintingService.printReceipt(sale, saleItems, products);
          } catch (e) {
            print('Receipt printing failed: $e');
          }
        }

        return SaleCompletionResult(
          success: true,
          sale: sale,
          saleItems: saleItems,
          message: 'Quick sale completed successfully',
          receiptGenerated: printReceipt,
        );
      });
    } catch (e) {
      return SaleCompletionResult(
        success: false,
        message: 'Quick sale failed: $e',
        receiptGenerated: false,
      );
    }
  }

  /// Process a return/refund
  Future<SaleCompletionResult> processReturn({
    required int originalSaleId,
    required List<ReturnItem> returnItems,
    required String reason,
    String? notes,
    bool printReceipt = true,
  }) async {
    try {
      // Get original sale
      final originalSale = await _salesDao.getSaleById(originalSaleId);
      final originalItems = await _salesDao.getSaleItems(originalSaleId);

      // Validate return items
      for (final returnItem in returnItems) {
        final originalItem = originalItems.firstWhere(
          (item) => item.productId == returnItem.productId,
          orElse: () => throw Exception('Product not found in original sale'),
        );
        
        if (returnItem.quantity > originalItem.qty) {
          throw Exception('Return quantity exceeds original quantity for ${originalItem.productName}');
        }
      }

      // Calculate return totals
      final returnSubtotal = returnItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      final returnTaxAmount = returnSubtotal * (originalSale.taxAmount / originalSale.subtotal);
      final returnTotal = returnSubtotal + returnTaxAmount;

      return await _database.transaction(() async {
        // Create return sale record (negative amounts)
        final returnSaleId = await _salesDao.createSale(SalesCompanion.insert(
          saleDate: DateTime.now(),
          subtotal: -returnSubtotal,
          taxAmount: -returnTaxAmount,
          discountAmount: 0.0,
          total: -returnTotal,
          paymentMethod: 'RETURN',
          amountPaid: -returnTotal,
          changeAmount: 0.0,
          customerId: Value(originalSale.customerId),
          notes: Value('RETURN: $reason${notes != null ? ' - $notes' : ''}'),
        ));

        final returnSale = await _salesDao.getSaleById(returnSaleId);
        final returnSaleItems = <SaleItem>[];
        final products = <Product>[];

        // Process each return item
        for (final returnItem in returnItems) {
          // Get product details
          final product = await _productsDao.getProductById(returnItem.productId);
          if (product == null) {
            throw Exception('Product not found: ${returnItem.productId}');
          }

          // Create return sale item
          await _salesDao.addSaleItem(SaleItemsCompanion.insert(
            saleId: returnSaleId,
            productId: returnItem.productId,
            productName: product.name,
            qty: -returnItem.quantity, // Negative quantity for return
            salePrice: returnItem.price,
            lineTotal: -(returnItem.price * returnItem.quantity),
          ));

          // Update stock (add back to inventory)
          if (product.trackStock) {
            final newQty = product.qty + returnItem.quantity;
            await _productsDao.updateProduct(product.copyWith(qty: newQty));

            // Record stock movement
            await _stockMovementsDao.recordMovement(StockMovementsCompanion.insert(
              productId: product.id,
              movementType: 'RETURN',
              quantity: returnItem.quantity,
              movementDate: DateTime.now(),
              reason: Value('Return #$returnSaleId - $reason'),
              referenceId: Value(returnSaleId.toString()),
            ));
          }

          returnSaleItems.add(SaleItem(
            id: 0,
            saleId: returnSaleId,
            productId: returnItem.productId,
            productName: product.name,
            qty: -returnItem.quantity,
            salePrice: returnItem.price,
            lineTotal: -(returnItem.price * returnItem.quantity),
          ));
          
          products.add(product);
        }

        // Print return receipt if requested
        if (printReceipt) {
          try {
            await ReceiptPrintingService.printReceipt(returnSale, returnSaleItems, products);
          } catch (e) {
            print('Return receipt printing failed: $e');
          }
        }

        return SaleCompletionResult(
          success: true,
          sale: returnSale,
          saleItems: returnSaleItems,
          message: 'Return processed successfully. Refund amount: \$${returnTotal.toStringAsFixed(2)}',
          receiptGenerated: printReceipt,
        );
      });
    } catch (e) {
      return SaleCompletionResult(
        success: false,
        message: 'Return failed: $e',
        receiptGenerated: false,
      );
    }
  }

  /// Void a sale (only if recent and conditions met)
  Future<bool> voidSale(int saleId, String reason) async {
    try {
      final sale = await _salesDao.getSaleById(saleId);
      final saleItems = await _salesDao.getSaleItems(saleId);

      // Check if sale can be voided (within time limit, no returns processed, etc.)
      final timeDifference = DateTime.now().difference(sale.saleDate);
      if (timeDifference.inHours > 24) {
        throw Exception('Cannot void sales older than 24 hours');
      }

      return await _database.transaction(() async {
        // Restore inventory for each item
        for (final item in saleItems) {
          final product = await _productsDao.getProductById(item.productId);
          if (product != null && product.trackStock) {
            final newQty = product.qty + item.qty;
            await _productsDao.updateProduct(product.copyWith(qty: newQty));

            // Record stock movement
            await _stockMovementsDao.recordMovement(StockMovementsCompanion.insert(
              productId: product.id,
              movementType: 'VOID',
              quantity: item.qty,
              movementDate: DateTime.now(),
              reason: Value('Voided Sale #$saleId - $reason'),
              referenceId: Value(saleId.toString()),
            ));
          }
        }

        // Mark sale as voided
        await _salesDao.voidSale(saleId, reason);
        
        return true;
      });
    } catch (e) {
      print('Void sale failed: $e');
      return false;
    }
  }
}

// Helper classes
class SaleCompletionResult {
  final bool success;
  final Sale? sale;
  final List<SaleItem>? saleItems;
  final String message;
  final bool receiptGenerated;

  SaleCompletionResult({
    required this.success,
    this.sale,
    this.saleItems,
    required this.message,
    required this.receiptGenerated,
  });
}

class QuickSaleItem {
  final String productId;
  final int quantity;
  final double price;

  QuickSaleItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });
}

class ReturnItem {
  final String productId;
  final int quantity;
  final double price;

  ReturnItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });
}
