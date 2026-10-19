import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/constants/storage_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../models/contact_snapshot.dart';
import 'storage_service.dart';

class ContactJsonService {
  final StorageService _storageService;

  ContactJsonService(this._storageService);

  /// Loads the active contact snapshot from app-private storage.
  /// Returns null if no snapshot exists yet.
  Future<ContactSnapshot?> loadActiveSnapshot() async {
    await _storageService.initialize();
    final file = _storageService.contactsSnapshotFile;
    if (!await file.exists()) {
      return null;
    }

    try {
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) return null;

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const ContactException('Invalid snapshot format: Root must be a JSON object.');
      }

      return ContactSnapshot.fromJson(decoded);
    } catch (e) {
      debugPrint('Failed to load active contacts snapshot: $e');
      throw ContactException('Failed to read saved contact snapshot: $e', details: e);
    }
  }

  /// Atomically saves the contact snapshot to app-private storage.
  /// Writes to a temporary file first, verifies parsing, and replaces the target file.
  Future<void> saveSnapshotAtomically(ContactSnapshot snapshot) async {
    await _storageService.initialize();
    final tempFile = await _storageService.createTemporaryFile('snapshot', 'json');
    try {
      final jsonMap = snapshot.toJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);

      // Write to staging file
      await tempFile.writeAsString(jsonString, flush: true);

      // Validate staged file
      final readBack = await tempFile.readAsString();
      final verified = jsonDecode(readBack);
      if (verified is! Map<String, dynamic> || verified['contacts'] == null) {
        throw const ContactException('Integrity verification failed for serialized snapshot.');
      }

      // Atomically copy to target snapshot location
      final targetFile = _storageService.contactsSnapshotFile;
      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }

      await tempFile.copy(targetFile.path);
      await tempFile.delete();
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      if (e is ContactException) rethrow;
      throw ContactException('Failed to atomically save contact snapshot: $e', details: e);
    }
  }

  /// Exports the current contact snapshot to user-accessible storage
  /// (e.g. "Ezze Backup/Contacts/Contacts_2026-10-19_211500.json").
  Future<File> exportSnapshotToSharedStorage(ContactSnapshot snapshot) async {
    try {
      final contactsDir = await _storageService.getCategoryExportDir(StorageConstants.contactsFolder);
      final exportFile = await _storageService.generateUniqueExportFile(
        directory: contactsDir,
        prefix: 'Contacts',
        extension: 'json',
      );

      final jsonString = const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
      await exportFile.writeAsString(jsonString, flush: true);
      return exportFile;
    } catch (e) {
      throw ContactException('Failed to export contact JSON to shared storage: $e', details: e);
    }
  }
}
