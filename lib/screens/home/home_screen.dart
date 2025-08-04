import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/widgets.dart';
import '../products/products_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(currentUserProvider);
    final userNotifier = ref.read(currentUserProvider.notifier);
    
    // Check user role for content filtering
    final isAdmin = userNotifier.isAdmin;
    final isManager = userNotifier.isManager;
    final canViewFinancials = isAdmin || isManager;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: colorScheme.surface,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: Container(
                  padding: AppConstants.defaultPadding,
                  child: Row(
                    children: [
                      // Welcome section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getGreeting(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              currentUser?['firstName'] ?? 'User',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action buttons
                      IconButton(
                        onPressed: () => _showNotifications(context),
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showUserMenu(context),
                        icon: CircleAvatar(
                          radius: 16,
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            (currentUser?['firstName'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main content
              SliverPadding(
                padding: AppConstants.defaultPadding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Metrics Section
                    if (canViewFinancials) ...[
                      Text(
                        'Today\'s Overview',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAdminMetrics(),
                      const SizedBox(height: 24),
                    ] else ...[
                      Text(
                        'Your Dashboard',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCashierMetrics(),
                      const SizedBox(height: 24),
                    ],

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(canViewFinancials),
                    const SizedBox(height: 24),

                    // Recent Activity (visible to all)
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentActivity(),
                    const SizedBox(height: 100), // Bottom padding
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Floating Action Button for quick sale
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewSale(),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Sale'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  // Build metrics for admin/manager users
  Widget _buildAdminMetrics() {
    final todayMetrics = ref.watch(todayMetricsProvider);
    final weeklyMetrics = ref.watch(weeklyMetricsProvider);

    return todayMetrics.when(
      loading: () => _buildLoadingMetrics(),
      error: (error, stack) => _buildErrorMetrics(error),
      data: (metrics) => Column(
        children: [
          // Top row - Revenue and Transactions
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Today\'s Revenue',
                  value: '\$${metrics.todayRevenue.toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                  trend: '${metrics.revenueChange >= 0 ? '+' : ''}${metrics.revenueChange.toStringAsFixed(1)}%',
                  isPositiveTrend: metrics.revenueChange >= 0,
                  onTap: () => _showRevenueDetails(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Transactions',
                  value: '${metrics.todayTransactions}',
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                  trend: '${metrics.transactionChange >= 0 ? '+' : ''}${metrics.transactionChange.toStringAsFixed(1)}%',
                  isPositiveTrend: metrics.transactionChange >= 0,
                  onTap: () => _showTransactionDetails(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Bottom row - Stock and Cart
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Low Stock Items',
                  value: '${metrics.lowStockCount}',
                  subtitle: 'Need attention',
                  icon: Icons.inventory_2_outlined,
                  color: metrics.lowStockCount > 0 ? Colors.orange : Colors.green,
                  onTap: () => _showLowStockItems(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Active Cart',
                  value: '${metrics.activeCartItems}',
                  subtitle: 'Items in cart',
                  icon: Icons.shopping_cart_outlined,
                  color: Colors.purple,
                  onTap: () => _showActiveCart(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build metrics for cashier users (non-financial)
  Widget _buildCashierMetrics() {
    final cashierStats = ref.watch(cashierStatsProvider);

    return cashierStats.when(
      loading: () => _buildLoadingMetrics(),
      error: (error, stack) => _buildErrorMetrics(error),
      data: (stats) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'My Transactions',
                  value: '${stats.myTransactionsToday}',
                  subtitle: 'Today',
                  icon: Icons.person_outline,
                  color: Colors.blue,
                  onTap: () => _showMyTransactions(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Stock Alerts',
                  value: '${stats.lowStockAlerts}',
                  subtitle: 'Need attention',
                  icon: Icons.warning_outlined,
                  color: stats.lowStockAlerts > 0 ? Colors.orange : Colors.green,
                  onTap: () => _showStockAlerts(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Products',
                  value: '${stats.totalProductsManaged}',
                  subtitle: 'In inventory',
                  icon: Icons.inventory_outlined,
                  color: Colors.green,
                  onTap: () => _showProducts(),
                ),
              ),
              const SizedBox(width: 16),
              // Placeholder for balance
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool canViewFinancials) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        QuickActionButton(
          label: 'New Sale',
          icon: Icons.add_shopping_cart,
          onTap: () => _startNewSale(),
          color: Colors.green,
        ),
        QuickActionButton(
          label: 'Products',
          icon: Icons.inventory_2,
          onTap: () => _navigateToProducts(),
          color: Colors.blue,
        ),
        QuickActionButton(
          label: 'Sales History',
          icon: Icons.receipt_long,
          onTap: () => _viewAllSales(),
          color: Colors.teal,
        ),
        if (canViewFinancials) ...[
          QuickActionButton(
            label: 'Reports',
            icon: Icons.analytics,
            onTap: () => _navigateToReports(),
            color: Colors.purple,
          ),
          QuickActionButton(
            label: 'Settings',
            icon: Icons.settings,
            onTap: () => _navigateToSettings(),
            color: Colors.grey,
          ),
        ] else ...[
          QuickActionButton(
            label: 'Scan Item',
            icon: Icons.qr_code_scanner,
            onTap: () => _scanBarcode(),
            color: Colors.orange,
          ),
          QuickActionButton(
            label: 'Search',
            icon: Icons.search,
            onTap: () => _searchProducts(),
            color: Colors.teal,
          ),
        ],
      ],
    );
  }

  Widget _buildRecentActivity() {
    final todayMetrics = ref.watch(todayMetricsProvider);
    
    return todayMetrics.when(
      loading: () => const RecentActivityCard(
        recentSales: [],
        isLoading: true,
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        child: Text('Error loading activity: $error'),
      ),
      data: (metrics) => RecentActivityCard(
        recentSales: metrics.recentSales,
        onViewAll: () => _viewAllSales(),
      ),
    );
  }

  Widget _buildLoadingMetrics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Loading...',
                value: '',
                icon: Icons.trending_up,
                isLoading: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: 'Loading...',
                value: '',
                icon: Icons.receipt_long,
                isLoading: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMetrics(Object error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading dashboard data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Navigation methods
  void _startNewSale() {
    // TODO: Navigate to POS screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('POS screen coming soon!')),
    );
  }

  void _navigateToProducts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductsScreen(),
      ),
    );
  }

  void _navigateToReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports screen coming soon!')),
    );
  }

  void _navigateToSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings screen coming soon!')),
    );
  }

  void _scanBarcode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barcode scanner coming soon!')),
    );
  }

  void _searchProducts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product search coming soon!')),
    );
  }

  void _viewAllSales() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SalesHistoryScreen(),
      ),
    );
  }

  // Detail view methods
  void _showRevenueDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Revenue details coming soon!')),
    );
  }

  void _showTransactionDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction details coming soon!')),
    );
  }

  void _showLowStockItems() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Low stock items coming soon!')),
    );
  }

  void _showActiveCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Active cart coming soon!')),
    );
  }

  void _showMyTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('My transactions coming soon!')),
    );
  }

  void _showStockAlerts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stock alerts coming soon!')),
    );
  }

  void _showProducts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Products screen coming soon!')),
    );
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications coming soon!')),
    );
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _navigateToSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                ref.read(currentUserProvider.notifier).logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
