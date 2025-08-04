import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_providers.dart';

// Sales filter class
class SalesFilter {
  final String? searchQuery;
  final String? status;
  final String? paymentMethod;
  final SalesDateTimeRange? dateRange;
  final String? cashierId;

  SalesFilter({
    this.searchQuery,
    this.status,
    this.paymentMethod,
    this.dateRange,
    this.cashierId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalesFilter &&
        other.searchQuery == searchQuery &&
        other.status == status &&
        other.paymentMethod == paymentMethod &&
        other.dateRange == dateRange &&
        other.cashierId == cashierId;
  }

  @override
  int get hashCode {
    return Object.hash(
      searchQuery,
      status,
      paymentMethod,
      dateRange,
      cashierId,
    );
  }
}

// Sales stats filter
class SalesStatsFilter {
  final SalesDateTimeRange? dateRange;
  final String? cashierId;

  SalesStatsFilter({
    this.dateRange,
    this.cashierId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalesStatsFilter &&
        other.dateRange == dateRange &&
        other.cashierId == cashierId;
  }

  @override
  int get hashCode {
    return Object.hash(dateRange, cashierId);
  }
}

// Sales stats class
class SalesStats {
  final double totalAmount;
  final int transactionCount;
  final double averageAmount;
  final double dailyGrowth;
  final Map<String, int> statusBreakdown;
  final Map<String, double> paymentMethodBreakdown;

  SalesStats({
    required this.totalAmount,
    required this.transactionCount,
    required this.averageAmount,
    required this.dailyGrowth,
    required this.statusBreakdown,
    required this.paymentMethodBreakdown,
  });
}

// SalesDateTimeRange extension for date ranges
extension SalesDateTimeRangeExtension on DateTime {
  static SalesDateTimeRange today() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return SalesDateTimeRange(
      start: today,
      end: today.add(const Duration(days: 1)),
    );
  }

  static SalesDateTimeRange thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return SalesDateTimeRange(
      start: startOfWeekDate,
      end: startOfWeekDate.add(const Duration(days: 7)),
    );
  }

  static SalesDateTimeRange thisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return SalesDateTimeRange(
      start: startOfMonth,
      end: endOfMonth,
    );
  }
}

// Provider for all sales
final salesProvider = FutureProvider<List<Sale>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.salesDao.getAllSales();
});

// Provider for filtered sales
final filteredSalesProvider = FutureProvider.family<List<Sale>, SalesFilter>((ref, filter) async {
  final database = ref.watch(databaseProvider);
  final dao = database.salesDao;

  List<Sale> sales;

  // Apply date range filter
  if (filter.dateRange != null) {
    sales = await dao.getSalesByDateRange(filter.dateRange!.start, filter.dateRange!.end);
  } else {
    sales = await dao.getAllSales();
  }

  // Apply cashier filter
  if (filter.cashierId != null) {
    sales = sales.where((sale) => sale.cashierId == filter.cashierId).toList();
  }

  // Apply status filter
  if (filter.status != null) {
    sales = sales.where((sale) => sale.status == filter.status).toList();
  }

  // Apply payment method filter
  if (filter.paymentMethod != null) {
    sales = sales.where((sale) => sale.paymentMethod == filter.paymentMethod).toList();
  }

  // Apply search query filter
  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    final query = filter.searchQuery!.toLowerCase();
    sales = sales.where((sale) {
      return sale.receiptNumber.toLowerCase().contains(query) ||
             sale.notes?.toLowerCase().contains(query) == true;
    }).toList();
  }

  // Sort by date (newest first)
  sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));

  return sales;
});

