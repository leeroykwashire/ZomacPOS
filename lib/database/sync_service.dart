import 'dart:convert';
import 'package:drift/drift.dart';
import 'app_database.dart';

class SyncService {
  final AppDatabase _database;
  
  SyncService(this._database);
  
  // Main sync orchestration method
  Future<void> performSync({bool fullSync = false}) async {
    final sessionId = await _database.startSyncSession(
      fullSync ? 'full_sync' : 'incremental_sync'
    );
    
    try {
      // Step 1: Push local changes to server
      await _pushLocalChanges(sessionId);
      
      // Step 2: Pull server changes
      await _pullServerChanges(sessionId, fullSync);
      
      // Step 3: Complete session
      await _database.completeSyncSession(sessionId, 'completed');
      
      // Step 4: Cleanup old data
      await _database.cleanupSyncData();
      
    } catch (e) {
      await _database.completeSyncSession(
        sessionId, 
        'failed', 
        errors: jsonEncode({'error': e.toString()})
      );
      rethrow;
    }
  }
  
  Future<void> _pushLocalChanges(String sessionId) async {
    final pendingItems = await _database.getSyncQueueItems();
    
    await _database.updateSyncSessionProgress(
      sessionId,
      totalRecords: pendingItems.length,
    );
    
    int processed = 0;
    int successful = 0;
    int failed = 0;
    
    for (final item in pendingItems) {
      try {
        await _database.markSyncItemAsProcessing(item.id);
        
        // Here you would make the actual API call
        // final result = await _apiService.syncRecord(item);
        
        // Simulate successful sync for now
        await _database.completeSyncItem(item.id, true);
        successful++;
        
        // Update local record sync status
        if (item.syncId != null) {
          await _database.markAsSynced(item.recordTable, item.localId, item.syncId!);
        }
        
      } catch (e) {
        await _database.completeSyncItem(
          item.id, 
          false, 
          error: e.toString(),
          errorCode: 'SYNC_ERROR'
        );
        failed++;
      }
      
      processed++;
      await _database.updateSyncSessionProgress(
        sessionId,
        processedRecords: processed,
        successfulRecords: successful,
        failedRecords: failed,
      );
    }
  }
  
  Future<void> _pullServerChanges(String sessionId, bool fullSync) async {
    // Placeholder for actual server sync implementation
    // This would typically:
    // 1. Get server changes since last sync
    // 2. Apply them to local database
    // 3. Handle conflicts appropriately
    
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network call
    
    await _database.updateSyncSessionProgress(
      sessionId,
      processedRecords: 0,
      successfulRecords: 0,
    );
  }
  
  // ignore: unused_element
  Future<void> _processServerChange(Map<String, dynamic> change) async {
    final tableName = change['table'];
    final recordData = change['data'];
    final operation = change['operation']; // create, update, delete
    
    switch (operation) {
      case 'create':
      case 'update':
        await _upsertRecord(tableName, recordData);
        break;
      case 'delete':
        await _deleteRecord(tableName, recordData['id']);
        break;
    }
  }
  
  Future<void> _upsertRecord(String tableName, Map<String, dynamic> data) async {
    // Check for existing record by sync_id
    final syncId = data['id'];
    
    switch (tableName) {
      case 'products':
        final existing = await (_database.select(_database.products)
            ..where((p) => p.syncId.equals(syncId)))
            .getSingleOrNull();
        
        if (existing != null) {
          // Update existing record
          await (_database.update(_database.products)
                ..where((p) => p.id.equals(existing.id)))
              .write(ProductsCompanion(
                name: Value(data['name']),
                price: Value(data['price'].toDouble()),
                qty: Value(data['qty']),
                // ... other fields
                syncState: const Value('synced'),
                lastSyncedAt: Value(DateTime.now()),
              ));
        } else {
          // Create new record
          await _database.into(_database.products).insert(ProductsCompanion.insert(
            id: IdGenerator.generateLocalId(),
            syncId: Value(syncId),
            name: data['name'],
            price: data['price'].toDouble(),
            qty: data['qty'],
            currencyId: data['currency_id'],
            companyId: data['company_id'],
            sku: data['sku'],
            syncState: const Value('synced'),
            lastSyncedAt: Value(DateTime.now()),
            // ... other fields
          ));
        }
        break;
      
      // Add cases for other tables...
    }
  }
  
  Future<void> _deleteRecord(String tableName, String syncId) async {
    switch (tableName) {
      case 'products':
        await (_database.update(_database.products)
              ..where((p) => p.syncId.equals(syncId)))
            .write(ProductsCompanion(
              isDeleted: const Value(true),
              deletedAt: Value(DateTime.now()),
              syncState: const Value('synced'),
            ));
        break;
      
      // Add cases for other tables...
    }
  }
  
  // Queue operations for sync
  Future<void> queueCreate(String tableName, String localId, Map<String, dynamic> data) async {
    await _database.addToSyncQueue(
      tableName,
      localId,
      'create',
      data: data,
    );
  }
  
  Future<void> queueUpdate(String tableName, String localId, String syncId, Map<String, dynamic> data) async {
    await _database.addToSyncQueue(
      tableName,
      localId,
      'update',
      syncId: syncId,
      data: data,
    );
  }
  
  Future<void> queueDelete(String tableName, String localId, String syncId) async {
    await _database.addToSyncQueue(
      tableName,
      localId,
      'delete',
      syncId: syncId,
    );
  }
  
  // Conflict resolution
  Future<void> resolveConflict(int metadataId, String resolution, {Map<String, dynamic>? mergedData}) async {
    final metadata = await (_database.select(_database.syncMetadata)
          ..where((sm) => sm.id.equals(metadataId)))
        .getSingle();
    
    switch (resolution) {
      case 'client_wins':
        // Re-queue the local version for sync
        await queueUpdate(
          metadata.recordTable,
          metadata.recordId,
          metadata.syncId!,
          jsonDecode(metadata.conflictData ?? '{}')
        );
        break;
        
      case 'server_wins':
        // Accept server version (already applied)
        break;
        
      case 'merged':
        if (mergedData != null) {
          await queueUpdate(
            metadata.recordTable,
            metadata.recordId,
            metadata.syncId!,
            mergedData
          );
        }
        break;
    }
    
    // Clear conflict flag
    await (_database.update(_database.syncMetadata)
          ..where((sm) => sm.id.equals(metadataId)))
        .write(SyncMetadataCompanion(
          hasConflict: const Value(false),
          conflictResolution: Value(resolution),
          conflictData: const Value(null),
        ));
  }
}