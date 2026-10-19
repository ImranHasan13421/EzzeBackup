import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../core/constants/storage_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../models/backup_manifest.dart';
import 'storage_service.dart';

class ZipItem {
  final File file;
  final String relativePath;

  const ZipItem({required this.file, required this.relativePath});
}

class ZipService {
  final StorageService _storageService;

  ZipService(this._storageService);

  /// Validates that a relative path does not attempt path traversal
  static String sanitizeRelativePath(String path) {
    var normalized = path.replaceAll('\\', '/');
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    final segments = normalized.split('/');
    if (segments.any((s) => s == '..')) {
      throw ZipException('Invalid path detected: path traversal attempt ($path)');
    }
    return segments.where((s) => s.isNotEmpty && s != '.').join('/');
  }

  /// Creates a ZIP archive containing the provided items and an embedded manifest.
  /// Reports progress via [onProgress].
  /// Writes initially to temporary storage, verifies the archive, and moves to [destinationFile].
  Future<int> createZipArchive({
    required List<ZipItem> items,
    required String category,
    required File destinationFile,
    void Function(int processed, int total, String currentName)? onProgress,
  }) async {
    if (items.isEmpty) {
      throw const ZipException('Cannot create empty ZIP archive. No files provided.');
    }

    final tempFile = await _storageService.createTemporaryFile(category, 'zip');
    final archive = Archive();
    final manifestEntries = <ManifestEntry>[];
    int totalInputBytes = 0;

    try {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final cleanRelativePath = sanitizeRelativePath(item.relativePath);
        onProgress?.call(i + 1, items.length, p.basename(item.file.path));

        if (!await item.file.exists()) {
          debugPrint('Skipping missing file: ${item.file.path}');
          continue;
        }

        final bytes = await item.file.readAsBytes();
        final stat = await item.file.stat();
        totalInputBytes += bytes.length;

        archive.addFile(
          ArchiveFile(cleanRelativePath, bytes.length, bytes)
            ..lastModTime = stat.modified.millisecondsSinceEpoch ~/ 1000,
        );

        manifestEntries.add(
          ManifestEntry(
            relativePath: cleanRelativePath,
            originalSizeBytes: bytes.length,
            modifiedAt: stat.modified.toIso8601String(),
          ),
        );
      }

      // Add ezze_backup_manifest.json
      final manifest = BackupManifest(
        createdAt: DateTime.now().toIso8601String(),
        category: category,
        totalFiles: manifestEntries.length,
        totalInputBytes: totalInputBytes,
        entries: manifestEntries,
      );

      final manifestJson = jsonEncode(manifest.toJson());
      final manifestBytes = utf8.encode(manifestJson);
      archive.addFile(
        ArchiveFile(StorageConstants.zipManifestFileName, manifestBytes.length, manifestBytes),
      );

      // Encode archive
      final encoder = ZipEncoder();
      final encodedBytes = encoder.encode(archive);

      // Write to staging temporary file
      await tempFile.writeAsBytes(encodedBytes, flush: true);

      // Verify the resulting ZIP file
      await verifyZipArchive(tempFile, expectedMinFiles: manifestEntries.length);

      // Ensure destination directory exists
      if (!await destinationFile.parent.exists()) {
        await destinationFile.parent.create(recursive: true);
      }

      // Move verified temporary archive to destination
      await tempFile.copy(destinationFile.path);
      await tempFile.delete();

      final outputLength = await destinationFile.length();
      return outputLength;
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      if (e is ZipException) rethrow;
      throw ZipException('Failed to generate ZIP archive: $e', details: e);
    }
  }

  /// Verifies that a ZIP file is valid and readable
  Future<void> verifyZipArchive(File zipFile, {int expectedMinFiles = 1}) async {
    if (!await zipFile.exists()) {
      throw const ZipException('Verification failed: ZIP file does not exist.');
    }
    final bytes = await zipFile.readAsBytes();
    if (bytes.length < 22) {
      throw const ZipException('Verification failed: ZIP file is truncated or empty.');
    }

    try {
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(bytes, verify: true);
      if (archive.isEmpty) {
        throw const ZipException('Verification failed: ZIP archive contains no entries.');
      }

      // Check for manifest
      final hasManifest = archive.any((f) => f.name == StorageConstants.zipManifestFileName);
      if (!hasManifest) {
        debugPrint('Warning: ZIP archive does not contain ${StorageConstants.zipManifestFileName}');
      }
    } catch (e) {
      throw ZipException('Verification failed: Corrupted ZIP structure ($e)');
    }
  }
}
