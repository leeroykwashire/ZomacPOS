import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../database/daos/cart_dao.dart';
import '../../providers/app_providers.dart';
import '../../providers/pos_providers.dart';
import '../../core/constants.dart';

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final _barcodeController = TextEditingController();
  final _searchController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  
  String _searchQuery = '';
  bool _showCustomerDetails = false;
  String _paymentMethod = 'cash';
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    // Generate unique session ID for this transaction
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final cartSummaryAsync = ref.watch(cartSummaryProvider(_sessionId));
    final filteredProductsAsync = ref.watch(filteredProductsProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showSettingsDialog(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Product Search and Selection
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search and Barcode Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search Products',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Scan Barcode',
                            prefixIcon: Icon(Icons.qr_code_scanner),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (barcode) => _handleBarcodeScanned(barcode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Product Grid
                  Expanded(
                    child: filteredProductsAsync.when(
                      data: (products) => products.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No Products Found',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Try adjusting your search terms'),
                                ],
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return _buildProductCard(product);
                              },
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${error.toString()}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.refresh(filteredProductsProvider(_searchQuery)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Panel - Cart and Checkout
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  left: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Column(
                children: [
                  // Cart Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cart',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _clearCart(),
                          icon: Icon(
                            Icons.clear_all,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Cart Items
                  Expanded(
                    child: cartSummaryAsync.when(
                      data: (cartSummary) => cartSummary.items.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Cart is Empty',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Add products to start a transaction'),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: cartSummary.items.length,
                                    itemBuilder: (context, index) {
                                      final item = cartSummary.items[index];
                                      return _buildCartItem(item);
                                    },
                                  ),
                                ),
                                
                                // Cart Summary
                                _buildCartSummary(cartSummary),
                              ],
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${error.toString()}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.refresh(cartSummaryProvider(_sessionId)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Customer Details Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _showCustomerDetails,
                          onChanged: (value) => setState(() => _showCustomerDetails = value!),
                        ),
                        const Text('Add Customer Details'),
                      ],
                    ),
                  ),
                  
                  // Customer Details Section
                  if (_showCustomerDetails)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _customerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Customer Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customerPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  
                  // Payment Method Selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPaymentMethodChip('cash', 'Cash', Icons.money),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPaymentMethodChip('card', 'Card', Icons.credit_card),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPaymentMethodChip('digital_wallet', 'Wallet', Icons.account_balance_wallet),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Checkout Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: cartSummaryAsync.when(
                      data: (cartSummary) => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cartSummary.items.isNotEmpty
                              ? () => _processTransaction(cartSummary, currentUser)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(
                            'Complete Sale - \$${cartSummary.total.toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: null,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => const SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: null,
                          child: Text('Error loading cart'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    final isLowStock = product.qty <= product.minQty;
    final isOutOfStock = product.qty <= 0;

    return Card(
      child: InkWell(
        onTap: isOutOfStock ? null : () => _addToCart(product),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Product Name
              Text(
                product.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Price
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Stock Status
              Row(
                children: [
                  Icon(
                    isOutOfStock
                        ? Icons.cancel
                        : isLowStock
                            ? Icons.warning
                            : Icons.check_circle,
                    size: 16,
                    color: isOutOfStock
                        ? AppColors.error
                        : isLowStock
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isOutOfStock
                          ? 'Out of Stock'
                          : '${product.qty} available',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOutOfStock
                            ? AppColors.error
                            : isLowStock
                                ? AppColors.warning
                                : theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(Cart item) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${item.price.toStringAsFixed(2)} each',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeFromCart(item.id),
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _updateQuantity(item.id, item.qty - 1),
                        icon: const Icon(Icons.remove),
                        iconSize: 16,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          item.qty.toString(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateQuantity(item.id, item.qty + 1),
                        icon: const Icon(Icons.add),
                        iconSize: 16,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartSummary cartSummary) {
    final theme = Theme.of(context);
    final tax = cartSummary.total * 0.1; // 10% tax
    final totalWithTax = cartSummary.total + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: theme.textTheme.bodyLarge),
              Text('\$${cartSummary.total.toStringAsFixed(2)}', style: theme.textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax (10%):', style: theme.textTheme.bodyLarge),
              Text('\$${tax.toStringAsFixed(2)}', style: theme.textTheme.bodyLarge),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${totalWithTax.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChip(String method, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _paymentMethod == method;

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => setState(() => _paymentMethod = method),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
      ),
      label: Text(label),
      selectedColor: AppColors.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
    );
  }

  Future<void> _handleBarcodeScanned(String barcode) async {
    if (barcode.isEmpty) return;

    try {
      final product = await ref.read(productByBarcodeProvider(barcode).future);
      if (product != null) {
        _addToCart(product);
        _barcodeController.clear();
      } else {
        _showErrorSnackBar('Product not found');
      }
    } catch (e) {
      _showErrorSnackBar('Error scanning barcode: $e');
    }
  }

  Future<void> _addToCart(Product product) async {
    if (product.qty <= 0) {
      _showErrorSnackBar('Product is out of stock');
      return;
    }

    try {
      await ref.read(cartDaoProvider).addToCart(
        _sessionId,
        product.id,
        product.name,
        1,
        product.price,
      );
      
      // Refresh cart summary
      ref.invalidate(cartSummaryProvider(_sessionId));
      
      // Show success feedback
      HapticFeedback.lightImpact();
      _showSuccessSnackBar('${product.name} added to cart');
    } catch (e) {
      _showErrorSnackBar('Error adding to cart: $e');
    }
  }

  Future<void> _updateQuantity(int cartId, int newQuantity) async {
    try {
      await ref.read(cartDaoProvider).updateCartItemQuantity(cartId, newQuantity);
      ref.invalidate(cartSummaryProvider(_sessionId));
      HapticFeedback.selectionClick();
    } catch (e) {
      _showErrorSnackBar('Error updating quantity: $e');
    }
  }

  Future<void> _removeFromCart(int cartId) async {
    try {
      await ref.read(cartDaoProvider).removeFromCart(cartId);
      ref.invalidate(cartSummaryProvider(_sessionId));
      _showSuccessSnackBar('Item removed from cart');
    } catch (e) {
      _showErrorSnackBar('Error removing item: $e');
    }
  }

  Future<void> _clearCart() async {
    try {
      await ref.read(cartDaoProvider).clearCart(_sessionId);
      ref.invalidate(cartSummaryProvider(_sessionId));
      _showSuccessSnackBar('Cart cleared');
    } catch (e) {
      _showErrorSnackBar('Error clearing cart: $e');
    }
  }

  Future<void> _processTransaction(CartSummary cartSummary, Map<String, dynamic>? currentUser) async {
    if (cartSummary.items.isEmpty) return;

    try {
      final posService = ref.read(posServiceProvider);
      final sale = await posService.processSale(
        sessionId: _sessionId,
        cartSummary: cartSummary,
        paymentMethod: _paymentMethod,
        customerName: _customerNameController.text.trim().isEmpty 
            ? null 
            : _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim().isEmpty 
            ? null 
            : _customerPhoneController.text.trim(),
        cashierId: currentUser?['id'] ?? '',
      );

      // Clear cart and reset form
      await _clearCart();
      _customerNameController.clear();
      _customerPhoneController.clear();
      setState(() {
        _showCustomerDetails = false;
        _paymentMethod = 'cash';
      });

      // Show success and print receipt option
      _showTransactionCompleteDialog(sale);
      
    } catch (e) {
      _showErrorSnackBar('Transaction failed: $e');
    }
  }

  void _showTransactionCompleteDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text('Sale ID: ${sale.id}'),
            Text('Total: \$${sale.total.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _printReceipt(sale);
            },
            child: const Text('Print Receipt'),
          ),
        ],
      ),
    );
  }

  void _printReceipt(Sale sale) {
    // TODO: Implement receipt printing
    _showSuccessSnackBar('Receipt printing not implemented yet');
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('POS Settings'),
        content: const Text('Settings functionality will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
