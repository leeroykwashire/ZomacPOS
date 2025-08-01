import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'all_tables.g.dart';

// Syncable table mixin for consistent sync fields
mixin SyncableTable on Table {
  // Identity
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get syncId => text().withLength(min: 36, max: 36).nullable().named('sync_id')();
  
  // Versioning
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get contentHash => text().nullable().named('content_hash')();
  
  // Sync state
  TextColumn get syncState => text().withDefault(const Constant('pending')).named('sync_state')();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false)).named('is_deleted')();
  DateTimeColumn get deletedAt => dateTime().nullable().named('deleted_at')();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at')();
  DateTimeColumn get lastSyncedAt => dateTime().nullable().named('last_synced_at')();
  
  // Ownership and context
  TextColumn get createdBy => text().nullable().named('created_by')();
  TextColumn get updatedBy => text().nullable().named('updated_by')();
  TextColumn get deviceId => text().nullable().named('device_id')();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Users table - matches Laravel schema
class Users extends Table with SyncableTable {
  TextColumn get fullName => text().named('full_name')();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get email => text().unique()();
  TextColumn get role => text().withDefault(const Constant('cashier'))();
  DateTimeColumn get emailVerifiedAt => dateTime().nullable().named('email_verified_at')();
  TextColumn get password => text()();
  TextColumn get rememberToken => text().nullable().named('remember_token')();
}

// Companies table - matches Laravel schema
class Companies extends Table with SyncableTable {
  TextColumn get companyName => text().named('company_name')();
  TextColumn get bpNumber => text().unique().named('bp_number')();
  TextColumn get email => text().unique()();
  TextColumn get phone => text()();
  TextColumn get logo => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
}

// Currencies table - matches Laravel schema
class Currencies extends Table with SyncableTable {
  TextColumn get name => text()();
  TextColumn get code => text().withLength(min: 3, max: 3)();
  TextColumn get symbol => text().withLength(min: 1, max: 5)();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0000)).named('exchange_rate')();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false)).named('is_default')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
}

// Products table - matches Laravel schema
class Products extends Table with SyncableTable {
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get qty => integer()();
  TextColumn get currencyId => text().named('currency_id')();
  TextColumn get warehouseId => text().nullable().named('warehouse_id')();
  TextColumn get categoryId => text().nullable().named('category_id')();
  TextColumn get companyId => text().withDefault(const Constant('no company')).named('company_id')();
  TextColumn get sku => text()();
  RealColumn get costPrice => real().nullable().named('cost_price')();
  RealColumn get vatRate => real().withDefault(const Constant(0.00)).named('vat_rate')();
}

// Carts table - matches Laravel schema
class Carts extends Table with SyncableTable {
  TextColumn get userId => text().named('user_id')();
  TextColumn get productId => text().named('product_id')();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  RealColumn get price => real()();
  RealColumn get subtotal => real()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
}

// Sales table - matches Laravel schema
class Sales extends Table with SyncableTable {
  TextColumn get userId => text().named('user_id')(); // the teller who made the sale
  TextColumn get companyId => text().named('company_id')();
  RealColumn get totalAmount => real().named('total_amount')();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  TextColumn get paymentMethod => text().nullable().named('payment_method')();
  TextColumn get notes => text().nullable()();
  TextColumn get cashCustomerId => text().nullable().named('cash_customer_id')();
  TextColumn get vatAmount => text().nullable().named('vat_amount')();
  TextColumn get receiptNumber => text().nullable().named('receipt_number')(); // Additional field
}

// Sales Items table - matches Laravel schema
class SalesItems extends Table with SyncableTable {
  TextColumn get companyId => text().named('company_id')();
  TextColumn get saleId => text().named('sale_id')();
  TextColumn get productId => text().named('product_id')();
  IntColumn get qty => integer()();
  RealColumn get price => real()();
  RealColumn get subtotal => real()();
  RealColumn get vatRate => real().named('vat_rate')();
  RealColumn get vatAmount => real().named('vat_amount')();
}

