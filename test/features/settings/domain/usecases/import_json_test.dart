import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/settings/domain/entities/json_backup.dart';
import 'package:spending_log/features/settings/domain/repositories/backup_restore_repository.dart';
import 'package:spending_log/features/settings/domain/usecases/import_json.dart';

class MockBackupRestoreRepository extends Mock
    implements BackupRestoreRepository {}

void main() {
  late MockBackupRestoreRepository mockRepository;
  late ImportJson useCase;

  setUpAll(() {
    registerFallbackValue(
      const JsonBackupData(
        categories: [],
        expenses: [],
        recurringExpenses: [],
        settings: {},
      ),
    );
  });

  setUp(() {
    mockRepository = MockBackupRestoreRepository();
    useCase = ImportJson(mockRepository);
    when(() => mockRepository.restore(any())).thenAnswer((_) async {});
  });

  test('imports valid JSON backup and returns counts', () async {
    const json = '''
{
  "version": 1,
  "exported_at": "2026-04-22T10:00:00.000Z",
  "categories": [
    {
      "id": 1,
      "name": "Food",
      "parent_id": null,
      "icon_name": "restaurant",
      "color_value": 4283215696,
      "sort_order": 0,
      "created_at": "2026-01-01T00:00:00.000Z"
    }
  ],
  "expenses": [
    {
      "id": "exp-1",
      "amount_cents": 1250,
      "description": "Lunch",
      "category_id": 1,
      "date": "2026-04-20T12:00:00.000Z",
      "notes": "Office",
      "recurring_expense_id": null,
      "created_at": "2026-04-20T12:00:00.000Z",
      "updated_at": "2026-04-20T12:00:00.000Z"
    }
  ],
  "recurring_expenses": [
    {
      "id": "rec-1",
      "name": "Rent",
      "amount_cents": 90000,
      "category_id": 1,
      "interval": "monthly",
      "start_date": "2026-01-01T00:00:00.000Z",
      "last_generated_date": null,
      "is_active": true,
      "created_at": "2026-01-01T00:00:00.000Z",
      "updated_at": "2026-01-01T00:00:00.000Z"
    }
  ],
  "settings": {
    "currency_symbol": "€",
    "biometrics_enabled": false
  }
}
''';

    final result = await useCase(json);

    expect(result.categoryCount, 1);
    expect(result.expenseCount, 1);
    expect(result.recurringCount, 1);
    expect(result.settingsCount, 2);

    final captured =
        verify(() => mockRepository.restore(captureAny())).captured.single
            as JsonBackupData;

    expect(captured.categories.single.isSavings, isFalse);
    expect(captured.settings['biometrics_enabled'], 'false');
  });

  test('throws for unsupported version', () async {
    const json = '''
{
  "version": 2,
  "categories": [],
  "expenses": [],
  "recurring_expenses": [],
  "settings": {}
}
''';

    expect(
      () => useCase(json),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported backup version'),
        ),
      ),
    );
    verifyNever(() => mockRepository.restore(any()));
  });

  test('throws for invalid recurring interval', () async {
    const json = '''
{
  "version": 1,
  "categories": [
    {
      "id": 1,
      "name": "Food",
      "created_at": "2026-01-01T00:00:00.000Z"
    }
  ],
  "expenses": [],
  "recurring_expenses": [
    {
      "id": "rec-1",
      "name": "Invalid",
      "amount_cents": 100,
      "category_id": 1,
      "interval": "fortnightly",
      "start_date": "2026-01-01T00:00:00.000Z",
      "is_active": true,
      "created_at": "2026-01-01T00:00:00.000Z",
      "updated_at": "2026-01-01T00:00:00.000Z"
    }
  ],
  "settings": {}
}
''';

    expect(
      () => useCase(json),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('unsupported value'),
        ),
      ),
    );
    verifyNever(() => mockRepository.restore(any()));
  });

  test('throws for empty json content', () async {
    expect(
      () => useCase('   '),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('empty'),
        ),
      ),
    );
    verifyNever(() => mockRepository.restore(any()));
  });
}
