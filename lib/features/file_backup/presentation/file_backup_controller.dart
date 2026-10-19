import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/storage_constants.dart';
import '../../../models/backup_record.dart';
import '../../../services/service_providers.dart';
import '../../../services/zip_service.dart';
import '../../backup_history/presentation/backup_history_controller.dart';

class FileBackupCategory {
  static const String documents = 'Documents';
  static const String images = 'Images';
  static const String videos = 'Videos';
  static const String audio = 'Audio';
  static const String other = 'Other';
  static const String custom = 'Custom';
}

class SelectedFileInfo {
  final String path;
  final String name;
  final int size;
  final String relativePath;

  const SelectedFileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.relativePath,
  });
}

class FileBackupProgress {
  final int processedCount;
  final int totalCount;
  final String currentFileName;

  const FileBackupProgress({
    this.processedCount = 0,
    this.totalCount = 0,
    this.currentFileName = '',
  });

  double get percentage =>
      totalCount > 0 ? (processedCount / totalCount).clamp(0.0, 1.0) : 0.0;
}

class FileBackupState {
  final String selectedCategory;
  final List<SelectedFileInfo> selectedFiles;
  final bool isSelecting;
  final bool isBackingUp;
  final FileBackupProgress progress;
  final BackupRecord? lastCompletedRecord;
  final String? errorMessage;
  final String? successMessage;

  const FileBackupState({
    this.selectedCategory = FileBackupCategory.documents,
    this.selectedFiles = const [],
    this.isSelecting = false,
    this.isBackingUp = false,
    this.progress = const FileBackupProgress(),
    this.lastCompletedRecord,
    this.errorMessage,
    this.successMessage,
  });

  int get totalInputBytes =>
      selectedFiles.fold(0, (sum, f) => sum + f.size);

