import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/storage_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../core/utils/date_formatter.dart';

class StorageService {
  Directory? _appPrivateDir;
  Directory? _contactsPrivateDir;
  Directory? _databasePrivateDir;
  Directory? _temporaryPrivateDir;
  Directory? _logsPrivateDir;

  /// Initializes the app-private working directory hierarchy
  Future<void> initialize() async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      _appPrivateDir = Directory(p.join(baseDir.path, StorageConstants.appPrivateRootFolder));
      if (!await _appPrivateDir!.exists()) {
        await _appPrivateDir!.create(recursive: true);
      }

      _contactsPrivateDir = Directory(p.join(_appPrivateDir!.path, StorageConstants.contactsPrivateFolder));
      if (!await _contactsPrivateDir!.exists()) {
        await _contactsPrivateDir!.create(recursive: true);
      }

      _databasePrivateDir = Directory(p.join(_appPrivateDir!.path, StorageConstants.databasePrivateFolder));
      if (!await _databasePrivateDir!.exists()) {
        await _databasePrivateDir!.create(recursive: true);
      }

      _temporaryPrivateDir = Directory(p.join(_appPrivateDir!.path, StorageConstants.temporaryPrivateFolder));
      if (!await _temporaryPrivateDir!.exists()) {
        await _temporaryPrivateDir!.create(recursive: true);
      }

      _logsPrivateDir = Directory(p.join(_appPrivateDir!.path, StorageConstants.logsPrivateFolder));
      if (!await _logsPrivateDir!.exists()) {
        await _logsPrivateDir!.create(recursive: true);
      }

      // Cleanup leftover temporary files from prior interrupted runs
      await cleanTemporaryFiles();
    } catch (e) {
      debugPrint('Failed to initialize StorageService: $e');
      throw StorageException('Could not initialize app-private storage: $e');
    }
  }

  Directory get appPrivateDir => _appPrivateDir!;
  Directory get contactsPrivateDir => _contactsPrivateDir!;
  Directory get databasePrivateDir => _databasePrivateDir!;
  Directory get temporaryPrivateDir => _temporaryPrivateDir!;
  Directory get logsPrivateDir => _logsPrivateDir!;

  File get contactsSnapshotFile =>
      File(p.join(contactsPrivateDir.path, StorageConstants.contactsSnapshotFileName));

  File get contactsMetadataFile =>
      File(p.join(contactsPrivateDir.path, StorageConstants.contactsMetadataFileName));

  File get backupHistoryDbFile =>
      File(p.join(databasePrivateDir.path, StorageConstants.backupHistoryDatabaseName));

  /// Resolves the user-accessible backup root folder.
  /// Checks user-configured custom destination first.
  /// If not set, checks common Android shared storage path or falls back to app-accessible external files directory.
  Future<Directory> getUserAccessibleBackupDir() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(AppConstants.prefCustomBackupPath);

    if (customPath != null && customPath.trim().isNotEmpty) {
      final customDir = Directory(customPath);
      if (await customDir.exists()) {
        return customDir;
      }
    }

    // Default location on Android / desktop
    try {
      if (Platform.isAndroid) {
        // Attempt standard shared storage "/storage/emulated/0/Ezze Backup"
        const standardShared = '/storage/emulated/0/${StorageConstants.userAccessibleRootFolder}';
        final sharedDir = Directory(standardShared);
        try {
          if (!await sharedDir.exists()) {
            await sharedDir.create(recursive: true);
          }
          return sharedDir;
        } catch (_) {
          // Scoped storage fallback: getExternalStorageDirectory()
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            final fallback = Directory(p.join(ext.path, StorageConstants.userAccessibleRootFolder));
            if (!await fallback.exists()) {
              await fallback.create(recursive: true);
            }
            return fallback;
          }
        }
      }

      // For desktop / other platforms: Downloads or Documents
      Directory? target;
      try {
        target = await getDownloadsDirectory();
      } catch (_) {}
      target ??= await getApplicationDocumentsDirectory();

      final sharedDir = Directory(p.join(target.path, StorageConstants.userAccessibleRootFolder));
      if (!await sharedDir.exists()) {
        await sharedDir.create(recursive: true);
      }
      return sharedDir;
    } catch (e) {
      debugPrint('Error getting shared backup directory: $e');
      return appPrivateDir;
    }
  }

  /// Resolves subcategory directory in user-accessible storage
  /// (e.g. "Files", "Media", "Contacts", "Backup_Logs")
  Future<Directory> getCategoryExportDir(String subfolder) async {
    final root = await getUserAccessibleBackupDir();
    final subDir = Directory(p.join(root.path, subfolder));
    if (!await subDir.exists()) {
      await subDir.create(recursive: true);
    }
    return subDir;
  }

  /// Generates a uniquely named, non-colliding file path with timestamp.
  /// E.g. "Documents_2026-10-19_211500.zip".
  /// If file already exists, appends "_1", "_2" to prevent silent overwriting.
  Future<File> generateUniqueExportFile({
    required Directory directory,
    required String prefix,
    required String extension,
    DateTime? timestamp,
  }) async {
    final dateStr = DateFormatter.formatFileTimestamp(timestamp ?? DateTime.now());
    final ext = extension.startsWith('.') ? extension : '.$extension';
    final baseName = '${prefix}_$dateStr';

    String candidatePath = p.join(directory.path, '$baseName$ext');
    File candidateFile = File(candidatePath);

    int sequence = 1;
    while (await candidateFile.exists()) {
      candidatePath = p.join(directory.path, '${baseName}_$sequence$ext');
      candidateFile = File(candidatePath);
      sequence++;
    }

    return candidateFile;
  }

  /// Creates a temporary file in the sandboxed temporary directory
  Future<File> createTemporaryFile(String prefix, String extension) async {
    final dateStr = DateFormatter.formatFileTimestamp(DateTime.now());
    final ext = extension.startsWith('.') ? extension : '.$extension';
    final tempPath = p.join(temporaryPrivateDir.path, 'tmp_${prefix}_${dateStr}_${DateTime.now().microsecond}$ext');
    return File(tempPath);
  }

  /// Deletes all leftover temporary files in `temporary/`
  Future<void> cleanTemporaryFiles() async {
    try {
      if (_temporaryPrivateDir != null && await _temporaryPrivateDir!.exists()) {
        final entities = _temporaryPrivateDir!.listSync();
        for (final entity in entities) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Could not clean temporary files: $e');
    }
  }

  /// Sets a custom user backup directory
  Future<void> setCustomBackupPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(AppConstants.prefCustomBackupPath);
    } else {
      await prefs.setString(AppConstants.prefCustomBackupPath, path);
    }
  }

  /// Returns current custom backup path if any
  Future<String?> getCustomBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefCustomBackupPath);
  }
}
