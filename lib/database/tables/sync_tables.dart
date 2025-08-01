import 'package:drift/drift.dart';

// Sync metadata table
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
