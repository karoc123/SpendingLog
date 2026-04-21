import 'import_csv_monekin.dart';

/// Backward-compatible wrapper for the original CSV importer.
///
/// New code should use [ImportCsvMonekin] directly.
class ImportCsv extends ImportCsvMonekin {
  ImportCsv(super.expenseRepository, super.categoryRepository);
}
