class StorageConstants {
  // Folder Names in App-Private Storage
  static const String appPrivateRootFolder = 'EzzeBackup';
  static const String contactsPrivateFolder = 'contacts';
  static const String databasePrivateFolder = 'database';
  static const String temporaryPrivateFolder = 'temporary';
  static const String logsPrivateFolder = 'logs';

  // Files in App-Private Storage
  static const String contactsSnapshotFileName = 'contacts_snapshot.json';
  static const String contactsMetadataFileName = 'contacts_metadata.json';
  static const String backupHistoryDatabaseName = 'backup_history.db';

  // Folders in User-Accessible Shared Storage
  static const String dedicatedAppFolder = 'EzzeBackUp';
  static const String userAccessibleRootFolder = 'Download/EzzeBackUp';
  static const String filesFolder = 'Files';
  static const String mediaFolder = 'Media';
  static const String contactsFolder = 'Contacts';
  static const String backupLogsFolder = 'Backup_Logs';

  // ZIP Manifest
  static const String zipManifestFileName = 'ezze_backup_manifest.json';
}
