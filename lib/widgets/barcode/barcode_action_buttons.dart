import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../database/app_database.dart';
import '../../services/barcode_printing_service.dart';
import 'barcode_print_dialogs.dart';

// Single Product Barcode Action Button
class ProductBarcodeActionButton extends StatelessWidget {
  final Product product;
  final bool isCompact;

  const ProductBarcodeActionButton({
    super.key,
    required this.product,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        icon: Icon(
          Icons.qr_code,
          color: AppColors.primary,
        ),
        tooltip: 'Print Barcode',
        onPressed: () => _showPrintOptions(context),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _showPrintOptions(context),
      icon: const Icon(Icons.qr_code),
      label: const Text('Print Barcode'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BarcodePrintOptionsSheet(product: product),
    );
  }
}

// Multiple Products Barcode Print Button
class MultipleBarcodeActionButton extends StatelessWidget {
  final List<Product> products;
  final VoidCallback? onPressed;

  const MultipleBarcodeActionButton({
    super.key,
    required this.products,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = products.isNotEmpty;
    
    return ElevatedButton.icon(
      onPressed: isEnabled ? () => _showMultiplePrintDialog(context) : null,
      icon: const Icon(Icons.print),
      label: Text('Print Barcodes (${products.length})'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? AppColors.success : Colors.grey,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showMultiplePrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MultipleProductBarcodePrintDialog(products: products),
    );
  }
}

// Floating Action Button for Barcode Printing
class BarcodePrintFAB extends StatelessWidget {
  final List<Product> selectedProducts;
  final VoidCallback? onQuickPrint;

  const BarcodePrintFAB({
    super.key,
    required this.selectedProducts,
    this.onQuickPrint,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    if (selectedProducts.length == 1) {
      return FloatingActionButton(
        onPressed: () => _showSingleProductOptions(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.qr_code),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () => _showMultipleProductsOptions(context),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.print),
      label: Text('Print ${selectedProducts.length}'),
    );
  }

  void _showSingleProductOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BarcodePrintOptionsSheet(product: selectedProducts.first),
    );
  }

  void _showMultipleProductsOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MultipleProductBarcodePrintDialog(products: selectedProducts),
    );
  }
}

// Barcode Action Menu for Product Cards
class ProductBarcodeMenu extends StatelessWidget {
  final Product product;

  const ProductBarcodeMenu({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppColors.primary,
      ),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'print_single',
          child: ListTile(
            leading: Icon(Icons.qr_code),
            title: Text('Print Barcode'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'quick_print',
          child: ListTile(
            leading: Icon(Icons.print),
            title: Text('Quick Print'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'preview',
          child: ListTile(
            leading: Icon(Icons.preview),
            title: Text('Preview'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (product.barcode != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'view_barcode',
            child: ListTile(
              leading: Icon(Icons.visibility),
              title: Text('View Barcode'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'print_single':
        showDialog(
          context: context,
          builder: (context) => ProductBarcodePrintDialog(product: product),
        );
        break;
      case 'quick_print':
        _quickPrint(context);
        break;
      case 'preview':
        _previewBarcode(context);
        break;
      case 'view_barcode':
        _viewBarcode(context);
        break;
    }
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

  void _previewBarcode(BuildContext context) async {
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

  void _viewBarcode(BuildContext context) {
    if (product.barcode != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Barcode - ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.barcode!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (product.sku != null)
                Text('SKU: ${product.sku}'),
              Text('Price: \$${product.price.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => ProductBarcodePrintDialog(product: product),
                );
              },
              child: const Text('Print'),
            ),
          ],
        ),
      );
    }
  }
}

// Barcode Quick Actions Row
class BarcodeQuickActions extends StatelessWidget {
  final List<Product> products;
  final List<Product> selectedProducts;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;

  const BarcodeQuickActions({
    super.key,
    required this.products,
    required this.selectedProducts,
    this.onSelectAll,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${selectedProducts.length} of ${products.length} selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          if (selectedProducts.isNotEmpty) ...[
            TextButton(
              onPressed: onClearSelection,
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            MultipleBarcodeActionButton(products: selectedProducts),
          ] else ...[
            TextButton(
              onPressed: onSelectAll,
              child: const Text('Select All'),
            ),
          ],
        ],
      ),
    );
  }
}
