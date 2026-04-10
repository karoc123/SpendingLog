import '../repositories/settings_repository.dart';

class GetSetting {
  final SettingsRepository _repository;

  GetSetting(this._repository);

  Future<String?> call(String key) {
    return _repository.getSetting(key);
  }

  Stream<String?> watch(String key) {
    return _repository.watchSetting(key);
  }
}
