import 'package:drift/drift.dart';
import 'syncable_table.dart';

// Companies table - matches Laravel schema
class Companies extends Table with SyncableTable {
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get postalCode => text().nullable().named('postal_code')();
  TextColumn get taxNumber => text().nullable().named('tax_number')();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get timezone => text().withDefault(const Constant('UTC'))();
  TextColumn get logoUrl => text().nullable().named('logo_url')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
}
