import 'package:flutter/services.dart';
import '../database/app_database.dart';
import '../database/daos/products_dao.dart';
import '../database/daos/cart_dao.dart';

class BarcodeScanningService {
  final ProductsDao _productsDao;
  final CartDao _cartDao;

  BarcodeScanningService(this._productsDao, this._cartDao);

  /// Scan barcode and add product to cart
  Future<ScanResult> scanAndAddToCart({
    required String sessionId,
    required String barcode,
    int quantity = 1,
    bool playSound = true,
  }) async {
    try {
      // Find product by barcode
      final product = await findProductByBarcode(barcode);
      
      if (product == null) {
        if (playSound) _playErrorSound();
        return ScanResult(
          success: false,
          message: 'Product not found for barcode: $barcode',
          barcode: barcode,
        );
      }

      // Check stock availability
      if (product.trackStock && product.qty < quantity) {
        if (playSound) _playErrorSound();
        return ScanResult(
          success: false,
          message: 'Insufficient stock. Available: ${product.qty}',
          barcode: barcode,
          product: product,
        );
      }

      // Add to cart
      await _cartDao.addToCart(
        sessionId,
        product.id,
        product.name,
        quantity,
        product.price,
      );

      if (playSound) _playSuccessSound();
      return ScanResult(
        success: true,
        message: '${product.name} added to cart',
        barcode: barcode,
        product: product,
        quantityAdded: quantity,
      );
    } catch (e) {
      if (playSound) _playErrorSound();
      return ScanResult(
        success: false,
        message: 'Scan error: $e',
        barcode: barcode,
      );
    }
  }

  /// Find product by barcode, SKU, or ID
  Future<Product?> findProductByBarcode(String code) async {
    // Try barcode first
    var product = await _productsDao.getProductByBarcode(code);
    if (product != null) return product;

    // Try SKU
    product = await _productsDao.getProductBySku(code);
    if (product != null) return product;

    // Try ID as fallback
    try {
      product = await _productsDao.getProductById(code);
      if (product != null) return product;
    } catch (e) {
      // ID lookup failed, continue
    }

    return null;
  }

  /// Scan barcode for inventory lookup
  Future<ProductLookupResult> scanForProductLookup(String barcode) async {
    try {
      final product = await findProductByBarcode(barcode);
      
      if (product == null) {
        return ProductLookupResult(
          success: false,
          message: 'Product not found for barcode: $barcode',
          barcode: barcode,
        );
      }

      return ProductLookupResult(
        success: true,
        message: 'Product found',
        barcode: barcode,
        product: product,
      );
    } catch (e) {
      return ProductLookupResult(
        success: false,
        message: 'Lookup error: $e',
        barcode: barcode,
      );
    }
  }

  /// Scan barcode for price verification
  Future<PriceVerificationResult> scanForPriceVerification(String barcode) async {
    try {
      final product = await findProductByBarcode(barcode);
      
      if (product == null) {
        return PriceVerificationResult(
          success: false,
          message: 'Product not found',
          barcode: barcode,
        );
      }

      return PriceVerificationResult(
        success: true,
        message: 'Price verified',
        barcode: barcode,
        product: product,
        currentPrice: product.price,
      );
    } catch (e) {
      return PriceVerificationResult(
        success: false,
        message: 'Verification error: $e',
        barcode: barcode,
      );
    }
  }

  /// Scan multiple items quickly (for inventory counting)
  Future<List<InventoryCountItem>> scanMultipleForInventoryCount(
    List<String> barcodes,
  ) async {
    final results = <InventoryCountItem>[];
    
    for (final barcode in barcodes) {
      try {
        final product = await findProductByBarcode(barcode);
        
        if (product != null) {
          // Check if we already have this product in results
          final existingIndex = results.indexWhere(
            (item) => item.productId == product.id,
          );
          
          if (existingIndex >= 0) {
            // Increment count
            results[existingIndex] = results[existingIndex].copyWith(
              scannedCount: results[existingIndex].scannedCount + 1,
            );
          } else {
            // Add new item
            results.add(InventoryCountItem(
              productId: product.id,
              productName: product.name,
              barcode: barcode,
              currentStock: product.qty,
              scannedCount: 1,
              product: product,
            ));
          }
        } else {
          // Add unknown barcode
          results.add(InventoryCountItem(
            productId: '',
            productName: 'Unknown Product',
            barcode: barcode,
            currentStock: 0,
            scannedCount: 1,
            product: null,
          ));
        }
      } catch (e) {
        print('Error scanning barcode $barcode: $e');
      }
    }
    
    return results;
  }

