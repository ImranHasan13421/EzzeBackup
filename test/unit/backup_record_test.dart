import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_backup/models/backup_record.dart';

void main() {
  group('BackupRecord Model Tests', () {
    test('Serializes to and from SQLite map correctly', () {
      final now = DateTime.now();
      final record = BackupRecord(
        id: 42,
        backupType: BackupType.file,
        category: 'Documents',
        createdAt: now,
        completedAt: now,
        destination: '/storage/emulated/0/Ezze Backup/Files/Doc.zip',
        filename: 'Doc.zip',
        itemCount: 5,
        inputSize: 5000,
        outputSize: 3200,
        status: BackupStatus.completed,
      );

      final map = record.toMap();
      expect(map['id'], 42);
      expect(map['backup_type'], 'file');
      expect(map['status'], 'Completed');

      final fromMap = BackupRecord.fromMap(map);
      expect(fromMap.id, 42);
      expect(fromMap.backupType, 'file');
      expect(fromMap.filename, 'Doc.zip');
      expect(fromMap.itemCount, 5);
      expect(fromMap.outputSize, 3200);
    });

    test('copyWith updates specified fields only', () {
      final record = BackupRecord(
        backupType: BackupType.contactPdf,
        category: 'Contacts',
        createdAt: DateTime.now(),
        destination: '/path/file.pdf',
        filename: 'file.pdf',
        itemCount: 10,
        inputSize: 1000,
        outputSize: 1500,
        status: BackupStatus.inProgress,
      );

      final updated = record.copyWith(status: BackupStatus.completed);
      expect(updated.status, BackupStatus.completed);
      expect(updated.filename, record.filename);
      expect(updated.itemCount, record.itemCount);
    });
  });
}
