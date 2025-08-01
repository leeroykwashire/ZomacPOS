import 'package:drift/drift.dart';
import 'syncable_table.dart';

// Sales items table
class SalesItems extends Table with SyncableTable {
  TextColumn get saleId => text().named('sale_id')();
  TextColumn get productId => text().named('product_id')();
  TextColumn get productName => text().named('product_name')(); // Snapshot at time of sale
  IntColumn get qty => integer()();
  RealColumn get price => real()(); // Price at time of sale
  RealColumn get cost => real().nullable()(); // Cost at time of sale
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get subtotal => real()();
}