  /// Validate barcode format
  bool isValidBarcode(String barcode) {
    if (barcode.isEmpty) return false;
    
    // Check for common barcode formats
    final patterns = [
      RegExp(r'^\d{12,13}$'), // EAN-13, UPC-A
      RegExp(r'^[A-Z0-9\-_]{6,20}$'), // Code128, Code39
      RegExp(r'^[0-9A-Z\-\.]{1,20}$'), // SKU format
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(barcode));
  }

  /// Generate scan report
  Future<ScanReport> generateScanReport(List<String> scannedBarcodes) async {
    final validScans = <String>[];
    final invalidScans = <String>[];
    final products = <Product>[];
    
    for (final barcode in scannedBarcodes) {
      final product = await findProductByBarcode(barcode);
      if (product != null) {
        validScans.add(barcode);
        products.add(product);
      } else {
        invalidScans.add(barcode);
      }
    }
    
    return ScanReport(
      totalScans: scannedBarcodes.length,
      validScans: validScans.length,
      invalidScans: invalidScans.length,
      validBarcodes: validScans,
      invalidBarcodes: invalidScans,
      products: products,
    );
  }

  /// Play success sound
  void _playSuccessSound() {
    try {
      HapticFeedback.lightImpact(); // Use haptic feedback instead
    } catch (e) {
      print('Could not play success sound: $e');
    }
  }

  /// Play error sound
  void _playErrorSound() {
    try {
      HapticFeedback.heavyImpact(); // Use haptic feedback instead
    } catch (e) {
      print('Could not play error sound: $e');
    }
  }
}

// Result classes
class ScanResult {
  final bool success;
  final String message;
  final String barcode;
  final Product? product;
  final int? quantityAdded;

  ScanResult({
    required this.success,
    required this.message,
    required this.barcode,
    this.product,
    this.quantityAdded,
  });
}

class ProductLookupResult {
  final bool success;
  final String message;
  final String barcode;
  final Product? product;

  ProductLookupResult({
    required this.success,
    required this.message,
    required this.barcode,
    this.product,
  });
}

class PriceVerificationResult {
  final bool success;
  final String message;
  final String barcode;
  final Product? product;
  final double? currentPrice;

  PriceVerificationResult({
    required this.success,
    required this.message,
    required this.barcode,
    this.product,
    this.currentPrice,
  });
}

class InventoryCountItem {
  final String productId;
  final String productName;
  final String barcode;
  final int currentStock;
  final int scannedCount;
  final Product? product;

  InventoryCountItem({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.currentStock,
    required this.scannedCount,
    this.product,
  });

  InventoryCountItem copyWith({
    String? productId,
    String? productName,
    String? barcode,
    int? currentStock,
    int? scannedCount,
    Product? product,
  }) {
    return InventoryCountItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      currentStock: currentStock ?? this.currentStock,
      scannedCount: scannedCount ?? this.scannedCount,
      product: product ?? this.product,
    );
  }
}

class ScanReport {
  final int totalScans;
  final int validScans;
  final int invalidScans;
  final List<String> validBarcodes;
  final List<String> invalidBarcodes;
  final List<Product> products;

  ScanReport({
    required this.totalScans,
    required this.validScans,
    required this.invalidScans,
    required this.validBarcodes,
    required this.invalidBarcodes,
    required this.products,
  });

  double get successRate => totalScans > 0 ? (validScans / totalScans) * 100 : 0;
}
