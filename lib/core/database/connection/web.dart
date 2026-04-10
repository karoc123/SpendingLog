import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor connect() {
  return WebDatabase('spending_log');
}

QueryExecutor connectInMemory() {
  return WebDatabase.withStorage(DriftWebStorage.volatile());
}