// Expenses table - matches Laravel schema
class Expenses extends Table with SyncableTable {
  RealColumn get amount => real()();
  TextColumn get description => text()();
  TextColumn get currencyId => text().named('currency_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get companyId => text().named('company_id')();
}

// Categories table - matches Laravel schema
class Categories extends Table with SyncableTable {
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get parentId => text().nullable().named('parent_id')();
  TextColumn get companyId => text().named('company_id')();
  RealColumn get priceAdjustmentPercentage => real().withDefault(const Constant(0.00)).named('price_adjustment_percentage')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
}

// Stock Takes table - matches Laravel schema
class StockTakes extends Table with SyncableTable {
  TextColumn get sessionStatus => text().withDefault(const Constant('open')).named('session_status')();
  TextColumn get companyId => text().named('company_id')();
}

// Stock Take Lines table - matches Laravel schema
class StockTakeLines extends Table with SyncableTable {
  TextColumn get sku => text()();
  TextColumn get productId => text().named('product_id')();
  TextColumn get stockTakeId => text().named('stock_take_id')();
  RealColumn get expectedQty => real().named('expected_qty')();
  RealColumn get countedQty => real().named('counted_qty')();
  TextColumn get varianceType => text().named('variance_type')(); // 'surplus', 'shortage', 'match'
  TextColumn get companyId => text().named('company_id')();
}

// Cash Customers table - matches Laravel schema
class CashCustomers extends Table with SyncableTable {
  TextColumn get fullname => text()();
  TextColumn get postalAddress => text().nullable().named('postal_address')();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get companyId => text().named('company_id')();
}

// Cash Drawers table - matches Laravel schema
class CashDrawers extends Table with SyncableTable {
  TextColumn get tellerId => text().named('teller_id')();
  TextColumn get currencyId => text().named('currency_id')();
  TextColumn get companyId => text().named('company_id')();
  RealColumn get openingBalance => real().withDefault(const Constant(0)).named('opening_balance')();
  RealColumn get cashSalesTotal => real().withDefault(const Constant(0)).named('cash_sales_total')();
  RealColumn get closingBalance => real().nullable().named('closing_balance')();
}

// Stock Movements table - matches Laravel schema
class StockMovements extends Table with SyncableTable {
  TextColumn get productId => text().named('product_id')();
  TextColumn get actionId => text().named('action_id')();
  TextColumn get companyId => text().named('company_id')();
  IntColumn get initialQty => integer().named('initial_qty')();
  IntColumn get finalQty => integer().named('final_qty')();
  TextColumn get notes => text().nullable()();
}

// Enhanced sync management with conflict resolution
class SyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get recordTable => text().named('table_name')();
  TextColumn get recordId => text().named('record_id')();
  TextColumn get syncId => text().nullable().named('sync_id')(); // Backend ID
  
  // Version tracking for conflict resolution
  IntColumn get localVersion => integer().withDefault(const Constant(1)).named('local_version')();
  IntColumn get serverVersion => integer().withDefault(const Constant(0)).named('server_version')();
  TextColumn get lastKnownHash => text().nullable().named('last_known_hash')(); // Content hash
  
  // Sync state tracking
  TextColumn get syncState => text().withDefault(const Constant('pending')).named('sync_state')(); // pending, syncing, synced, conflict, error
  TextColumn get operation => text().nullable()(); // create, update, delete
  DateTimeColumn get lastModifiedLocal => dateTime().withDefault(currentDateAndTime).named('last_modified_local')();
  DateTimeColumn get lastModifiedServer => dateTime().nullable().named('last_modified_server')();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable().named('last_sync_attempt')();
  
