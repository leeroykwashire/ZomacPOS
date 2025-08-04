import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/sales_providers.dart';
import '../../providers/app_providers.dart';

class SaleDetailsScreen extends ConsumerWidget {
  final String saleId;

  const SaleDetailsScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final saleAsync = ref.watch(saleDetailsProvider(saleId));
    final saleItemsAsync = ref.watch(saleItemsProvider(saleId));
    final currentUser = ref.watch(currentUserProvider);
    final userRole = currentUser?['role'] ?? 'cashier';
    final isManager = userRole == 'manager' || userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReceipt(context),
            tooltip: 'Print Receipt',
          ),
          if (isManager)
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, value, ref),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refund',
                  child: ListTile(
                    leading: Icon(Icons.undo),
                    title: Text('Process Refund'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Duplicate Sale'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: saleAsync.when(
        data: (sale) {
          if (sale == null) {
            return const Center(
              child: Text('Sale not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sale Header
                _buildSaleHeader(sale, theme),
                
                const SizedBox(height: 24),
                
                // Sale Items
                _buildSaleItemsSection(saleItemsAsync, theme),
                
                const SizedBox(height: 24),
                
                // Payment Information
                _buildPaymentSection(sale, theme),
                
                const SizedBox(height: 24),
                
                // Additional Information
                _buildAdditionalInfoSection(sale, theme),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading sale details: $error'),
        ),
      ),
    );
  }

  Widget _buildSaleHeader(Sale sale, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt #${sale.receiptNumber}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(sale.saleDate),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(sale.status, theme),
              ],
            ),
            
            const Divider(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Total Amount',
                    '\$${sale.total.toStringAsFixed(2)}',
                    Icons.attach_money,
                    theme,
                    isHighlighted: true,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Payment Method',
                    sale.paymentMethod.replaceAll('_', ' ').toUpperCase(),
                    Icons.payment,
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItemsSection(AsyncValue<List<SalesItem>> saleItemsAsync, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        saleItemsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No items found'),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        const Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                        const Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        const Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        const Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      ],
                    ),
                    
                    const Divider(),
                    
                    // Items
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${item.qty}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '\$${item.subtotal.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error loading items: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(Sale sale, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPaymentRow('Subtotal', sale.subtotal, theme),
            _buildPaymentRow('Tax', sale.tax, theme),
            if (sale.discount > 0)
              _buildPaymentRow('Discount', -sale.discount, theme, isDiscount: true),
            
            const Divider(height: 24),
            
            _buildPaymentRow('Total', sale.total, theme, isTotal: true),
            _buildPaymentRow('Amount Paid', sale.amountPaid, theme),
            if (sale.change > 0)
              _buildPaymentRow('Change', sale.change, theme, isChange: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, ThemeData theme, {bool isTotal = false, bool isDiscount = false, bool isChange = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : 
                     isChange ? Colors.green :
                     isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection(Sale sale, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Sale ID', sale.id, theme),
            _buildInfoRow('Cashier ID', sale.cashierId, theme),
            if (sale.customerId != null)
              _buildInfoRow('Customer ID', sale.customerId!, theme),
            _buildInfoRow('Company ID', sale.companyId, theme),
            
            if (sale.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(sale.notes!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, ThemeData theme, {bool isHighlighted = false}) {
    return Column(
      children: [
        Icon(
          icon,
          color: isHighlighted ? theme.colorScheme.primary : theme.colorScheme.outline,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? theme.colorScheme.primary : null,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _printReceipt(BuildContext context) {
    // TODO: Implement print receipt functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print receipt functionality coming soon')),
    );
  }

  void _handleAction(BuildContext context, String action, WidgetRef ref) {
    switch (action) {
      case 'refund':
        _showRefundDialog(context, ref);
        break;
      case 'duplicate':
        _duplicateSale(context, ref);
        break;
    }
  }

  void _showRefundDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund'),
        content: const Text('Are you sure you want to process a refund for this sale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement refund logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refund processed successfully')),
              );
            },
            child: const Text('Process Refund'),
          ),
        ],
      ),
    );
  }

  void _duplicateSale(BuildContext context, WidgetRef ref) {
    // TODO: Implement duplicate sale functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate sale functionality coming soon')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
