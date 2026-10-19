import 'package:ezze_backup/core/constants/storage_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageConstants & Dedicated Download Folder Tests', () {
    test('Dedicated app folder is named EzzeBackUp in Download directory', () {
      expect(StorageConstants.dedicatedAppFolder, 'EzzeBackUp');
      expect(StorageConstants.userAccessibleRootFolder, 'Download/EzzeBackUp');
    });

    test('Category names match expected backup types', () {
      expect(StorageConstants.filesFolder, 'Files');
      expect(StorageConstants.contactsFolder, 'Contacts');
      expect(StorageConstants.mediaFolder, 'Media');
    });
  });
}