  // Conflict resolution
  TextColumn get conflictData => text().nullable().named('conflict_data')(); // JSON of conflicting data
  BoolColumn get hasConflict => boolean().withDefault(const Constant(false)).named('has_conflict')();
  TextColumn get conflictResolution => text().nullable().named('conflict_resolution')(); // client_wins, server_wins, merged, manual
  
  // Error handling and retry logic
  IntColumn get retryCount => integer().withDefault(const Constant(0)).named('retry_count')();
  TextColumn get lastError => text().nullable().named('last_error')();
  DateTimeColumn get nextRetryAt => dateTime().nullable().named('next_retry_at')();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at')();
}

// Enhanced sync queue with better error handling and batching
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get batchId => text().nullable().named('batch_id')(); // Group related operations
  TextColumn get recordTable => text().named('table_name')();
  TextColumn get localId => text().named('local_id')();
  TextColumn get syncId => text().nullable().named('sync_id')();
  TextColumn get operation => text()(); // create, update, delete
  TextColumn get data => text().nullable()(); // JSON data
  TextColumn get dependencies => text().nullable()(); // JSON array of dependent record IDs
  
  // Priority and ordering
  IntColumn get priority => integer().withDefault(const Constant(0))(); // Higher number = higher priority
  IntColumn get sequenceNumber => integer().nullable().named('sequence_number')(); // For maintaining order
  
  // State management
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, processing, completed, failed, cancelled
  IntColumn get retryCount => integer().withDefault(const Constant(0)).named('retry_count')();
  IntColumn get maxRetries => integer().withDefault(const Constant(3)).named('max_retries')();
  
  // Timing
  DateTimeColumn get scheduledAt => dateTime().withDefault(currentDateAndTime).named('scheduled_at')();
  DateTimeColumn get startedAt => dateTime().nullable().named('started_at')();
  DateTimeColumn get completedAt => dateTime().nullable().named('completed_at')();
  DateTimeColumn get nextRetryAt => dateTime().nullable().named('next_retry_at')();
  
  // Error tracking
  TextColumn get errorMessage => text().nullable().named('error_message')();
  TextColumn get errorCode => text().nullable().named('error_code')();
  TextColumn get stackTrace => text().nullable().named('stack_trace')();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at')();
}

// Sync sessions for tracking sync progress
class SyncSessions extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get sessionType => text().named('session_type')(); // full_sync, incremental_sync, push_only, pull_only
  TextColumn get status => text().withDefault(const Constant('started'))(); // started, in_progress, completed, failed, cancelled
  
  // Progress tracking
  IntColumn get totalRecords => integer().withDefault(const Constant(0)).named('total_records')();
  IntColumn get processedRecords => integer().withDefault(const Constant(0)).named('processed_records')();
  IntColumn get successfulRecords => integer().withDefault(const Constant(0)).named('successful_records')();
  IntColumn get failedRecords => integer().withDefault(const Constant(0)).named('failed_records')();
  IntColumn get conflictedRecords => integer().withDefault(const Constant(0)).named('conflicted_records')();
  
  // Timing
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime).named('started_at')();
  DateTimeColumn get completedAt => dateTime().nullable().named('completed_at')();
  RealColumn get durationSeconds => real().nullable().named('duration_seconds')();
  
  // Sync window
  DateTimeColumn get syncFromTime => dateTime().nullable().named('sync_from_time')();
  DateTimeColumn get syncToTime => dateTime().nullable().named('sync_to_time')();
  
  // Results
  TextColumn get summary => text().nullable()(); // JSON summary of sync results
  TextColumn get errors => text().nullable()(); // JSON array of errors encountered
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Change log for auditing and debugging
class ChangeLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get recordTable => text().named('table_name')();
  TextColumn get recordId => text().named('record_id')();
  TextColumn get operation => text()(); // insert, update, delete
  TextColumn get oldValues => text().nullable().named('old_values')(); // JSON
  TextColumn get newValues => text().nullable().named('new_values')(); // JSON
  TextColumn get changedFields => text().nullable().named('changed_fields')(); // JSON array
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get source => text().withDefault(const Constant('local')).named('source')(); // local, sync, import
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

