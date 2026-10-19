import '../core/constants/storage_constants.dart';
import '../models/backup_record.dart';
import '../models/contact_record.dart';
import '../models/contact_snapshot.dart';
import 'backup_history_service.dart';
import 'contact_json_service.dart';
import 'contact_service.dart';

class ContactSyncService {
  final ContactService _contactService;
  final ContactJsonService _jsonService;
  final BackupHistoryService _historyService;

  ContactSyncService({
    required ContactService contactService,
    required ContactJsonService jsonService,
    required BackupHistoryService historyService,
  })  : _contactService = contactService,
        _jsonService = jsonService,
        _historyService = historyService;

  /// Performs full on-demand contact synchronization and reconciliation.
  /// Detects new contacts, updated contacts, and missing contacts.
  /// Preserves all historical records without silent deletion.
  Future<ContactReconciliationResult> synchronizeContacts() async {
    final freshContacts = await _contactService.fetchDeviceContacts();
    final previousSnapshot = await _jsonService.loadActiveSnapshot();
    final nowIso = DateTime.now().toIso8601String();

    if (previousSnapshot == null) {
      // First Backup
      final snapshot = ContactSnapshot(
        createdAt: nowIso,
        updatedAt: nowIso,
        lastSuccessfulSyncAt: nowIso,
        contactCount: freshContacts.length,
        contacts: freshContacts,
        removedContacts: const [],
      );

      await _jsonService.saveSnapshotAtomically(snapshot);

      // Record in history
      await _historyService.insertRecord(
        BackupRecord(
          backupType: BackupType.contactJson,
          category: 'Contacts',
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
          destination: 'App-Private Storage',
          filename: StorageConstants.contactsSnapshotFileName,
          itemCount: freshContacts.length,
          inputSize: freshContacts.length * 150,
          outputSize: snapshot.contacts.length * 150,
          status: BackupStatus.completed,
          errorSummary: null,
        ),
      );

      return ContactReconciliationResult(
        currentAvailableCount: freshContacts.length,
        newContactsCount: freshContacts.length,
        updatedContactsCount: 0,
        noLongerFoundCount: 0,
        isUpToDate: false,
        summaryMessage: 'Initial contact backup created with ${freshContacts.length} contacts.',
      );
    }

    // Existing snapshot: perform reconciliation
    final prevContactsMapById = <String, ContactRecord>{};
    final prevContactsMapByKey = <String, ContactRecord>{};

    for (final c in previousSnapshot.contacts) {
      prevContactsMapById[c.contactId] = c;
      final key = _compositeKey(c);
      if (key.isNotEmpty) {
        prevContactsMapByKey[key] = c;
      }
    }

    int newCount = 0;
    int updatedCount = 0;
    final matchedPrevIds = <String>{};

    for (final fresh in freshContacts) {
      ContactRecord? prev = prevContactsMapById[fresh.contactId];
      prev ??= prevContactsMapByKey[_compositeKey(fresh)];

      if (prev == null) {
        newCount++;
      } else {
        matchedPrevIds.add(prev.contactId);
        if (_hasChanged(prev, fresh)) {
          updatedCount++;
        }
      }
    }

    // Detect contacts in previous snapshot that are no longer found in fresh read
    final noLongerFound = <ContactRecord>[];
    for (final prev in previousSnapshot.contacts) {
      if (!matchedPrevIds.contains(prev.contactId)) {
        noLongerFound.add(
          prev.copyWith(
            isHistorical: true,
            lastSeenAt: previousSnapshot.updatedAt,
          ),
        );
      }
    }

    final bool isUpToDate = (newCount == 0 && updatedCount == 0 && noLongerFound.isEmpty);

    if (isUpToDate) {
      return ContactReconciliationResult(
        currentAvailableCount: freshContacts.length,
        newContactsCount: 0,
        updatedContactsCount: 0,
        noLongerFoundCount: 0,
        isUpToDate: true,
        summaryMessage: 'Your contact backup is already up to date (${freshContacts.length} contacts).',
      );
    }

    // Merge retained removed contacts
    final combinedRemoved = <ContactRecord>[...previousSnapshot.removedContacts];
    for (final missing in noLongerFound) {
      if (!combinedRemoved.any((r) => r.contactId == missing.contactId)) {
        combinedRemoved.add(missing);
      }
    }

    final updatedSnapshot = previousSnapshot.copyWith(
      updatedAt: nowIso,
      lastSuccessfulSyncAt: nowIso,
      contactCount: freshContacts.length,
      contacts: freshContacts,
      removedContacts: combinedRemoved,
    );

    await _jsonService.saveSnapshotAtomically(updatedSnapshot);

    // Record in history
    await _historyService.insertRecord(
      BackupRecord(
        backupType: BackupType.contactJson,
        category: 'Contacts',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        destination: 'App-Private Storage',
        filename: StorageConstants.contactsSnapshotFileName,
        itemCount: freshContacts.length,
        inputSize: freshContacts.length * 150,
        outputSize: updatedSnapshot.contacts.length * 150,
        status: BackupStatus.completed,
        errorSummary: null,
      ),
    );

    final msg = 'Contact Backup Updated: ${freshContacts.length} available, '
        '$newCount new, $updatedCount updated, ${noLongerFound.length} historical.';

    return ContactReconciliationResult(
      currentAvailableCount: freshContacts.length,
      newContactsCount: newCount,
      updatedContactsCount: updatedCount,
      noLongerFoundCount: noLongerFound.length,
      isUpToDate: false,
      summaryMessage: msg,
    );
  }

  static String _compositeKey(ContactRecord c) {
    final name = c.displayName.trim().toLowerCase();
    final phone = c.primaryPhone.replaceAll(RegExp(r'\s+'), '');
    return '$name|$phone';
  }

  static bool _hasChanged(ContactRecord prev, ContactRecord current) {
    if (prev.displayName.trim() != current.displayName.trim()) return true;
    if (prev.phoneNumbers.length != current.phoneNumbers.length) return true;
    for (int i = 0; i < prev.phoneNumbers.length; i++) {
      if (prev.phoneNumbers[i] != current.phoneNumbers[i]) return true;
    }
    if (prev.emails.length != current.emails.length) return true;
    for (int i = 0; i < prev.emails.length; i++) {
      if (prev.emails[i] != current.emails[i]) return true;
    }
    return false;
  }
}
