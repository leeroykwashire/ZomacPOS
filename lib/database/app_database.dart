import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

// Import all tables
import 'tables/users_table.dart';
import 'tables/companies_table.dart';
import 'tables/categories_table.dart';
import 'tables/products_table.dart';
import 'tables/sales_table.dart';
import 'tables/sales_items_table.dart';
import 'tables/carts_table.dart';
import 'tables/sync_tables.dart';
import 'tables/other_tables.dart';

// Import all DAOs
import 'daos/users_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/cart_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/stock_movements_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // Core business tables
    Users,
    Companies,
    Categories,
    Products,
    Sales,
    SalesItems,
    Carts,
    
    // Sync system tables
    SyncMetadata,
    SyncQueue,
    ChangeLog,
    
    // Other tables
    Currencies,
    Expenses,
    Customers,
    Suppliers,
    StockMovements,
    AppSettings,
  ],
  daos: [
    UsersDao,
    CategoriesDao,
    ProductsDao,
    SalesDao,
    CartDao,
    SyncDao,
    StockMovementsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedInitialData();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Handle future migrations here
    },
  );

  // Seed initial data
  Future<void> _seedInitialData() async {
    const uuid = Uuid();
    
    // Generate consistent UUIDs for initial data
    final companyId = uuid.v4();
    final currencyId = uuid.v4();
    final adminId = uuid.v4();
    final categoryId = uuid.v4();
    final product1Id = uuid.v4();
    final product2Id = uuid.v4();
    
    // Create default company
    final defaultCompany = await into(companies).insertReturning(
      CompaniesCompanion.insert(
        id: companyId,
        name: 'My Business',
        email: 'admin@mybusiness.com',
        currency: const Value('USD'),
      )
    );

    // Create default currency
    await into(currencies).insert(
      CurrenciesCompanion.insert(
        id: currencyId,
        name: 'US Dollar',
        code: 'USD',
        symbol: '\$',
        isDefault: const Value(true),
        companyId: defaultCompany.id,
      )
    );

    // Create default admin user
    await into(users).insert(
      UsersCompanion.insert(
        id: adminId,
        fullName: 'System Administrator',
        email: 'admin@pos.local',
        password: 'admin123', // In real app, hash this!
        role: const Value('admin'),
        companyId: defaultCompany.id,
      )
    );

    // Create default category
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: categoryId,
        name: 'General',
        description: const Value('Default category for products'),
        companyId: defaultCompany.id,
      )
    );

    // Add some sample products
    await into(products).insert(
      ProductsCompanion.insert(
        id: product1Id,
        name: 'Sample Product 1',
        price: 19.99,
        qty: const Value(100),
        categoryId: Value(categoryId),
        currencyId: currencyId,
        companyId: defaultCompany.id,
        sku: const Value('SP001'),
      )
    );

    await into(products).insert(
      ProductsCompanion.insert(
        id: product2Id,
        name: 'Sample Product 2',
        price: 29.99,
        qty: const Value(50),
        categoryId: Value(categoryId),
        currencyId: currencyId,
        companyId: defaultCompany.id,
        sku: const Value('SP002'),
      )
    );

    // Add initial app settings
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        key: 'app_initialized',
        value: 'true',
      )
    );

    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        key: 'default_company_id',
        value: defaultCompany.id,
      )
    );
  }

  // Helper method to check if app is initialized
  Future<bool> isAppInitialized() async {
    final setting = await (select(appSettings)
      ..where((s) => s.key.equals('app_initialized')))
      .getSingleOrNull();
    return setting?.value == 'true';
  }

  // Helper method to get default company ID
  Future<String?> getDefaultCompanyId() async {
    final setting = await (select(appSettings)
      ..where((s) => s.key.equals('default_company_id')))
      .getSingleOrNull();
    return setting?.value;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'zomac_pos.db'));
    return NativeDatabase(file);
  });
}
