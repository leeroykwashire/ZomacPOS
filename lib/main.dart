import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import 'database/tables/all_tables.dart';
import 'providers/database_providers.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'POS System'),
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
    final syncStatus = ref.watch(syncStatusProvider);

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
            syncStatus.when(
              data: (status) => Column(
                children: [
                  Text('Pending sync items: ${status['pending_items']}'),
                  Text('Failed sync items: ${status['failed_items']}'),
                  Text('Conflicted items: ${status['conflicted_items']}'),
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
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: IdGenerator.generateLocalId(),
        name: 'Sample Product ${DateTime.now().millisecondsSinceEpoch}',
        price: 29.99,
        qty: 100,
        currencyId: 'default-currency',
        companyId: const Value('default-company'),
        sku: 'SP${DateTime.now().millisecondsSinceEpoch}',
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
    final syncService = ref.read(syncServiceProvider);
    
    try {
      await syncService.performSync();
      ref.invalidate(syncStatusProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully!')),
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