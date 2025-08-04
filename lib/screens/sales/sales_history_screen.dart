import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/sales_providers.dart';
import '../../widgets/widgets.dart';
import 'sale_details_screen.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedPaymentMethod = 'All';
  DateTimeRange? _dateRange;
  String _selectedCashier = 'All';

  final List<String> _statusOptions = ['All', 'completed', 'pending', 'cancelled', 'refunded'];
  final List<String> _paymentMethods = ['All', 'cash', 'card', 'digital_wallet'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    
    // Set default date range to today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dateRange = DateTimeRange(
      start: today,
      end: today.add(const Duration(days: 1)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final userRole = currentUser?['role'] ?? 'cashier';
    final isAdmin = userRole == 'admin';
    final isManager = userRole == 'manager' || isAdmin;
    final currentUserId = currentUser?['id'] ?? '';

    // Build sales query based on user role
    final salesAsync = ref.watch(filteredSalesProvider(SalesFilter(
      searchQuery: _searchQuery,
      status: _selectedStatus == 'All' ? null : _selectedStatus,
      paymentMethod: _selectedPaymentMethod == 'All' ? null : _selectedPaymentMethod,
      dateRange: _dateRange != null 
          ? SalesDateTimeRange(start: _dateRange!.start, end: _dateRange!.end)
          : null,
      cashierId: isAdmin || isManager 
          ? (_selectedCashier == 'All' ? null : _selectedCashier)
          : currentUserId, // Cashiers only see their own sales
    )));

    final salesStatsAsync = ref.watch(salesStatsProvider(SalesStatsFilter(
      dateRange: _dateRange != null 
          ? SalesDateTimeRange(start: _dateRange!.start, end: _dateRange!.end)
          : null,
      cashierId: isAdmin || isManager ? null : currentUserId,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (isManager) // Only managers and admins can export
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportSalesData,
              tooltip: 'Export Data',
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printSalesReport,
            tooltip: 'Print Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by receipt number, customer...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Date Range Picker
                      _buildFilterChip(
                        icon: Icons.date_range,
                        label: _dateRange != null
                            ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                            : 'Select Date Range',
                        onTap: _selectDateRange,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Status Filter
                      _buildDropdownFilter<String>(
                        icon: Icons.check_circle_outline,
                        value: _selectedStatus,
                        items: _statusOptions,
                        onChanged: (value) => setState(() => _selectedStatus = value!),
                        labelBuilder: (status) => status == 'All' ? 'All Status' : status.toUpperCase(),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Payment Method Filter
                      _buildDropdownFilter<String>(
                        icon: Icons.payment,
                        value: _selectedPaymentMethod,
                        items: _paymentMethods,
                        onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                        labelBuilder: (method) => method == 'All' ? 'All Payments' : method.replaceAll('_', ' ').toUpperCase(),
                      ),
                      
                      // Cashier Filter (Only for Admin/Manager)
                      if (isManager) ...[
                        const SizedBox(width: 12),
                        _buildCashierFilter(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Summary
          salesStatsAsync.when(
            data: (stats) => _buildStatsSection(stats, theme),
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (error, stack) => const SizedBox(),
          ),

          // Sales List
          Expanded(
            child: salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return _buildSaleCard(sale, theme, isManager);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading sales: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required IconData icon,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 12),
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(labelBuilder(item)),
            )).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCashierFilter() {
    final cashiersAsync = ref.watch(cashiersProvider);
    
    return cashiersAsync.when(
      data: (cashiers) {
        final cashierOptions = ['All', ...cashiers.map((c) => c.id)];
        final cashierLabels = {
          'All': 'All Cashiers',
          ...{for (var c in cashiers) c.id: c.fullName}
        };
        
        return _buildDropdownFilter<String>(
          icon: Icons.person,
          value: _selectedCashier,
          items: cashierOptions,
          onChanged: (value) => setState(() => _selectedCashier = value!),
          labelBuilder: (cashierId) => cashierLabels[cashierId] ?? cashierId,
        );
      },
      loading: () => const SizedBox(),
      error: (error, stack) => const SizedBox(),
    );
  }

  Widget _buildStatsSection(SalesStats stats, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Sales',
              '\$${stats.totalAmount.toStringAsFixed(2)}',
              Icons.attach_money,
              theme,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Transactions',
              '${stats.transactionCount}',
              Icons.receipt_long,
              theme,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Average',
              '\$${stats.averageAmount.toStringAsFixed(2)}',
              Icons.trending_up,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildSaleCard(Sale sale, ThemeData theme, bool canModify) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _viewSaleDetails(sale),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Receipt #${sale.receiptNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(sale.status, theme),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '\$${sale.total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.payment, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    sale.paymentMethod.replaceAll('_', ' ').toUpperCase(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(sale.saleDate),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (canModify && sale.status == 'completed')
                    TextButton(
                      onPressed: () => _showRefundDialog(sale),
                      child: const Text('Refund'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'refunded':
        color = Colors.purple;
        icon = Icons.undo;
        break;
      default:
        color = theme.colorScheme.outline;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No sales found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _viewSaleDetails(Sale sale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleDetailsScreen(saleId: sale.id),
      ),
    );
  }

  void _showRefundDialog(Sale sale) {
    // TODO: Implement refund dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund'),
        content: Text('Process refund for receipt #${sale.receiptNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Process refund
              Navigator.pop(context);
            },
            child: const Text('Refund'),
          ),
        ],
      ),
    );
  }

  void _exportSalesData() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _printSalesReport() {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
