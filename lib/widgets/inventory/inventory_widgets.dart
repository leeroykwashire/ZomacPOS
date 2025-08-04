import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../database/app_database.dart';
import '../../database/daos/stock_movements_dao.dart';
import '../../providers/inventory_providers.dart';
import '../../providers/database_providers.dart';
import '../../widgets/app_card.dart';
import '../barcode/barcode_action_buttons.dart';

// Inventory Product Card
class InventoryProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onStockAdjustment;
  final VoidCallback onViewMovements;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool isSelectionMode;
  final VoidCallback? onBarcodePrint;

  const InventoryProductCard({
    super.key,
    required this.product,
    required this.onStockAdjustment,
    required this.onViewMovements,
    this.isSelected = false,
    this.onSelectionChanged,
    this.isSelectionMode = false,
    this.onBarcodePrint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = product.qty <= product.minQty;
    final isOutOfStock = product.qty <= 0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) => onSelectionChanged?.call(value ?? false),
                  )
                : CircleAvatar(
                    backgroundColor: isOutOfStock
                        ? AppColors.error.withOpacity(0.1)
                        : isLowStock
                            ? AppColors.warning.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                    child: Icon(
                      isOutOfStock
                          ? Icons.cancel
                          : isLowStock
                              ? Icons.warning
                              : Icons.inventory,
                      color: isOutOfStock
                          ? AppColors.error
                          : isLowStock
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                  ),
            title: Text(
              product.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.sku != null)
                  Text('SKU: ${product.sku}'),
                if (product.barcode != null)
                  Text('Barcode: ${product.barcode}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Stock: ${product.qty}',
                      style: TextStyle(
                        color: isOutOfStock
                            ? AppColors.error
                            : isLowStock
                                ? AppColors.warning
                                : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (product.trackStock) ...[
                      Text(' / Min: ${product.minQty}'),
                    ],
                    const Spacer(),
                    Text('\$${product.price.toStringAsFixed(2)}'),
                  ],
                ),
                if (isLowStock && !isOutOfStock)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Text(
                      'LOW STOCK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      'OUT OF STOCK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: isSelectionMode
                ? null
                : PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'adjust',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Adjust Stock'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'movements',
                        child: Row(
                          children: [
                            Icon(Icons.history),
                            SizedBox(width: 8),
                            Text('View Movements'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'print_barcode',
                        child: Row(
                          children: [
                            Icon(Icons.qr_code),
                            SizedBox(width: 8),
                            Text('Print Barcode'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'adjust':
                          onStockAdjustment();
                          break;
                        case 'movements':
                          onViewMovements();
                          break;
                        case 'print_barcode':
                          onBarcodePrint?.call();
                          break;
                      }
                    },
                  ),
            onTap: isSelectionMode
                ? () => onSelectionChanged?.call(!isSelected)
                : null,
          ),
          
          // Barcode quick actions when not in selection mode
          if (!isSelectionMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ProductBarcodeActionButton(
                      product: product,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onStockAdjustment,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Adjust'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onViewMovements,
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('History'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Low Stock Product Card
class LowStockProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRestock;
  final VoidCallback onAdjustMinimum;

  const LowStockProductCard({
    super.key,
    required this.product,
    required this.onRestock,
    required this.onAdjustMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortage = product.minQty - product.qty;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.warning.withOpacity(0.1),
              child: Icon(
                Icons.warning,
                color: AppColors.warning,
              ),
            ),
            title: Text(
              product.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current: ${product.qty} | Minimum: ${product.minQty}'),
                Text(
                  'Shortage: $shortage units',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAdjustMinimum,
                    child: const Text('Adjust Minimum'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRestock,
                    child: const Text('Restock'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stock Movement Card
class StockMovementCard extends StatelessWidget {
  final StockMovementWithProduct movement;

  const StockMovementCard({
    super.key,
    required this.movement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncrease = movement.quantityChange > 0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncrease
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          child: Icon(
            isIncrease ? Icons.add : Icons.remove,
            color: isIncrease ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(movement.productName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${movement.actionId} • ${_formatDateTime(movement.createdAt)}'),
            Text('${movement.previousQuantity} → ${movement.newQuantity}'),
            if (movement.notes != null)
              Text(
                movement.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Text(
          '${isIncrease ? '+' : ''}${movement.quantityChange}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isIncrease ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Barcode Scanner Dialog for Bluetooth scanners
class BarcodeScannerDialog extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const BarcodeScannerDialog({
    super.key,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field for Bluetooth scanner input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner),
          SizedBox(width: 8),
          Text('Scan Barcode'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Use your Bluetooth scanner or enter barcode manually:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _barcodeController,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: 'Scan or enter barcode...',
              prefixIcon: Icon(Icons.qr_code),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                widget.onBarcodeScanned(value.trim());
                Navigator.of(context).pop();
              }
            },
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For Bluetooth scanners: Just scan the barcode and it will appear here automatically.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final barcode = _barcodeController.text.trim();
            if (barcode.isNotEmpty) {
              widget.onBarcodeScanned(barcode);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Search'),
        ),
      ],
    );
  }
}

// Quick Stock Adjustment Dialog
class QuickStockAdjustmentDialog extends ConsumerStatefulWidget {
  final VoidCallback onAdjustmentMade;

  const QuickStockAdjustmentDialog({
    super.key,
    required this.onAdjustmentMade,
  });

  @override
  ConsumerState<QuickStockAdjustmentDialog> createState() => _QuickStockAdjustmentDialogState();
}

class _QuickStockAdjustmentDialogState extends ConsumerState<QuickStockAdjustmentDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  Product? _selectedProduct;
  StockMovementReason _selectedReason = StockMovementReason.manualAdjustment;
  bool _isIncrease = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Quick Stock Adjustment'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Search
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search product by name, SKU, or barcode...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchProduct,
            ),
            
            if (_selectedProduct != null) ...[
              const SizedBox(height: 16),
              
              // Selected Product Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedProduct!.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Current Stock: ${_selectedProduct!.qty}'),
                    if (_selectedProduct!.sku != null)
                      Text('SKU: ${_selectedProduct!.sku}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Adjustment Type
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Increase'),
                      value: true,
                      groupValue: _isIncrease,
                      onChanged: (value) => setState(() => _isIncrease = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Decrease'),
                      value: false,
                      groupValue: _isIncrease,
                      onChanged: (value) => setState(() => _isIncrease = value!),
                    ),
                  ),
                ],
              ),
              
              // Quantity
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              
              const SizedBox(height: 16),
              
              // Reason
              DropdownButtonFormField<StockMovementReason>(
                value: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: StockMovementReason.values.map((reason) => 
                  DropdownMenuItem(
                    value: reason,
                    child: Text(reason.name),
                  ),
                ).toList(),
                onChanged: (value) => setState(() => _selectedReason = value!),
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedProduct != null && !_isLoading ? _performAdjustment : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Adjust'),
        ),
      ],
    );
  }

  void _searchProduct(String query) async {
    if (query.length < 2) {
      setState(() => _selectedProduct = null);
      return;
    }

    try {
      final database = ref.read(databaseProvider);
      
      // Try barcode first
      Product? product = await database.productsDao.getProductByBarcode(query);
      
      // If not found by barcode, search by name/SKU
      if (product == null) {
        final results = await database.productsDao.searchProducts(query);
        product = results.isNotEmpty ? results.first : null;
      }
      
      setState(() => _selectedProduct = product);
    } catch (e) {
      // Handle search error
    }
  }

  void _performAdjustment() async {
    if (_selectedProduct == null || _quantityController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(_quantityController.text);
      final quantityChange = _isIncrease ? quantity : -quantity;
      
      final inventoryService = ref.read(inventoryServiceProvider);
      await inventoryService.adjustStock(
        productId: _selectedProduct!.id,
        quantityChange: quantityChange,
        reason: _selectedReason,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      widget.onAdjustmentMade();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock adjusted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adjusting stock: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Placeholder widgets for other dialogs (we'll implement these next)
class StockAdjustmentDialog extends StatelessWidget {
  final Product product;
  final VoidCallback onAdjustmentMade;

  const StockAdjustmentDialog({
    super.key,
    required this.product,
    required this.onAdjustmentMade,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Stock - ${product.name}'),
      content: const Text('Stock adjustment dialog coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class ProductMovementsDialog extends StatelessWidget {
  final Product product;

  const ProductMovementsDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Movements - ${product.name}'),
      content: const Text('Product movements dialog coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class RestockDialog extends StatelessWidget {
  final Product product;
  final VoidCallback onRestocked;

  const RestockDialog({
    super.key,
    required this.product,
    required this.onRestocked,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Restock - ${product.name}'),
      content: const Text('Restock dialog coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class MinimumStockAdjustmentDialog extends StatelessWidget {
  final Product product;
  final VoidCallback onAdjusted;

  const MinimumStockAdjustmentDialog({
    super.key,
    required this.product,
    required this.onAdjusted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Minimum - ${product.name}'),
      content: const Text('Minimum stock adjustment dialog coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class BulkRestockDialog extends StatelessWidget {
  final VoidCallback onRestocked;

  const BulkRestockDialog({super.key, required this.onRestocked});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Restock'),
      content: const Text('Bulk restock dialog coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class StockTakeView extends StatelessWidget {
  const StockTakeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Stock Take feature coming soon...'),
    );
  }
}

class NewStockTakeDialog extends StatelessWidget {
  final VoidCallback onStockTakeStarted;

  const NewStockTakeDialog({super.key, required this.onStockTakeStarted});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Stock Take'),
      content: const Text('Stock take creation coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class AddMovementDialog extends StatelessWidget {
  final VoidCallback onMovementAdded;

  const AddMovementDialog({super.key, required this.onMovementAdded});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Movement'),
      content: const Text('Add movement dialog coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
