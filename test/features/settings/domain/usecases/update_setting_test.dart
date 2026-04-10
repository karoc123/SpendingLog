import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/settings/domain/usecases/update_setting.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockSettingsRepository mockRepository;
  late UpdateSetting useCase;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = UpdateSetting(mockRepository);
  });

  test('should call repository.setSetting with key and value', () async {
    when(
      () => mockRepository.setSetting('currency', 'USD'),
    ).thenAnswer((_) async {});

    await useCase('currency', 'USD');

    verify(() => mockRepository.setSetting('currency', 'USD')).called(1);
  });
}
