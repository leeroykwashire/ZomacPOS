import 'package:drift/drift.dart';

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
