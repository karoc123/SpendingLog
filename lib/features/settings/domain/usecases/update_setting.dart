import '../repositories/settings_repository.dart';

class UpdateSetting {
  final SettingsRepository _repository;

  UpdateSetting(this._repository);

  Future<void> call(String key, String value) {
    return _repository.setSetting(key, value);
  }
}
