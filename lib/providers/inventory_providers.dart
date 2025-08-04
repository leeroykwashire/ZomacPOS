import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/stock_movements_dao.dart';
import '../providers/database_providers.dart';

// Inventory statistics provider
final inventoryStatsProvider = FutureProvider<InventoryStats>((ref) async {
  final database = ref.watch(databaseProvider);
  final productsDao = database.productsDao;
  
  final totalProducts = await productsDao.getTotalProductsCount();
  final lowStockProducts = await productsDao.getLowStockProducts();
  final outOfStockProducts = await productsDao.getOutOfStockProducts();
  final allProducts = await productsDao.getAllProducts();
  
  // Calculate total inventory value
  double totalValue = 0;
  for (final product in allProducts) {
    if (product.cost != null) {
      totalValue += (product.cost! * product.qty);
    } else {
      totalValue += (product.price * 0.7 * product.qty); // Assume 70% of price as cost
    }
  }
  
  return InventoryStats(
    totalProducts: totalProducts,
    lowStockCount: lowStockProducts.length,
    outOfStockCount: outOfStockProducts.length,
    totalInventoryValue: totalValue,
    averageStockLevel: allProducts.isEmpty ? 0 : allProducts.map((p) => p.qty).reduce((a, b) => a + b) / allProducts.length,
  );
});

// Low stock products provider
final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.productsDao.getLowStockProducts();
});

// Filtered inventory products provider
final filteredInventoryProductsProvider = FutureProvider.family<List<Product>, InventoryFilter>((ref, filter) async {
  final database = ref.watch(databaseProvider);
  final productsDao = database.productsDao;
  
  List<Product> products;
  
  // Apply filter type
  switch (filter.filterType) {
    case 'low_stock':
      products = await productsDao.getLowStockProducts();
      break;
    case 'out_of_stock':
      products = await productsDao.getOutOfStockProducts();
      break;
    case 'active':
      products = await productsDao.getActiveProducts();
      break;
    case 'inactive':
      final allProducts = await productsDao.getAllProducts();
      products = allProducts.where((p) => !p.isActive).toList();
      break;
    default:
      products = await productsDao.getAllProducts();
  }
  
  // Apply search filter
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    products = products.where((product) {
      return product.name.toLowerCase().contains(query) ||
             (product.sku?.toLowerCase().contains(query) ?? false) ||
             (product.barcode?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
  
  return products;
});

// Stock movements provider
final stockMovementsProvider = FutureProvider<List<StockMovementWithProduct>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.stockMovementsDao.getMovementsWithProducts(limit: 50);
});

// Product movements provider for specific product  
final productMovementsProvider = FutureProvider.family<List<StockMovementWithProduct>, String>((ref, productId) async {
  final database = ref.watch(databaseProvider);
  return database.stockMovementsDao.getProductMovementsWithDetails(productId);
});

// Inventory service provider
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService(ref);
});

// Data classes
class InventoryStats {
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalInventoryValue;
  final double averageStockLevel;

  InventoryStats({
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalInventoryValue,
    required this.averageStockLevel,
  });
}

class InventoryFilter {
  final String searchQuery;
  final String filterType;

  InventoryFilter({
    required this.searchQuery,
    required this.filterType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryFilter &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          filterType == other.filterType;

  @override
  int get hashCode => searchQuery.hashCode ^ filterType.hashCode;
}

// Stock movement types
enum StockMovementType {
  sale,
  purchase,
  adjustment,
  transfer,
  damage,
  expired,
  returned,
  stockTake,
}

// Stock movement reasons
enum StockMovementReason {
  sale,
  purchase,
  manualAdjustment,
  damage,
  expired,
  theft,
  stockTake,
  transfer,
  return_,
  promotion,
  other,
}

// Inventory service for business logic
class InventoryService {
  final Ref _ref;

  InventoryService(this._ref);

  // Adjust stock with movement tracking
  Future<void> adjustStock({
    required String productId,
    required int quantityChange,
    required StockMovementReason reason,
    String? notes,
    String? reference,
  }) async {
    final database = _ref.read(databaseProvider);
    final productsDao = database.productsDao;
    final stockMovementsDao = database.stockMovementsDao;

    // Get current product
    final product = await productsDao.getProductById(productId);
    if (product == null) throw Exception('Product not found');

    // Get default company ID
    final companyId = await database.getDefaultCompanyId();
    if (companyId == null) throw Exception('No default company found. Please initialize the database.');

    // Calculate new quantity
    final newQuantity = product.qty + quantityChange;
    if (newQuantity < 0) throw Exception('Insufficient stock');

    // Update product stock
    await productsDao.updateStock(productId, newQuantity);

    // Record stock movement
    await stockMovementsDao.createMovement(
      productId: productId,
      actionId: reason.name, // Use reason as action ID
      companyId: companyId,
      initialQty: product.qty,
      finalQty: newQuantity,
      notes: notes,
    );
  }

  // Bulk stock adjustment
  Future<void> bulkAdjustStock(List<StockAdjustment> adjustments) async {
    for (final adjustment in adjustments) {
      await adjustStock(
        productId: adjustment.productId,
        quantityChange: adjustment.quantityChange,
        reason: adjustment.reason,
        notes: adjustment.notes,
        reference: adjustment.reference,
      );
    }
  }

  // Auto-generate reorder suggestions
  Future<List<ReorderSuggestion>> getReorderSuggestions() async {
    final database = _ref.read(databaseProvider);
    final lowStockProducts = await database.productsDao.getLowStockProducts();
    
    List<ReorderSuggestion> suggestions = [];
    
    for (final product in lowStockProducts) {
      // Calculate suggested order quantity (simple algorithm)
      final shortage = product.minQty - product.qty;
      final bufferStock = (product.minQty * 0.5).round(); // 50% buffer
      final suggestedQuantity = shortage + bufferStock;
      
      suggestions.add(ReorderSuggestion(
        product: product,
        currentStock: product.qty,
        minimumStock: product.minQty,
        shortage: shortage,
        suggestedOrderQuantity: suggestedQuantity,
        estimatedCost: (product.cost ?? product.price * 0.7) * suggestedQuantity,
      ));
    }
    
    return suggestions;
  }
}

// Helper classes
class StockAdjustment {
  final String productId;
  final int quantityChange;
  final StockMovementReason reason;
  final String? notes;
  final String? reference;

  StockAdjustment({
    required this.productId,
    required this.quantityChange,
    required this.reason,
    this.notes,
    this.reference,
  });
}

class ReorderSuggestion {
  final Product product;
  final int currentStock;
  final int minimumStock;
  final int shortage;
  final int suggestedOrderQuantity;
  final double estimatedCost;

  ReorderSuggestion({
    required this.product,
    required this.currentStock,
    required this.minimumStock,
    required this.shortage,
    required this.suggestedOrderQuantity,
    required this.estimatedCost,
  });
}
