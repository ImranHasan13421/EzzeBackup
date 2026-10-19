import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backup_history_service.dart';
import 'contact_json_service.dart';
import 'contact_service.dart';
import 'contact_sync_service.dart';
import 'pdf_service.dart';
import 'storage_service.dart';
import 'zip_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final backupHistoryServiceProvider = Provider<BackupHistoryService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return BackupHistoryService(storage);
});

final zipServiceProvider = Provider<ZipService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ZipService(storage);
});

final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

final contactJsonServiceProvider = Provider<ContactJsonService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ContactJsonService(storage);
});

final contactSyncServiceProvider = Provider<ContactSyncService>((ref) {
  final contacts = ref.watch(contactServiceProvider);
  final json = ref.watch(contactJsonServiceProvider);
  final history = ref.watch(backupHistoryServiceProvider);
  return ContactSyncService(
    contactService: contacts,
    jsonService: json,
    historyService: history,
  );
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final history = ref.watch(backupHistoryServiceProvider);
  return PdfService(
    storageService: storage,
    historyService: history,
  );
});
