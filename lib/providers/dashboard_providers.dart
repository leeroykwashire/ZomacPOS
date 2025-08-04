import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_providers.dart';

// Dashboard metrics for today
final todayMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final database = ref.watch(databaseProvider);
  
  // Get today's date range
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  // Get today's sales
  final todaysSales = await database.salesDao.getSalesByDateRange(startOfDay, endOfDay);
  
  // Get yesterday's sales for comparison
  final yesterdayStart = startOfDay.subtract(const Duration(days: 1));
  final yesterdaySales = await database.salesDao.getSalesByDateRange(yesterdayStart, startOfDay);
  
  // Get low stock products
  final lowStockProducts = await database.productsDao.getLowStockProducts();
  
  // Get cart items count (active session)
  final cartItems = await database.cartDao.getCartItemsCount();
  
  // Calculate metrics
  final todayRevenue = todaysSales.fold<double>(0, (sum, sale) => sum + sale.total);
  final yesterdayRevenue = yesterdaySales.fold<double>(0, (sum, sale) => sum + sale.total);
  final revenueChange = yesterdayRevenue > 0 
      ? ((todayRevenue - yesterdayRevenue) / yesterdayRevenue * 100)
      : 0.0;
  
  final todayTransactions = todaysSales.length;
  final yesterdayTransactions = yesterdaySales.length;
  final transactionChange = yesterdayTransactions > 0
      ? ((todayTransactions - yesterdayTransactions) / yesterdayTransactions * 100)
      : 0.0;
  
  return DashboardMetrics(
    todayRevenue: todayRevenue,
    todayTransactions: todayTransactions,
    lowStockCount: lowStockProducts.length,
    activeCartItems: cartItems,
    revenueChange: revenueChange,
    transactionChange: transactionChange,
    recentSales: todaysSales.take(5).toList(),
  );
});

// Weekly metrics for admins
final weeklyMetricsProvider = FutureProvider<WeeklyMetrics>((ref) async {
  final database = ref.watch(databaseProvider);
  
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  
  final weekSales = await database.salesDao.getSalesByDateRange(startOfWeek, endOfWeek);
  final weekRevenue = weekSales.fold<double>(0, (sum, sale) => sum + sale.total);
  
  // Get previous week for comparison
  final prevWeekStart = startOfWeek.subtract(const Duration(days: 7));
  final prevWeekSales = await database.salesDao.getSalesByDateRange(prevWeekStart, startOfWeek);
  final prevWeekRevenue = prevWeekSales.fold<double>(0, (sum, sale) => sum + sale.total);
  
  final weeklyGrowth = prevWeekRevenue > 0
      ? ((weekRevenue - prevWeekRevenue) / prevWeekRevenue * 100)
      : 0.0;
  
  return WeeklyMetrics(
    weekRevenue: weekRevenue,
    weekTransactions: weekSales.length,
    weeklyGrowth: weeklyGrowth,
    averageOrderValue: weekSales.isNotEmpty ? weekRevenue / weekSales.length : 0.0,
  );
});

// Quick stats for cashiers (non-sensitive data)
final cashierStatsProvider = FutureProvider<CashierStats>((ref) async {
  final database = ref.watch(databaseProvider);
  
  // Get current user's sales for today
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  // For now, get all sales (in real implementation, filter by cashier)
  final todaysSales = await database.salesDao.getSalesByDateRange(startOfDay, endOfDay);
  final myTransactions = todaysSales.length; // Would filter by current user
  
  // Get products needing attention (low stock visible to all)
  final lowStockProducts = await database.productsDao.getLowStockProducts();
  
  return CashierStats(
    myTransactionsToday: myTransactions,
    lowStockAlerts: lowStockProducts.length,
    totalProductsManaged: await database.productsDao.getAllProducts().then((p) => p.length),
  );
});

// Data classes
class DashboardMetrics {
  final double todayRevenue;
  final int todayTransactions;
  final int lowStockCount;
  final int activeCartItems;
  final double revenueChange;
  final double transactionChange;
  final List<Sale> recentSales;

  DashboardMetrics({
    required this.todayRevenue,
    required this.todayTransactions,
    required this.lowStockCount,
    required this.activeCartItems,
    required this.revenueChange,
    required this.transactionChange,
    required this.recentSales,
  });
}

class WeeklyMetrics {
  final double weekRevenue;
  final int weekTransactions;
  final double weeklyGrowth;
  final double averageOrderValue;

  WeeklyMetrics({
    required this.weekRevenue,
    required this.weekTransactions,
    required this.weeklyGrowth,
    required this.averageOrderValue,
  });
}

class CashierStats {
  final int myTransactionsToday;
  final int lowStockAlerts;
  final int totalProductsManaged;

  CashierStats({
    required this.myTransactionsToday,
    required this.lowStockAlerts,
    required this.totalProductsManaged,
  });
}
