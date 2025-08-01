import 'package:drift/drift.dart';
import 'syncable_table.dart';

// Products table
class Products extends Table with SyncableTable {
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  RealColumn get price => real()();
  RealColumn get cost => real().nullable()();
  IntColumn get qty => integer().withDefault(const Constant(0))();
  IntColumn get minQty => integer().withDefault(const Constant(0)).named('min_qty')();
  BoolColumn get trackStock => boolean().withDefault(const Constant(true)).named('track_stock')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
  TextColumn get imageUrl => text().nullable().named('image_url')();
  TextColumn get categoryId => text().nullable().named('category_id')();
  TextColumn get currencyId => text().named('currency_id')();
  TextColumn get companyId => text().named('company_id')();
  RealColumn get taxRate => real().withDefault(const Constant(0.0)).named('tax_rate')();
}