// App settings table
class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at')();
}

@DriftDatabase(tables: [
  Users,
  Companies,
  Currencies,
  Categories,
  Products,
  Carts,
  Sales,
  SalesItems,
  Expenses,
  StockTakes,
  StockTakeLines,
  CashCustomers,
  CashDrawers,
  StockMovements,
  SyncMetadata,
  SyncQueue,
  SyncSessions,
  ChangeLog,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'pos_app.db'));
      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createIndexes();
        await _insertDefaultSettings();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle database migrations here when schema version changes
      },
    );
  }

  // Create indexes for better performance
  Future<void> _createIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS idx_sync_metadata_record ON sync_metadata(table_name, record_id);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_sync_metadata_state ON sync_metadata(sync_state);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_sync_queue_scheduled ON sync_queue(scheduled_at);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_change_log_table_record ON change_log(table_name, record_id);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_products_sync_state ON products(sync_state);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_sales_sync_state ON sales(sync_state);');
  }

  Future<void> _insertDefaultSettings() async {
    await setSetting('sync_batch_size', '50');
    await setSetting('sync_retry_delay_seconds', '30');
    await setSetting('sync_max_retries', '3');
    await setSetting('last_full_sync', '');
    await setSetting('device_id', IdGenerator.generateDeviceId());
  }

  // ==================== USERS QUERIES ====================
  Future<List<User>> getAllUsers() => select(users).get();
  
  Future<User?> getUserById(String id) => 
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  
  Future<User?> getUserByEmail(String email) => 
      (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();

  // ==================== COMPANIES QUERIES ====================
  Future<List<Company>> getAllCompanies() => select(companies).get();
  
  Future<Company?> getCompanyById(String id) => 
      (select(companies)..where((c) => c.id.equals(id))).getSingleOrNull();

  // ==================== PRODUCTS QUERIES ====================
  Future<List<Product>> getAllProducts() => select(products).get();
  
  Future<List<Product>> getProductsByCategory(String categoryId) => 
      (select(products)..where((p) => p.categoryId.equals(categoryId))).get();
  
  Future<List<Product>> searchProducts(String query) => 
      (select(products)..where((p) => 
          p.name.contains(query) | 
          p.sku.contains(query))).get();
  
  Future<Product?> getProductBySku(String sku) => 
      (select(products)..where((p) => p.sku.equals(sku))).getSingleOrNull();
  
  Future<List<Product>> getLowStockProducts({int threshold = 10}) => 
      (select(products)..where((p) => p.qty.isSmallerOrEqualValue(threshold))).get();

  // ==================== CATEGORIES QUERIES ====================
  Future<List<Category>> getAllCategories() => select(categories).get();
  
  Future<List<Category>> getActiveCategories() => 
      (select(categories)..where((c) => c.isActive.equals(true))).get();

  // ==================== CART QUERIES ====================
  Future<List<Cart>> getUserCart(String userId) => 
      (select(carts)..where((c) => c.userId.equals(userId) & c.status.equals('pending'))).get();
  
  Future<void> clearUserCart(String userId) => 
      (delete(carts)..where((c) => c.userId.equals(userId) & c.status.equals('pending'))).go();

  // ==================== SALES QUERIES ====================
  Future<List<Sale>> getAllSales() => select(sales).get();
  
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) => 
      (select(sales)..where((s) => 
          s.createdAt.isBetweenValues(start, end))).get();
  
  Future<List<Sale>> getSalesByUser(String userId) => 
      (select(sales)..where((s) => s.userId.equals(userId))).get();

  // ==================== SALES ITEMS QUERIES ====================
  Future<List<SalesItem>> getSaleItems(String saleId) => 
      (select(salesItems)..where((si) => si.saleId.equals(saleId))).get();

  // ==================== EXPENSES QUERIES ====================
  Future<List<Expense>> getAllExpenses() => select(expenses).get();
  
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) => 
      (select(expenses)..where((e) => 
          e.createdAt.isBetweenValues(start, end))).get();

  // ==================== CASH DRAWER QUERIES ====================
  Future<List<CashDrawer>> getCashDrawersByTeller(String tellerId) => 
      (select(cashDrawers)..where((cd) => cd.tellerId.equals(tellerId))).get();
  
  Future<CashDrawer?> getActiveCashDrawer(String tellerId) => 
      (select(cashDrawers)..where((cd) => 
          cd.tellerId.equals(tellerId) & 
          cd.closingBalance.isNull())).getSingleOrNull();

  // ==================== STOCK TAKE QUERIES ====================
  Future<List<StockTake>> getAllStockTakes() => select(stockTakes).get();
  
  Future<List<StockTakeLine>> getStockTakeLines(String stockTakeId) => 
      (select(stockTakeLines)..where((stl) => stl.stockTakeId.equals(stockTakeId))).get();

  // ==================== CURRENCIES QUERIES ====================
  Future<List<Currency>> getAllCurrencies() => select(currencies).get();
  
  Future<Currency?> getDefaultCurrency() => 
      (select(currencies)..where((c) => c.isDefault.equals(true))).getSingleOrNull();

  // ==================== CUSTOMERS QUERIES ====================
  Future<List<CashCustomer>> getAllCustomers() => select(cashCustomers).get();
  
  Future<List<CashCustomer>> searchCustomers(String query) => 
      (select(cashCustomers)..where((c) => 
          c.fullname.contains(query) | 
          c.email.contains(query) | 
          c.phone.contains(query))).get();

  // ==================== SYNC MANAGEMENT ====================
  
  // Create a new sync session
  Future<String> startSyncSession(String sessionType) async {
    final sessionId = IdGenerator.generateLocalId();
    await into(syncSessions).insert(SyncSessionsCompanion.insert(
      id: sessionId,
      sessionType: sessionType,
      status: const Value('started'),
    ));
    return sessionId;
  }

  // Update sync session progress
  Future<void> updateSyncSessionProgress(String sessionId, {
    int? totalRecords,
    int? processedRecords,
    int? successfulRecords,
    int? failedRecords,
    int? conflictedRecords,
    String? status,
  }) async {
    final companion = SyncSessionsCompanion(
      totalRecords: totalRecords != null ? Value(totalRecords) : const Value.absent(),
      processedRecords: processedRecords != null ? Value(processedRecords) : const Value.absent(),
      successfulRecords: successfulRecords != null ? Value(successfulRecords) : const Value.absent(),
      failedRecords: failedRecords != null ? Value(failedRecords) : const Value.absent(),
      conflictedRecords: conflictedRecords != null ? Value(conflictedRecords) : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
    );
    
    await (update(syncSessions)..where((s) => s.id.equals(sessionId))).write(companion);
  }

  // Complete sync session
  Future<void> completeSyncSession(String sessionId, String status, {String? summary, String? errors}) async {
    final now = DateTime.now();
    final session = await (select(syncSessions)..where((s) => s.id.equals(sessionId))).getSingle();
    final duration = now.difference(session.startedAt).inSeconds.toDouble();
    
    await (update(syncSessions)..where((s) => s.id.equals(sessionId))).write(SyncSessionsCompanion(
      status: Value(status),
      completedAt: Value(now),
      durationSeconds: Value(duration),
      summary: Value(summary),
      errors: Value(errors),
    ));
  }

  // Add record to sync queue with dependencies
  Future<void> addToSyncQueue(
    String tableName, 
    String localId, 
    String operation, {
    String? syncId,
    Map<String, dynamic>? data,
    List<String>? dependencies,
    int priority = 0,
    String? batchId,
  }) async {
    await into(syncQueue).insert(SyncQueueCompanion.insert(
      recordTable: tableName,
      localId: localId,
      syncId: Value(syncId),
      operation: operation,
      data: Value(data != null ? jsonEncode(data) : null),
      dependencies: Value(dependencies != null ? jsonEncode(dependencies) : null),
      priority: Value(priority),
      batchId: Value(batchId),
    ));
  }

  // Get sync queue items in order
  Future<List<SyncQueueData>> getSyncQueueItems({int? limit}) async {
    var query = select(syncQueue)
      ..where((sq) => sq.status.equals('pending'))
      ..orderBy([
        (sq) => OrderingTerm(expression: sq.priority, mode: OrderingMode.desc),
        (sq) => OrderingTerm(expression: sq.sequenceNumber),
        (sq) => OrderingTerm(expression: sq.scheduledAt),
      ]);
    
    if (limit != null) {
      query = query..limit(limit);
    }
    
    return query.get();
  }

  // Mark sync queue item as processing
  Future<void> markSyncItemAsProcessing(int queueId) async {
    await (update(syncQueue)..where((sq) => sq.id.equals(queueId))).write(SyncQueueCompanion(
      status: const Value('processing'),
      startedAt: Value(DateTime.now()),
    ));
  }

  // Complete sync queue item
  Future<void> completeSyncItem(int queueId, bool success, {String? error, String? errorCode}) async {
    await (update(syncQueue)..where((sq) => sq.id.equals(queueId))).write(SyncQueueCompanion(
      status: Value(success ? 'completed' : 'failed'),
      completedAt: Value(DateTime.now()),
      errorMessage: Value(error),
      errorCode: Value(errorCode),
    ));
  }

  // Create or update sync metadata
  Future<void> updateSyncMetadata(
    String tableName,
    String recordId, {
    String? syncId,
    int? localVersion,
    int? serverVersion,
    String? contentHash,
    String? syncState,
    DateTime? lastModifiedServer,
    bool? hasConflict,
    String? conflictData,
  }) async {
    final existing = await (select(syncMetadata)
      ..where((sm) => sm.recordTable.equals(tableName) & sm.recordId.equals(recordId)))
      .getSingleOrNull();

    if (existing != null) {
      await (update(syncMetadata)..where((sm) => sm.id.equals(existing.id))).write(SyncMetadataCompanion(
        syncId: syncId != null ? Value(syncId) : const Value.absent(),
        localVersion: localVersion != null ? Value(localVersion) : const Value.absent(),
        serverVersion: serverVersion != null ? Value(serverVersion) : const Value.absent(),
        lastKnownHash: contentHash != null ? Value(contentHash) : const Value.absent(),
        syncState: syncState != null ? Value(syncState) : const Value.absent(),
        lastModifiedServer: lastModifiedServer != null ? Value(lastModifiedServer) : const Value.absent(),
        hasConflict: hasConflict != null ? Value(hasConflict) : const Value.absent(),
        conflictData: conflictData != null ? Value(conflictData) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await into(syncMetadata).insert(SyncMetadataCompanion.insert(
        recordTable: tableName,
        recordId: recordId,
        syncId: Value(syncId),
        localVersion: Value(localVersion ?? 1),
        serverVersion: Value(serverVersion ?? 0),
        lastKnownHash: Value(contentHash),
        syncState: Value(syncState ?? 'pending'),
        lastModifiedServer: Value(lastModifiedServer),
        hasConflict: Value(hasConflict ?? false),
        conflictData: Value(conflictData),
      ));
    }
  }

  // Get records with conflicts
  Future<List<SyncMetadataData>> getConflictedRecords() async {
    return (select(syncMetadata)..where((sm) => sm.hasConflict.equals(true))).get();
  }

  // Log changes for audit trail
  Future<void> logChange(
    String tableName,
    String recordId,
    String operation, {
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    List<String>? changedFields,
    String? userId,
    String source = 'local',
  }) async {
    await into(changeLog).insert(ChangeLogCompanion.insert(
      recordTable: tableName,
      recordId: recordId,
      operation: operation,
      oldValues: Value(oldValues != null ? jsonEncode(oldValues) : null),
      newValues: Value(newValues != null ? jsonEncode(newValues) : null),
      changedFields: Value(changedFields != null ? jsonEncode(changedFields) : null),
      userId: Value(userId),
      source: Value(source),
    ));
  }

  // Calculate content hash for conflict detection
  String calculateContentHash(Map<String, dynamic> data) {
    // Remove sync-specific fields for hash calculation
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.removeWhere((key, value) => [
      'id', 'sync_id', 'version', 'content_hash', 'sync_state',
      'last_synced_at', 'created_at', 'updated_at'
    ].contains(key));
    
    final sortedJson = jsonEncode(cleanData);
    return sortedJson.hashCode.toString();
  }

  // Clean up completed sync operations
  Future<void> cleanupSyncData({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    // Clean completed sync queue items
    await (delete(syncQueue)
      ..where((sq) => sq.status.equals('completed') & sq.completedAt.isSmallerThanValue(cutoffDate)))
      .go();
    
    // Clean old sync sessions
    await (delete(syncSessions)
      ..where((ss) => ss.status.equals('completed') & ss.completedAt.isSmallerThanValue(cutoffDate)))
      .go();
    
    // Clean old change logs
    await (delete(changeLog)
      ..where((cl) => cl.timestamp.isSmallerThanValue(cutoffDate)))
      .go();
  }

  // Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final pendingItems = await (selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equals('pending')))
      .getSingle();
    
    final failedItems = await (selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equals('failed')))
      .getSingle();
    
    final conflictedItems = await (selectOnly(syncMetadata)
      ..addColumns([syncMetadata.id.count()])
      ..where(syncMetadata.hasConflict.equals(true)))
      .getSingle();
    
    final lastSession = await (select(syncSessions)
      ..orderBy([(ss) => OrderingTerm.desc(ss.createdAt)])
      ..limit(1))
      .getSingleOrNull();
    
    return {
      'pending_items': pendingItems.read(syncQueue.id.count()) ?? 0,
      'failed_items': failedItems.read(syncQueue.id.count()) ?? 0,
      'conflicted_items': conflictedItems.read(syncMetadata.id.count()) ?? 0,
      'last_sync': lastSession?.createdAt.toIso8601String(),
      'last_sync_status': lastSession?.status,
    };
  }

  // Mark records as synced
  Future<void> markAsSynced(String tableName, String localId, String syncId) async {
    switch (tableName) {
      case 'products':
        await (update(products)..where((p) => p.id.equals(localId)))
            .write(ProductsCompanion(
              syncId: Value(syncId),
              syncState: const Value('synced'),
              lastSyncedAt: Value(DateTime.now()),
            ));
        break;
      case 'sales':
        await (update(sales)..where((s) => s.id.equals(localId)))
            .write(SalesCompanion(
              syncId: Value(syncId),
              syncState: const Value('synced'),
              lastSyncedAt: Value(DateTime.now()),
            ));
        break;
      // Add more cases for other tables as needed
    }
  }
  
  Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final queue = await select(syncQueue).get();
    return queue.map((e) => e.toJson()).toList();
  }

  // ==================== APP SETTINGS ====================
  Future<String?> getSetting(String key) async {
    final setting = await (select(appSettings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return setting?.value;
  }
  
  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(
      key: key,
      value: value,
    ));
  }
}

// Helper class for generating UUIDs and IDs
class IdGenerator {
  static String generateLocalId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
    return '$timestamp$random';
  }
  
  static String generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'device_$timestamp';
  }
  
  static String generateBatchId() {
    return 'batch_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  static String generateReceiptNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'RCP-${timestamp.toString().substring(8)}';
  }
}