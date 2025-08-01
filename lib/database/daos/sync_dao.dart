import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_tables.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncMetadata, SyncQueue, ChangeLog])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(AppDatabase db) : super(db);

  // Sync Metadata operations
  Future<List<SyncMetadataData>> getAllSyncMetadata() => select(syncMetadata).get();

  Future<SyncMetadataData?> getSyncMetadata(String tableName, String recordId) =>
    (select(syncMetadata)..where((sm) => 
      sm.recordTable.equals(tableName) & sm.recordId.equals(recordId)))
    .getSingleOrNull();

  Future<List<SyncMetadataData>> getPendingSyncMetadata() =>
    (select(syncMetadata)..where((sm) => sm.syncState.equals('pending'))).get();

  Future<List<SyncMetadataData>> getConflictedMetadata() =>
    (select(syncMetadata)..where((sm) => sm.hasConflict.equals(true))).get();

  Future<void> createOrUpdateSyncMetadata({
    required String tableName,
    required String recordId,
    String? syncId,
    int? localVersion,
    int? serverVersion,
    String? contentHash,
    String? syncState,
    DateTime? lastModifiedServer,
    bool? hasConflict,
    String? conflictData,
  }) async {
    final existing = await getSyncMetadata(tableName, recordId);
    
    if (existing != null) {
      await (update(syncMetadata)..where((sm) => sm.id.equals(existing.id)))
        .write(SyncMetadataCompanion(
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

  // Sync Queue operations
  Future<List<SyncQueueData>> getAllQueueItems() => select(syncQueue).get();

  Future<List<SyncQueueData>> getPendingQueueItems() =>
    (select(syncQueue)..where((sq) => sq.status.equals('pending'))
      ..orderBy([(sq) => OrderingTerm.desc(sq.priority), (sq) => OrderingTerm.asc(sq.createdAt)]))
    .get();

  Future<void> queueForSync({
    required String tableName,
    required String localId,
    required String operation,
    String? syncId,
    String? data,
    int priority = 0,
    String? batchId,
  }) async {
    await into(syncQueue).insert(SyncQueueCompanion.insert(
      recordTable: tableName,
      localId: localId,
      operation: operation,
      syncId: Value(syncId),
      data: Value(data),
      priority: Value(priority),
      batchId: Value(batchId),
    ));
  }

  Future<void> updateQueueItemStatus(int queueId, String status, {String? errorMessage}) =>
    (update(syncQueue)..where((sq) => sq.id.equals(queueId)))
      .write(SyncQueueCompanion(
        status: Value(status),
        errorMessage: errorMessage != null ? Value(errorMessage) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> removeFromQueue(int queueId) =>
    (delete(syncQueue)..where((sq) => sq.id.equals(queueId))).go();

  Future<void> clearCompletedQueueItems() =>
    (delete(syncQueue)..where((sq) => sq.status.equals('completed'))).go();

  // Change Log operations
  Future<List<ChangeLogData>> getAllChangeLogs() => select(changeLog).get();

  Future<List<ChangeLogData>> getChangeLogsByTable(String tableName) =>
    (select(changeLog)..where((cl) => cl.recordTable.equals(tableName))
      ..orderBy([(cl) => OrderingTerm.desc(cl.timestamp)]))
    .get();

  Future<List<ChangeLogData>> getChangeLogsByRecord(String tableName, String recordId) =>
    (select(changeLog)..where((cl) => 
      cl.recordTable.equals(tableName) & cl.recordId.equals(recordId))
      ..orderBy([(cl) => OrderingTerm.desc(cl.timestamp)]))
    .get();

  Future<void> logChange({
    required String tableName,
    required String recordId,
    required String operation,
    String? oldValues,
    String? newValues,
    String? changedFields,
    String? userId,
    String source = 'local',
  }) async {
    await into(changeLog).insert(ChangeLogCompanion.insert(
      recordTable: tableName,
      recordId: recordId,
      operation: operation,
      oldValues: Value(oldValues),
      newValues: Value(newValues),
      changedFields: Value(changedFields),
      userId: Value(userId),
      source: Value(source),
    ));
  }

  // Conflict resolution
  Future<void> resolveConflict(int metadataId, String resolution, {String? mergedData}) async {
    await (update(syncMetadata)..where((sm) => sm.id.equals(metadataId)))
      .write(SyncMetadataCompanion(
        hasConflict: const Value(false),
        conflictResolution: Value(resolution),
        conflictData: mergedData != null ? Value(mergedData) : const Value(null),
        updatedAt: Value(DateTime.now()),
      ));
  }

  // Sync statistics
  Future<SyncStats> getSyncStats() async {
    final pendingCount = await (selectOnly(syncMetadata)
      ..addColumns([syncMetadata.id.count()])
      ..where(syncMetadata.syncState.equals('pending')))
      .getSingle().then((row) => row.read(syncMetadata.id.count()) ?? 0);

    final conflictCount = await (selectOnly(syncMetadata)
      ..addColumns([syncMetadata.id.count()])
      ..where(syncMetadata.hasConflict.equals(true)))
      .getSingle().then((row) => row.read(syncMetadata.id.count()) ?? 0);

    final queueCount = await (selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equals('pending')))
      .getSingle().then((row) => row.read(syncQueue.id.count()) ?? 0);

    return SyncStats(
      pendingRecords: pendingCount,
      conflictedRecords: conflictCount,
      queuedItems: queueCount,
    );
  }

  // Clean up old logs
  Future<void> cleanupOldLogs({Duration retention = const Duration(days: 30)}) async {
    final cutoffDate = DateTime.now().subtract(retention);
    await (delete(changeLog)..where((cl) => cl.timestamp.isSmallerThanValue(cutoffDate))).go();
  }
}

class SyncStats {
  final int pendingRecords;
  final int conflictedRecords;
  final int queuedItems;

  SyncStats({
    required this.pendingRecords,
    required this.conflictedRecords,
    required this.queuedItems,
  });
}
