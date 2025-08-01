import 'package:drift/drift.dart';

// Cart table for temporary storage
class Carts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productId => text().named('product_id')();
  TextColumn get productName => text().named('product_name')();
  IntColumn get qty => integer()();
  RealColumn get price => real()();
  RealColumn get subtotal => real()();
  TextColumn get sessionId => text().named('session_id')(); // For multi-user support
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();
}
