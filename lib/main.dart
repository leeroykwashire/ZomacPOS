import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import 'core/constants.dart';
import 'core/theme.dart';
import 'database/app_database.dart';
import 'database/id_generator.dart';
import 'providers/app_providers.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final syncStats = ref.watch(syncStatsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'POS System Database Ready!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Products count
            productsAsync.when(
              data: (products) => Text(
                'Products in database: ${products.length}',
                style: const TextStyle(fontSize: 18),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
            
            const SizedBox(height: 20),
            
            // Sync status
            syncStats.when(
              data: (status) => Column(
                children: [
                  Text('Pending sync items: ${status['pendingItems'] ?? 0}'),
                  Text('Queued items: ${status['errors'] ?? 0}'),
                  Text('Status: ${status['status'] ?? 'unknown'}'),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Sync error: $error'),
            ),
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: () {
                _createSampleProduct();
              },
              child: const Text('Create Sample Product'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                _performSync();
              },
              child: const Text('Test Sync'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSampleProduct() async {
    final database = ref.read(databaseProvider);
    
    try {
      // Get the default company ID
      final companyId = await database.getDefaultCompanyId();
      if (companyId == null) {
        throw Exception('No default company found');
      }
      
      // Add a sample product to test the database
      await database.productsDao.createProduct(ProductsCompanion.insert(
        id: IdGenerator.generateLocalId(),
        name: 'Sample Product ${DateTime.now().millisecondsSinceEpoch}',
        price: 29.99,
        qty: const Value(100),
        currencyId: 'default-currency', // This should also use a dynamic ID
        companyId: companyId,
        sku: Value('SP${DateTime.now().millisecondsSinceEpoch}'),
      ));
      
      // Refresh the products list
      ref.invalidate(productsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample product created!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating product: $e')),
        );
      }
    }
  }

  Future<void> _performSync() async {
    // Sync functionality would use the sync DAO
    try {
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync functionality coming soon!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }
}