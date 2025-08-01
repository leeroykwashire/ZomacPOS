import 'package:drift/drift.dart';
import 'syncable_table.dart';

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
