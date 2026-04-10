import '../../../../core/database/app_database.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _db;

  SettingsRepositoryImpl(this._db);

  @override
  Future<String?> getSetting(String key) => _db.getSetting(key);

  @override
  Stream<String?> watchSetting(String key) => _db.watchSetting(key);

  @override
  Future<void> setSetting(String key, String value) =>
      _db.setSetting(key, value);

  @override
  Future<Map<String, String>> getAllSettings() async {
    final rows = await _db.getAllSettings();
    return {for (final r in rows) r.key: r.value};
  }
}
