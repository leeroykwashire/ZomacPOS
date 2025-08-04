import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/sync_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final database = ref.watch(databaseProvider);
  return SyncService(database);
});

final syncStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.getSyncStats();
});
