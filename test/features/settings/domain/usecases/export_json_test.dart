import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/settings/domain/usecases/export_json.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockExpenseRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockRecurringExpenseRepository mockRecurringRepository;
  late MockSettingsRepository mockSettingsRepository;
  late ExportJson useCase;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockRecurringRepository = MockRecurringExpenseRepository();
    mockSettingsRepository = MockSettingsRepository();
    useCase = ExportJson(
      mockExpenseRepository,
      mockCategoryRepository,
      mockRecurringRepository,
      mockSettingsRepository,
    );
  });

  test('should export valid JSON with all data sections', () async {
    when(
      () => mockExpenseRepository.getAllExpenses(),
    ).thenAnswer((_) async => [makeExpense()]);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [makeCategory()]);
    when(
      () => mockRecurringRepository.getAllRecurringExpenses(),
    ).thenAnswer((_) async => [makeRecurring()]);
    when(
      () => mockSettingsRepository.getAllSettings(),
    ).thenAnswer((_) async => {'currency': 'EUR'});

    final result = await useCase();
    final parsed = jsonDecode(result) as Map<String, dynamic>;

    expect(parsed, containsPair('version', 1));
    expect(parsed, contains('exported_at'));
    expect(parsed['categories'], isList);
    expect(parsed['expenses'], isList);
    expect(parsed['recurring_expenses'], isList);
    expect(parsed['settings'], isA<Map>());

    final categoryJson = (parsed['categories'] as List).first as Map;
    final recurringJson = (parsed['recurring_expenses'] as List).first as Map;
    expect(categoryJson, containsPair('is_savings', false));
    expect(recurringJson, contains('end_date'));
  });

  test('should export savings category flag as true when set', () async {
    when(
      () => mockExpenseRepository.getAllExpenses(),
    ).thenAnswer((_) async => []);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [makeCategory(isSavings: true)]);
    when(
      () => mockRecurringRepository.getAllRecurringExpenses(),
    ).thenAnswer((_) async => []);
    when(
      () => mockSettingsRepository.getAllSettings(),
    ).thenAnswer((_) async => {});

    final result = await useCase();
    final parsed = jsonDecode(result) as Map<String, dynamic>;
    final categoryJson = (parsed['categories'] as List).first as Map;

    expect(categoryJson['is_savings'], isTrue);
  });

  test('should include expense fields in JSON output', () async {
    final expense = makeExpense(
      id: 'test-id',
      amountCents: 1000,
      description: 'Test',
    );
    when(
      () => mockExpenseRepository.getAllExpenses(),
    ).thenAnswer((_) async => [expense]);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRecurringRepository.getAllRecurringExpenses(),
    ).thenAnswer((_) async => []);
    when(
      () => mockSettingsRepository.getAllSettings(),
    ).thenAnswer((_) async => {});

    final result = await useCase();
    final parsed = jsonDecode(result) as Map<String, dynamic>;
    final expenseJson =
        (parsed['expenses'] as List).first as Map<String, dynamic>;

    expect(expenseJson['id'], 'test-id');
    expect(expenseJson['amount_cents'], 1000);
    expect(expenseJson['description'], 'Test');
  });

  test('should handle empty data gracefully', () async {
    when(
      () => mockExpenseRepository.getAllExpenses(),
    ).thenAnswer((_) async => []);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRecurringRepository.getAllRecurringExpenses(),
    ).thenAnswer((_) async => []);
    when(
      () => mockSettingsRepository.getAllSettings(),
    ).thenAnswer((_) async => {});

    final result = await useCase();
    final parsed = jsonDecode(result) as Map<String, dynamic>;

    expect((parsed['expenses'] as List), isEmpty);
    expect((parsed['categories'] as List), isEmpty);
    expect((parsed['recurring_expenses'] as List), isEmpty);
  });
}