// Provider for sales statistics
final salesStatsProvider = FutureProvider.family<SalesStats, SalesStatsFilter>((ref, filter) async {
  final database = ref.watch(databaseProvider);
  final dao = database.salesDao;

  List<Sale> sales;

  // Get sales based on filters
  if (filter.dateRange != null) {
    sales = await dao.getSalesByDateRange(filter.dateRange!.start, filter.dateRange!.end);
  } else {
    sales = await dao.getAllSales();
  }

  // Filter by cashier if specified
  if (filter.cashierId != null) {
    sales = sales.where((sale) => sale.cashierId == filter.cashierId).toList();
  }

  // Calculate statistics
  final totalAmount = sales.fold<double>(0, (sum, sale) => sum + sale.total);
  final transactionCount = sales.length;
  final averageAmount = transactionCount > 0 ? totalAmount / transactionCount : 0.0;

  // Calculate daily growth (if date range is set)
  double dailyGrowth = 0.0;
  if (filter.dateRange != null) {
    final daysBetween = filter.dateRange!.end.difference(filter.dateRange!.start).inDays;
    if (daysBetween > 0) {
      // Get previous period for comparison
      final previousStart = filter.dateRange!.start.subtract(Duration(days: daysBetween));
      final previousEnd = filter.dateRange!.start;
      final previousSales = await dao.getSalesByDateRange(previousStart, previousEnd);
      
      if (filter.cashierId != null) {
        previousSales.removeWhere((sale) => sale.cashierId != filter.cashierId);
      }
      
      final previousTotal = previousSales.fold<double>(0, (sum, sale) => sum + sale.total);
      if (previousTotal > 0) {
        dailyGrowth = ((totalAmount - previousTotal) / previousTotal) * 100;
      }
    }
  }

  // Status breakdown
  final statusBreakdown = <String, int>{};
  for (final sale in sales) {
    statusBreakdown[sale.status] = (statusBreakdown[sale.status] ?? 0) + 1;
  }

  // Payment method breakdown
  final paymentMethodBreakdown = <String, double>{};
  for (final sale in sales) {
    paymentMethodBreakdown[sale.paymentMethod] = 
        (paymentMethodBreakdown[sale.paymentMethod] ?? 0.0) + sale.total;
  }

  return SalesStats(
    totalAmount: totalAmount,
    transactionCount: transactionCount,
    averageAmount: averageAmount,
    dailyGrowth: dailyGrowth,
    statusBreakdown: statusBreakdown,
    paymentMethodBreakdown: paymentMethodBreakdown,
  );
});

// Provider for today's sales
final todaysSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.salesDao.getTodaysSales();
});

// Provider for sales by cashier
final salesByCashierProvider = FutureProvider.family<List<Sale>, String>((ref, cashierId) async {
  final database = ref.watch(databaseProvider);
  return database.salesDao.getSalesByCashier(cashierId);
});

// Provider for cashiers list
final cashiersProvider = FutureProvider<List<User>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.usersDao.getCashiers();
});

// Provider for sale details
final saleDetailsProvider = FutureProvider.family<Sale?, String>((ref, saleId) async {
  final database = ref.watch(databaseProvider);
  return database.salesDao.getSaleById(saleId);
});

// Provider for sale items
final saleItemsProvider = FutureProvider.family<List<SalesItem>, String>((ref, saleId) async {
  final database = ref.watch(databaseProvider);
  return database.salesDao.getSaleItems(saleId);
});

// Provider for recent sales (dashboard)
final recentSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final database = ref.watch(databaseProvider);
  final allSales = await database.salesDao.getAllSales();
  
  // Sort by date and take the most recent 10
  allSales.sort((a, b) => b.saleDate.compareTo(a.saleDate));
  return allSales.take(10).toList();
});

// Provider for daily sales summary
final dailySalesSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final database = ref.watch(databaseProvider);
  final todaysSales = await database.salesDao.getTodaysSales();
  
  final totalAmount = todaysSales.fold<double>(0, (sum, sale) => sum + sale.total);
  final transactionCount = todaysSales.length;
  final averageAmount = transactionCount > 0 ? totalAmount / transactionCount : 0.0;
  
  return {
    'totalAmount': totalAmount,
    'transactionCount': transactionCount,
    'averageAmount': averageAmount,
    'sales': todaysSales,
  };
});

// SalesDateTimeRange helper class for Flutter
class SalesDateTimeRange {
  final DateTime start;
  final DateTime end;

  SalesDateTimeRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalesDateTimeRange &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
