import 'package:drift/drift.dart';
import 'syncable_table.dart';

// Currencies table
class Currencies extends Table with SyncableTable {
  TextColumn get name => text()();
  TextColumn get code => text().unique()(); // USD, EUR, etc.
  TextColumn get symbol => text()(); // $, €, etc.
  RealColumn get rate => real().withDefault(const Constant(1.0))(); // Exchange rate to base currency
  BoolColumn get isDefault => boolean().withDefault(const Constant(false)).named('is_default')();
  TextColumn get companyId => text().named('company_id')();
}

// Expenses table
class Expenses extends Table with SyncableTable {
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash')).named('payment_method')();
  TextColumn get receipt => text().nullable()(); // Receipt number or reference
  TextColumn get notes => text().nullable()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get companyId => text().named('company_id')();
  DateTimeColumn get expenseDate => dateTime().withDefault(currentDateAndTime).named('expense_date')();
}

// Customers table
class Customers extends Table with SyncableTable {
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get postalCode => text().nullable().named('postal_code')();
  DateTimeColumn get birthDate => dateTime().nullable().named('birth_date')();
  TextColumn get notes => text().nullable()();
  TextColumn get companyId => text().named('company_id')();
  RealColumn get totalPurchases => real().withDefault(const Constant(0.0)).named('total_purchases')();
  DateTimeColumn get lastPurchase => dateTime().nullable().named('last_purchase')();
}

// Suppliers table
class Suppliers extends Table with SyncableTable {
  TextColumn get name => text()();
  TextColumn get contactPerson => text().nullable().named('contact_person')();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get postalCode => text().nullable().named('postal_code')();
  TextColumn get taxNumber => text().nullable().named('tax_number')();
  TextColumn get notes => text().nullable()();
  TextColumn get companyId => text().named('company_id')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
}

// App settings table
class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at')();
}