  FileBackupState copyWith({
    String? selectedCategory,
    List<SelectedFileInfo>? selectedFiles,
    bool? isSelecting,
    bool? isBackingUp,
    FileBackupProgress? progress,
    BackupRecord? lastCompletedRecord,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return FileBackupState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      isSelecting: isSelecting ?? this.isSelecting,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      progress: progress ?? this.progress,
      lastCompletedRecord: lastCompletedRecord ?? this.lastCompletedRecord,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class FileBackupNotifier extends StateNotifier<FileBackupState> {
  final Ref _ref;

  FileBackupNotifier(this._ref) : super(const FileBackupState());

  void selectCategory(String category) {
    state = state.copyWith(
      selectedCategory: category,
      clearMessages: true,
    );
  }

  /// Opens system picker based on active category
  Future<void> pickFilesForCategory() async {
    state = state.copyWith(isSelecting: true, clearMessages: true);

    try {
      List<PlatformFile> pickedFiles = const [];
      switch (state.selectedCategory) {
        case FileBackupCategory.documents:
          pickedFiles = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: [
              'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
              'txt', 'csv', 'rtf', 'odt', 'ods', 'odp'
            ],
          );
          break;
        case FileBackupCategory.images:
          pickedFiles = await FilePicker.pickFiles(
            type: FileType.image,
          );
          break;
        case FileBackupCategory.videos:
          pickedFiles = await FilePicker.pickFiles(
            type: FileType.video,
          );
          break;
        case FileBackupCategory.audio:
          pickedFiles = await FilePicker.pickFiles(
            type: FileType.audio,
          );
          break;
        case FileBackupCategory.other:
        case FileBackupCategory.custom:
        default:
          pickedFiles = await FilePicker.pickFiles(
            type: FileType.any,
          );
          break;
      }

      if (pickedFiles.isNotEmpty) {
        final categorySubfolder = state.selectedCategory;
        final newItems = <SelectedFileInfo>[];

        for (final file in pickedFiles) {
          if (file.path != null) {
            final ioFile = File(file.path!);
            final fileSize = ioFile.existsSync() ? ioFile.lengthSync() : 0;
            newItems.add(
              SelectedFileInfo(
                path: file.path!,
                name: file.name,
                size: fileSize,
                relativePath: '$categorySubfolder/${file.name}',
              ),
            );
          }
        }

        state = state.copyWith(
          isSelecting: false,
          selectedFiles: newItems,
          successMessage: 'Selected ${newItems.length} files.',
        );
      } else {
        state = state.copyWith(isSelecting: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSelecting: false,
        errorMessage: 'Failed to pick files: $e',
      );
    }
  }

  /// Lets user pick an entire folder and recursively indexes files
  Future<void> pickFolder() async {
    state = state.copyWith(isSelecting: true, clearMessages: true);
    try {
      final folderPath = await FilePicker.getDirectoryPath();
      if (folderPath != null) {
        final dir = Directory(folderPath);
        final entities = dir.listSync(recursive: true);
        final folderItems = <SelectedFileInfo>[];
        final folderName = p.basename(folderPath);

        for (final entity in entities) {
          if (entity is File) {
            final rel = p.relative(entity.path, from: dir.parent.path);
            final stat = entity.statSync();
            folderItems.add(
              SelectedFileInfo(
                path: entity.path,
                name: p.basename(entity.path),
                size: stat.size,
                relativePath: rel,
              ),
            );
          }
        }

        state = state.copyWith(
          isSelecting: false,
          selectedCategory: folderName,
          selectedFiles: folderItems,
          successMessage: 'Loaded ${folderItems.length} files from $folderName.',
        );
      } else {
        state = state.copyWith(isSelecting: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSelecting: false,
        errorMessage: 'Failed to read directory: $e',
      );
    }
  }

  void removeFile(SelectedFileInfo file) {
    final updated = state.selectedFiles.where((f) => f.path != file.path).toList();
    state = state.copyWith(selectedFiles: updated);
  }

  void clearSelection() {
    state = state.copyWith(selectedFiles: const []);
  }

  /// Executes ZIP creation, verification, and history recording
  Future<BackupRecord?> executeBackup([BuildContext? context]) async {
    if (state.selectedFiles.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select files to back up.');
      return null;
    }

    if (context != null) {
      final permService = _ref.read(permissionServiceProvider);
      final hasPerm = await permService.ensureStoragePermission(context);
      if (!hasPerm) {
        state = state.copyWith(
          errorMessage: 'Storage permission is required to save backups into Download/EzzeBackUp.',
        );
        return null;
      }
    }

    state = state.copyWith(
      isBackingUp: true,
      clearMessages: true,
      progress: FileBackupProgress(
        processedCount: 0,
        totalCount: state.selectedFiles.length,
        currentFileName: 'Preparing...',
      ),
    );

    final storage = _ref.read(storageServiceProvider);
    final zipService = _ref.read(zipServiceProvider);
    final historyService = _ref.read(backupHistoryServiceProvider);

    final category = state.selectedCategory;
    final isMedia = (category == FileBackupCategory.images ||
        category == FileBackupCategory.videos ||
        category == FileBackupCategory.audio);

    final targetSubfolder = isMedia ? StorageConstants.mediaFolder : StorageConstants.filesFolder;

    try {
      final exportDir = await storage.getCategoryExportDir(targetSubfolder);
      final destFile = await storage.generateUniqueExportFile(
        directory: exportDir,
        prefix: category,
        extension: 'zip',
      );

      final zipItems = state.selectedFiles.map((f) {
        return ZipItem(file: File(f.path), relativePath: f.relativePath);
      }).toList();

      final outputBytes = await zipService.createZipArchive(
        items: zipItems,
        category: category,
        destinationFile: destFile,
        onProgress: (processed, total, current) {
          state = state.copyWith(
            progress: FileBackupProgress(
              processedCount: processed,
              totalCount: total,
              currentFileName: current,
            ),
          );
        },
      );

      final record = BackupRecord(
        backupType: BackupType.file,
        category: category,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        destination: destFile.path,
        filename: p.basename(destFile.path),
        itemCount: state.selectedFiles.length,
        inputSize: state.totalInputBytes,
        outputSize: outputBytes,
        status: BackupStatus.completed,
      );

      await historyService.insertRecord(record);
      _ref.read(backupHistoryProvider.notifier).loadHistory();

      state = state.copyWith(
        isBackingUp: false,
        selectedFiles: const [],
        lastCompletedRecord: record,
        successMessage: 'Backup completed: ${record.filename}',
      );

      return record;
    } catch (e) {
      state = state.copyWith(
        isBackingUp: false,
        errorMessage: 'Backup failed: $e',
      );
      return null;
    }
  }
}

final fileBackupProvider =
    StateNotifierProvider<FileBackupNotifier, FileBackupState>((ref) {
  return FileBackupNotifier(ref);
});
