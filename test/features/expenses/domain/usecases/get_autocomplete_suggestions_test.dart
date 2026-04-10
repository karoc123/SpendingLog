import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/expenses/domain/entities/autocomplete_suggestion.dart';
import 'package:spending_log/features/expenses/domain/usecases/get_autocomplete_suggestions.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockRepository;
  late GetAutocompleteSuggestions useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = GetAutocompleteSuggestions(mockRepository);
  });

  test(
    'should return suggestions from repository for non-empty query',
    () async {
      const suggestions = [
        AutocompleteSuggestion(
          description: 'Coffee',
          categoryId: 1,
          amountCents: 350,
          frequency: 5,
        ),
      ];
      when(
        () => mockRepository.getAutocompleteSuggestions('Cof'),
      ).thenAnswer((_) async => suggestions);

      final result = await useCase('Cof');

      expect(result, suggestions);
      verify(() => mockRepository.getAutocompleteSuggestions('Cof')).called(1);
    },
  );

  test('should return empty list for empty query', () async {
    final result = await useCase('');

    expect(result, isEmpty);
    verifyNever(() => mockRepository.getAutocompleteSuggestions(any()));
  });

  test('should return empty list for whitespace-only query', () async {
    final result = await useCase('   ');

    expect(result, isEmpty);
    verifyNever(() => mockRepository.getAutocompleteSuggestions(any()));
  });

  test('should trim query before passing to repository', () async {
    when(
      () => mockRepository.getAutocompleteSuggestions('test'),
    ).thenAnswer((_) async => []);

    await useCase('  test  ');

    verify(() => mockRepository.getAutocompleteSuggestions('test')).called(1);
  });
}
