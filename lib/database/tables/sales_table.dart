import 'package:drift/drift.dart';
import 'syncable_table.dart';

// Sales table
class Sales extends Table with SyncableTable {
  TextColumn get receiptNumber => text().unique().named('receipt_number')();
  RealColumn get subtotal => real()();
  RealColumn get tax => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real()();
  RealColumn get amountPaid => real().withDefault(const Constant(0.0)).named('amount_paid')();
  RealColumn get change => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('completed'))(); // completed, pending, cancelled, refunded
  TextColumn get paymentMethod => text().withDefault(const Constant('cash')).named('payment_method')();
  TextColumn get notes => text().nullable()();
  TextColumn get cashierId => text().named('cashier_id')();
  TextColumn get customerId => text().nullable().named('customer_id')();
  TextColumn get companyId => text().named('company_id')();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime).named('sale_date')();
}
