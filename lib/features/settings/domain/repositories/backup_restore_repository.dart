import '../entities/json_backup.dart';

abstract class BackupRestoreRepository {
  Future<void> restore(JsonBackupData data);
}
