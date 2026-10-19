import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_backup/models/backup_manifest.dart';

void main() {
  group('BackupManifest Model Tests', () {
    test('Correctly serializes and deserializes manifest JSON', () {
      final manifest = BackupManifest(
        createdAt: '2026-10-19T21:15:00Z',
        category: 'Documents',
        totalFiles: 2,
        totalInputBytes: 2048,
        entries: const [
          ManifestEntry(
            relativePath: 'Documents/work.pdf',
            originalSizeBytes: 1024,
            modifiedAt: '2026-10-18T10:00:00Z',
          ),
          ManifestEntry(
            relativePath: 'Documents/expenses.xlsx',
            originalSizeBytes: 1024,
            modifiedAt: '2026-10-18T11:00:00Z',
          ),
        ],
      );

      final json = manifest.toJson();
      expect(json['appName'], 'Ezze Backup');
      expect(json['archiveFormatVersion'], 1);
      expect(json['category'], 'Documents');
      expect(json['totalFiles'], 2);

      final deserialized = BackupManifest.fromJson(json);
      expect(deserialized.appName, manifest.appName);
      expect(deserialized.entries.length, 2);
      expect(deserialized.entries.first.relativePath, 'Documents/work.pdf');
    });
  });
}
