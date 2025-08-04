import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../database/app_database.dart';
import '../../services/barcode_printing_service.dart';
import '../../widgets/app_card.dart';

// Single Product Barcode Print Dialog
class ProductBarcodePrintDialog extends StatefulWidget {
  final Product product;

  const ProductBarcodePrintDialog({
    super.key,
    required this.product,
  });

  @override
  State<ProductBarcodePrintDialog> createState() => _ProductBarcodePrintDialogState();
}

class _ProductBarcodePrintDialogState extends State<ProductBarcodePrintDialog> {
  int _quantity = 1;
  bool _includeProductInfo = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Print Barcode - ${widget.product.name}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product info preview
            AppCard(
              child: ListTile(
                leading: Icon(
                  Icons.qr_code,
                  color: AppColors.primary,
                  size: 32,
                ),
                title: Text(widget.product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.sku != null)
                      Text('SKU: ${widget.product.sku}'),
                    if (widget.product.barcode != null)
                      Text('Barcode: ${widget.product.barcode}'),
                    Text('Price: \$${widget.product.price.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quantity selector
            Row(
              children: [
                const Text('Quantity:'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _quantity.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _quantity < 100 ? () => setState(() => _quantity++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Options
            CheckboxListTile(
              title: const Text('Include product information'),
              subtitle: const Text('Name, price, and SKU on label'),
              value: _includeProductInfo,
              onChanged: (value) => setState(() => _includeProductInfo = value ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _previewBarcode,
          child: const Text('Preview'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _printBarcode,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Print'),
        ),
      ],
    );
  }

  void _previewBarcode() async {
    setState(() => _isLoading = true);
    
    try {
      await BarcodePrintingService.printProductBarcode(
        widget.product,
        quantity: _quantity,
        includeProductInfo: _includeProductInfo,
        jobName: 'Preview - ${widget.product.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error previewing barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _printBarcode() async {
    setState(() => _isLoading = true);
    
    try {
      await BarcodePrintingService.printProductBarcode(
        widget.product,
        quantity: _quantity,
        includeProductInfo: _includeProductInfo,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcode sent to printer successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Multiple Products Barcode Print Dialog
class MultipleProductBarcodePrintDialog extends StatefulWidget {
  final List<Product> products;

  const MultipleProductBarcodePrintDialog({
    super.key,
    required this.products,
  });

  @override
  State<MultipleProductBarcodePrintDialog> createState() => _MultipleProductBarcodePrintDialogState();
}

class _MultipleProductBarcodePrintDialogState extends State<MultipleProductBarcodePrintDialog> {
  bool _includeProductInfo = true;
  int _labelsPerRow = 2;
  bool _isLoading = false;
  List<Product> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _selectedProducts = List.from(widget.products);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Print Barcodes (${widget.products.length} products)'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            // Options
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Include product info'),
                    value: _includeProductInfo,
                    onChanged: (value) => setState(() => _includeProductInfo = value ?? true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _labelsPerRow,
                    decoration: const InputDecoration(
                      labelText: 'Labels per row',
                      border: OutlineInputBorder(),
                    ),
                    items: [1, 2, 3, 4].map((value) => 
                      DropdownMenuItem(
                        value: value,
                        child: Text('$value'),
                      ),
                    ).toList(),
                    onChanged: (value) => setState(() => _labelsPerRow = value ?? 2),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Product selection
            Row(
              children: [
                const Text('Products to print:'),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedProducts = _selectedProducts.length == widget.products.length
                        ? []
                        : List.from(widget.products);
                  }),
                  child: Text(_selectedProducts.length == widget.products.length
                      ? 'Deselect All'
                      : 'Select All'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Product list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final product = widget.products[index];
                    final isSelected = _selectedProducts.contains(product);
                    
                    return CheckboxListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        'SKU: ${product.sku ?? 'N/A'} • Barcode: ${product.barcode ?? 'N/A'}',
                      ),
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedProducts.add(product);
                          } else {
                            _selectedProducts.remove(product);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedProducts.isEmpty || _isLoading ? null : _previewBarcodes,
          child: const Text('Preview'),
        ),
        ElevatedButton(
          onPressed: _selectedProducts.isEmpty || _isLoading ? null : _printBarcodes,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Print (${_selectedProducts.length})'),
        ),
      ],
    );
  }

  void _previewBarcodes() async {
    setState(() => _isLoading = true);
    
    try {
      await BarcodePrintingService.previewBarcodeLabels(
        _selectedProducts,
        includeProductInfo: _includeProductInfo,
        jobName: 'Preview - Multiple Products',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error previewing barcodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _printBarcodes() async {
    setState(() => _isLoading = true);
    
    try {
      await BarcodePrintingService.printBarcodeLabels(
        _selectedProducts,
        includeProductInfo: _includeProductInfo,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedProducts.length} barcodes sent to printer'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing barcodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Barcode Print Options Bottom Sheet
class BarcodePrintOptionsSheet extends StatelessWidget {
  final Product product;

  const BarcodePrintOptionsSheet({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Print Barcode Options',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          ListTile(
            leading: Icon(Icons.qr_code, color: AppColors.primary),
            title: const Text('Print Single Label'),
            subtitle: const Text('Print one barcode label for this product'),
            onTap: () {
              Navigator.of(context).pop();
              _showSinglePrintDialog(context);
            },
          ),
          
          ListTile(
            leading: Icon(Icons.print, color: AppColors.success),
            title: const Text('Quick Print'),
            subtitle: const Text('Print immediately with default settings'),
            onTap: () {
              Navigator.of(context).pop();
              _quickPrint(context);
            },
          ),
          
          ListTile(
            leading: Icon(Icons.preview, color: AppColors.warning),
            title: const Text('Preview Only'),
            subtitle: const Text('Preview barcode before printing'),
            onTap: () {
              Navigator.of(context).pop();
              _previewOnly(context);
            },
          ),
        ],
      ),
    );
  }

  void _showSinglePrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProductBarcodePrintDialog(product: product),
    );
  }

  void _quickPrint(BuildContext context) async {
    try {
      await BarcodePrintingService.printProductBarcode(product);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barcode sent to printer'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previewOnly(BuildContext context) async {
    try {
      await BarcodePrintingService.printProductBarcode(
        product,
        jobName: 'Preview - ${product.name}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error previewing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
