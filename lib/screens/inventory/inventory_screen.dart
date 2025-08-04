import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../database/app_database.dart';
import '../../providers/database_providers.dart';
import '../../providers/inventory_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/inventory/inventory_widgets.dart';
import '../../widgets/barcode/barcode_action_buttons.dart';
import '../../widgets/barcode/barcode_print_dialogs.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  String _selectedFilter = 'all';
  List<Product> _selectedProducts = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventoryStats = ref.watch(inventoryStatsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Inventory Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.warning), text: 'Low Stock'),
            Tab(icon: Icon(Icons.inventory), text: 'Stock Take'),
            Tab(icon: Icon(Icons.history), text: 'Movements'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showBarcodeScanner,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
          ),
          IconButton(
            onPressed: _showBulkBarcodeMenu,
            icon: const Icon(Icons.print),
            tooltip: 'Print Barcodes',
          ),
          IconButton(
            onPressed: _showQuickStockAdjustment,
            icon: const Icon(Icons.edit),
            tooltip: 'Quick Adjustment',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview Card
          Container(
            margin: const EdgeInsets.all(16),
            child: inventoryStats.when(
              data: (stats) => _buildStatsCard(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading stats: $error'),
              ),
            ),
          ),

          // Search and Filter Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products, SKU, or barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _refreshProducts();
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => _refreshProducts(),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  initialValue: _selectedFilter,
                  onSelected: (value) {
                    setState(() => _selectedFilter = value);
                    _refreshProducts();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('All Products')),
                    const PopupMenuItem(value: 'low_stock', child: Text('Low Stock')),
                    const PopupMenuItem(value: 'out_of_stock', child: Text('Out of Stock')),
                    const PopupMenuItem(value: 'active', child: Text('Active Only')),
                    const PopupMenuItem(value: 'inactive', child: Text('Inactive Only')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list),
                        const SizedBox(width: 8),
                        Text(_getFilterDisplayName()),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildLowStockTab(),
                _buildStockTakeTab(),
                _buildMovementsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedProducts.isNotEmpty 
          ? BarcodePrintFAB(
              selectedProducts: _selectedProducts,
            )
          : _buildFloatingActionButton(),
    );
  }

  Widget _buildStatsCard(InventoryStats stats) {
    final theme = Theme.of(context);
    
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 20),
              const SizedBox(width: 8),
              Text(
                'Inventory Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Products',
                  stats.totalProducts.toString(),
                  Icons.inventory_2,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Low Stock',
                  stats.lowStockCount.toString(),
                  Icons.warning,
                  AppColors.warning,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Out of Stock',
                  stats.outOfStockCount.toString(),
                  Icons.cancel,
                  AppColors.error,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Value',
                  '\$${stats.totalInventoryValue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final filteredProducts = ref.watch(filteredInventoryProductsProvider(
      InventoryFilter(
        searchQuery: _searchController.text,
        filterType: _selectedFilter,
      ),
    ));

    return filteredProducts.when(
      data: (products) => Column(
        children: [
          // Barcode quick actions bar
          if (_selectedProducts.isNotEmpty)
            BarcodeQuickActions(
              products: products,
              selectedProducts: _selectedProducts,
              onSelectAll: () => _selectAllProducts(products),
              onClearSelection: _clearSelection,
            ),
          
          // Product list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) => InventoryProductCard(
                product: products[index],
                onStockAdjustment: () => _showStockAdjustmentDialog(products[index]),
                onViewMovements: () => _showProductMovements(products[index]),
                isSelected: _selectedProducts.contains(products[index]),
                onSelectionChanged: (selected) => _toggleProductSelection(products[index], selected),
                isSelectionMode: _isSelectionMode,
                onBarcodePrint: () => _showSingleProductBarcodeDialog(products[index]),
              ),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading products: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(filteredInventoryProductsProvider(
                InventoryFilter(
                  searchQuery: _searchController.text,
                  filterType: _selectedFilter,
                ),
              )),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockTab() {
    final lowStockProducts = ref.watch(lowStockProductsProvider);

    return lowStockProducts.when(
      data: (products) => products.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No low stock items!'),
                  Text('All products are above minimum levels.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) => LowStockProductCard(
                product: products[index],
                onRestock: () => _showRestockDialog(products[index]),
                onAdjustMinimum: () => _showMinimumAdjustmentDialog(products[index]),
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading low stock products: $error'),
      ),
    );
  }

  Widget _buildStockTakeTab() {
    return const StockTakeView();
  }

  Widget _buildMovementsTab() {
    final movements = ref.watch(stockMovementsProvider);

    return movements.when(
      data: (movements) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: movements.length,
        itemBuilder: (context, index) => StockMovementCard(
          movement: movements[index],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading movements: $error'),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0: // Overview
        return FloatingActionButton(
          onPressed: _showQuickStockAdjustment,
          child: const Icon(Icons.edit),
          tooltip: 'Quick Stock Adjustment',
        );
      case 1: // Low Stock
        return FloatingActionButton(
          onPressed: _showBulkRestockDialog,
          child: const Icon(Icons.add_shopping_cart),
          tooltip: 'Bulk Restock',
        );
      case 2: // Stock Take
        return FloatingActionButton(
          onPressed: _startNewStockTake,
          child: const Icon(Icons.inventory),
          tooltip: 'New Stock Take',
        );
      case 3: // Movements
        return FloatingActionButton(
          onPressed: _showAddMovementDialog,
          child: const Icon(Icons.add),
          tooltip: 'Add Movement',
        );
      default:
        return FloatingActionButton(
          onPressed: _showQuickStockAdjustment,
          child: const Icon(Icons.edit),
        );
    }
  }

  void _refreshProducts() {
    ref.invalidate(filteredInventoryProductsProvider(
      InventoryFilter(
        searchQuery: _searchController.text,
        filterType: _selectedFilter,
      ),
    ));
  }

  String _getFilterDisplayName() {
    switch (_selectedFilter) {
      case 'all': return 'All';
      case 'low_stock': return 'Low Stock';
      case 'out_of_stock': return 'Out of Stock';
      case 'active': return 'Active';
      case 'inactive': return 'Inactive';
      default: return 'All';
    }
  }

  void _showBarcodeScanner() {
    showDialog(
      context: context,
      builder: (context) => BarcodeScannerDialog(
        onBarcodeScanned: (barcode) => _handleBarcodeScanned(barcode),
      ),
    );
  }

  void _handleBarcodeScanned(String barcode) async {
    try {
      final product = await ref.read(databaseProvider).productsDao.getProductByBarcode(barcode);
      if (product != null) {
        _showStockAdjustmentDialog(product);
      } else {
        _showSnackBar('Product not found with barcode: $barcode', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error scanning barcode: $e', isError: true);
    }
  }

  void _showQuickStockAdjustment() {
    showDialog(
      context: context,
      builder: (context) => QuickStockAdjustmentDialog(
        onAdjustmentMade: () {
          _refreshProducts();
          ref.invalidate(inventoryStatsProvider);
        },
      ),
    );
  }

  void _showStockAdjustmentDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => StockAdjustmentDialog(
        product: product,
        onAdjustmentMade: () {
          _refreshProducts();
          ref.invalidate(inventoryStatsProvider);
        },
      ),
    );
  }

  void _showProductMovements(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductMovementsDialog(product: product),
    );
  }

  void _showRestockDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => RestockDialog(
        product: product,
        onRestocked: () {
          _refreshProducts();
          ref.invalidate(inventoryStatsProvider);
          ref.invalidate(lowStockProductsProvider);
        },
      ),
    );
  }

  void _showMinimumAdjustmentDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => MinimumStockAdjustmentDialog(
        product: product,
        onAdjusted: () {
          _refreshProducts();
          ref.invalidate(lowStockProductsProvider);
        },
      ),
    );
  }

  void _showBulkRestockDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkRestockDialog(
        onRestocked: () {
          _refreshProducts();
          ref.invalidate(inventoryStatsProvider);
          ref.invalidate(lowStockProductsProvider);
        },
      ),
    );
  }

  void _startNewStockTake() {
    // Navigate to stock take creation screen
    showDialog(
      context: context,
      builder: (context) => NewStockTakeDialog(
        onStockTakeStarted: () {
          _tabController.animateTo(2); // Switch to stock take tab
        },
      ),
    );
  }

  void _showAddMovementDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMovementDialog(
        onMovementAdded: () {
          ref.invalidate(stockMovementsProvider);
          _refreshProducts();
        },
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Barcode printing methods
  void _showBulkBarcodeMenu() async {
    final filteredProducts = await ref.read(filteredInventoryProductsProvider(
      InventoryFilter(
        searchQuery: _searchController.text,
        filterType: _selectedFilter,
      ),
    ).future);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => MultipleProductBarcodePrintDialog(
          products: filteredProducts,
        ),
      );
    }
  }

  void _selectAllProducts(List<Product> products) {
    setState(() {
      _selectedProducts = List.from(products);
      _isSelectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProducts.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleProductSelection(Product product, bool selected) {
    setState(() {
      if (selected) {
        _selectedProducts.add(product);
        _isSelectionMode = true;
      } else {
        _selectedProducts.remove(product);
        if (_selectedProducts.isEmpty) {
          _isSelectionMode = false;
        }
      }
    });
  }

  void _showSingleProductBarcodeDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductBarcodePrintDialog(product: product),
    );
  }
}
