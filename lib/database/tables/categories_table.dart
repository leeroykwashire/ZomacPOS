import 'package:drift/drift.dart';
import 'syncable_table.dart';

// Categories table
class Categories extends Table with SyncableTable {
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get parentId => text().nullable().named('parent_id')();
  TextColumn get companyId => text().named('company_id')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
  IntColumn get sortOrder => integer().withDefault(const Constant(0)).named('sort_order')();
}
