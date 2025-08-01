import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_table.dart';
import '../tables/sales_items_table.dart';
import '../tables/products_table.dart';
import '../tables/users_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [Sales, SalesItems, Products, Users])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(AppDatabase db) : super(db);

  // Get all sales
  Future<List<Sale>> getAllSales() => select(sales).get();

  // Get sales by date range
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) =>
    (select(sales)..where((s) => 
      s.saleDate.isBetweenValues(start, end)))
    .get();

  // Get today's sales
  Future<List<Sale>> getTodaysSales() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getSalesByDateRange(startOfDay, endOfDay);
  }

  // Get sales by cashier
  Future<List<Sale>> getSalesByCashier(String cashierId) =>
    (select(sales)..where((s) => s.cashierId.equals(cashierId))).get();

  // Get sale by ID
  Future<Sale?> getSaleById(String saleId) =>
    (select(sales)..where((s) => s.id.equals(saleId))).getSingleOrNull();

  // Get sale by receipt number
  Future<Sale?> getSaleByReceiptNumber(String receiptNumber) =>
    (select(sales)..where((s) => s.receiptNumber.equals(receiptNumber))).getSingleOrNull();

  // Get sale items for a sale
  Future<List<SalesItem>> getSaleItems(String saleId) =>
    (select(salesItems)..where((si) => si.saleId.equals(saleId))).get();

  // Create a complete sale with items
  Future<String> createSaleWithItems(
    SalesCompanion sale, 
    List<SalesItemsCompanion> items
  ) async {
    return await transaction(() async {
      final createdSale = await into(sales).insertReturning(sale);
      
      // Insert all sale items
      for (final item in items) {
        await into(salesItems).insert(item.copyWith(saleId: Value(createdSale.id)));
      }
      
      return createdSale.id;
    });
  }

  // Update sale status
  Future<void> updateSaleStatus(String saleId, String status) =>
    (update(sales)..where((s) => s.id.equals(saleId)))
      .write(SalesCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ));

  // Get sales summary for a date range
  Future<SalesSummary> getSalesSummary(DateTime start, DateTime end) async {
    final salesInRange = await getSalesByDateRange(start, end);
    
    final totalSales = salesInRange.length;
    final totalRevenue = salesInRange.fold<double>(0, (sum, sale) => sum + sale.total);
    final totalTax = salesInRange.fold<double>(0, (sum, sale) => sum + sale.tax);
    final totalDiscount = salesInRange.fold<double>(0, (sum, sale) => sum + sale.discount);
    
    return SalesSummary(
      totalSales: totalSales,
      totalRevenue: totalRevenue,
      totalTax: totalTax,
      totalDiscount: totalDiscount,
      averageSale: totalSales > 0 ? totalRevenue / totalSales : 0,
    );
  }

  // Get top selling products
  Future<List<TopSellingProduct>> getTopSellingProducts(DateTime start, DateTime end, {int limit = 10}) async {
    final query = selectOnly(salesItems)
      ..addColumns([
        salesItems.productId,
        salesItems.productName,
        salesItems.qty.sum(),
        salesItems.subtotal.sum()
      ])
      ..join([
        innerJoin(sales, sales.id.equalsExp(salesItems.saleId))
      ])
      ..where(sales.saleDate.isBetweenValues(start, end))
      ..groupBy([salesItems.productId, salesItems.productName])
      ..orderBy([OrderingTerm.desc(salesItems.qty.sum())])
      ..limit(limit);

    final result = await query.get();
    
    return result.map((row) => TopSellingProduct(
      productId: row.read(salesItems.productId)!,
      productName: row.read(salesItems.productName)!,
      totalQuantity: row.read(salesItems.qty.sum()) ?? 0,
      totalRevenue: row.read(salesItems.subtotal.sum()) ?? 0.0,
    )).toList();
  }

  // Get sales with cashier info
  Future<List<SaleWithCashier>> getSalesWithCashier() {
    final query = select(sales).join([
      leftOuterJoin(users, users.id.equalsExp(sales.cashierId))
    ]);
    
    return query.map((row) {
      final sale = row.readTable(sales);
      final cashier = row.readTableOrNull(users);
      return SaleWithCashier(sale: sale, cashier: cashier);
    }).get();
  }

  // Void/cancel a sale
  Future<void> voidSale(String saleId, String reason) =>
    (update(sales)..where((s) => s.id.equals(saleId)))
      .write(SalesCompanion(
        status: const Value('cancelled'),
        notes: Value(reason),
        updatedAt: Value(DateTime.now()),
      ));

  // Get sales by company
  Future<List<Sale>> getSalesByCompany(String companyId) =>
    (select(sales)..where((s) => s.companyId.equals(companyId))).get();
}

// Helper classes
class SalesSummary {
  final int totalSales;
  final double totalRevenue;
  final double totalTax;
  final double totalDiscount;
  final double averageSale;

  SalesSummary({
    required this.totalSales,
    required this.totalRevenue,
    required this.totalTax,
    required this.totalDiscount,
    required this.averageSale,
  });
}

class TopSellingProduct {
  final String productId;
  final String productName;
  final int totalQuantity;
  final double totalRevenue;

  TopSellingProduct({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
  });
}

class SaleWithCashier {
  final Sale sale;
  final User? cashier;

  SaleWithCashier({required this.sale, this.cashier});
}
