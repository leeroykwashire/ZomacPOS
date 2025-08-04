import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/other_tables.dart';
import '../tables/products_table.dart';

part 'stock_movements_dao.g.dart';

// Stock Movements DAO
@DriftAccessor(tables: [StockMovements, Products])
class StockMovementsDao extends DatabaseAccessor<AppDatabase> with _$StockMovementsDaoMixin {
  StockMovementsDao(AppDatabase db) : super(db);

  // Create a new stock movement record
  Future<StockMovement> createMovement({
    required String productId,
    required String actionId,
    required String companyId,
    required int initialQty,
    required int finalQty,
    String? notes,
  }) async {
    final movementId = DateTime.now().microsecondsSinceEpoch.toString();
    
    final companion = StockMovementsCompanion.insert(
      id: movementId,
      productId: productId,
      actionId: actionId,
      companyId: companyId,
      initialQty: initialQty,
      finalQty: finalQty,
      notes: Value(notes),
    );

    return await into(stockMovements).insertReturning(companion);
  }

  // Get all movements for a specific product
  Future<List<StockMovement>> getMovementsByProduct(String productId) =>
    (select(stockMovements)
      ..where((m) => m.productId.equals(productId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();

  // Get all movements for a company
  Future<List<StockMovement>> getMovementsByCompany(String companyId) =>
    (select(stockMovements)
      ..where((m) => m.companyId.equals(companyId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();

  // Get movements within a date range
  Future<List<StockMovement>> getMovementsByDateRange(
    DateTime start,
    DateTime end,
    {String? productId, String? companyId}
  ) {
    final query = select(stockMovements)
      ..where((m) => m.createdAt.isBetweenValues(start, end));
    
    if (productId != null) {
      query.where((m) => m.productId.equals(productId));
    }
    
    if (companyId != null) {
      query.where((m) => m.companyId.equals(companyId));
    }
    
    query.orderBy([(m) => OrderingTerm.desc(m.createdAt)]);
    
    return query.get();
  }

  // Get recent movements (last N records)
  Future<List<StockMovement>> getRecentMovements({int limit = 50, String? companyId}) {
    final query = select(stockMovements);
    
    if (companyId != null) {
      query.where((m) => m.companyId.equals(companyId));
    }
    
    query
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
      ..limit(limit);
    
    return query.get();
  }

  // Get movement statistics for a product
  Future<MovementStats> getMovementStats(String productId, {DateTime? since}) async {
    var query = select(stockMovements)..where((m) => m.productId.equals(productId));
    
    if (since != null) {
      query.where((m) => m.createdAt.isBiggerOrEqualValue(since));
    }
    
    final movements = await query.get();
    
    int totalIncrease = 0;
    int totalDecrease = 0;
    int movementCount = movements.length;
    
    for (final movement in movements) {
      final change = movement.finalQty - movement.initialQty;
      if (change > 0) {
        totalIncrease += change;
      } else {
        totalDecrease += change.abs();
      }
    }
    
    return MovementStats(
      productId: productId,
      totalMovements: movementCount,
      totalIncrease: totalIncrease,
      totalDecrease: totalDecrease,
      netChange: totalIncrease - totalDecrease,
    );
  }

  // Get movements with product information (join)
  Future<List<StockMovementWithProduct>> getMovementsWithProducts({
    String? companyId,
    int limit = 100,
  }) {
    final query = select(stockMovements).join([
      innerJoin(products, products.id.equalsExp(stockMovements.productId))
    ]);
    
    if (companyId != null) {
      query.where(stockMovements.companyId.equals(companyId));
    }
    
    query
      ..orderBy([OrderingTerm.desc(stockMovements.createdAt)])
      ..limit(limit);
    
    return query.map((row) {
      final movement = row.readTable(stockMovements);
      final product = row.readTable(products);
      return StockMovementWithProduct(movement: movement, product: product);
    }).get();
  }

  // Get movements for a specific product with product info
  Future<List<StockMovementWithProduct>> getProductMovementsWithDetails(String productId) {
    final query = select(stockMovements).join([
      innerJoin(products, products.id.equalsExp(stockMovements.productId))
    ]);
    
    query.where(stockMovements.productId.equals(productId));
    query.orderBy([OrderingTerm.desc(stockMovements.createdAt)]);
    
    return query.map((row) {
      final movement = row.readTable(stockMovements);
      final product = row.readTable(products);
      return StockMovementWithProduct(movement: movement, product: product);
    }).get();
  }

  // Delete old movements (for cleanup)
  Future<int> deleteOldMovements(DateTime before) =>
    (delete(stockMovements)..where((m) => m.createdAt.isSmallerThanValue(before))).go();

  // Get total movements count
  Future<int> getTotalMovementsCount({String? companyId}) async {
    final query = selectOnly(stockMovements)..addColumns([stockMovements.id.count()]);
    
    if (companyId != null) {
      query.where(stockMovements.companyId.equals(companyId));
    }
    
    final result = await query.getSingleOrNull();
    return result?.read(stockMovements.id.count()) ?? 0;
  }
}

// Helper classes for movement statistics and joins
class MovementStats {
  final String productId;
  final int totalMovements;
  final int totalIncrease;
  final int totalDecrease;
  final int netChange;

  MovementStats({
    required this.productId,
    required this.totalMovements,
    required this.totalIncrease,
    required this.totalDecrease,
    required this.netChange,
  });
}

class StockMovementWithProduct {
  final StockMovement movement;
  final Product product;

  StockMovementWithProduct({
    required this.movement,
    required this.product,
  });
  
  // Helper properties for UI compatibility
  String get productName => product.name;
  int get quantityChange => movement.finalQty - movement.initialQty;
  int get previousQuantity => movement.initialQty;
  int get newQuantity => movement.finalQty;
  String? get notes => movement.notes;
  DateTime get createdAt => movement.createdAt;
  String get actionId => movement.actionId;
}
