import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/settings/domain/usecases/get_setting.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockSettingsRepository mockRepository;
  late GetSetting useCase;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = GetSetting(mockRepository);
  });

  group('call', () {
    test('should return setting value for given key', () async {
      when(
        () => mockRepository.getSetting('currency'),
      ).thenAnswer((_) async => 'EUR');

      final result = await useCase('currency');

      expect(result, 'EUR');
    });

    test('should return null for non-existent key', () async {
      when(
        () => mockRepository.getSetting('nonexistent'),
      ).thenAnswer((_) async => null);

      final result = await useCase('nonexistent');

      expect(result, isNull);
    });
  });

  group('watch', () {
    test('should return stream of setting value', () {
      when(
        () => mockRepository.watchSetting('theme'),
      ).thenAnswer((_) => Stream.value('dark'));

      expectLater(useCase.watch('theme'), emits('dark'));
    });
  });
}
