abstract class SettingsRepository {
  Future<String?> getSetting(String key);
  Stream<String?> watchSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<Map<String, String>> getAllSettings();
}
