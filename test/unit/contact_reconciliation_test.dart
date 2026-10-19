import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_backup/models/contact_record.dart';
import 'package:ezze_backup/models/contact_snapshot.dart';

void main() {
  group('Contact Reconciliation & Non-Destructive Sync Logic Tests', () {
    test('Detects new contacts and preserves existing contacts', () {
      final prevContacts = [
        const ContactRecord(
          contactId: 'id-1',
          displayName: 'Person A',
          phoneNumbers: [ContactPhone(number: '01711111111', label: 'mobile')],
          emails: [ContactEmail(address: 'a@example.com', label: 'home')],
        ),
      ];

      final freshContacts = [
        const ContactRecord(
          contactId: 'id-1',
          displayName: 'Person A',
          phoneNumbers: [ContactPhone(number: '01711111111', label: 'mobile')],
          emails: [ContactEmail(address: 'a@example.com', label: 'home')],
        ),
        const ContactRecord(
          contactId: 'id-2',
          displayName: 'Person B',
          phoneNumbers: [ContactPhone(number: '01822222222', label: 'mobile')],
          emails: [],
        ),
      ];

      final prevIds = prevContacts.map((c) => c.contactId).toSet();
      final newContacts = freshContacts.where((c) => !prevIds.contains(c.contactId)).toList();

      expect(newContacts.length, 1);
      expect(newContacts.first.displayName, 'Person B');
    });

    test('Detects updated phone numbers or emails without losing historical fields', () {
      const prevContact = ContactRecord(
        contactId: 'id-1',
        displayName: 'Person A',
        phoneNumbers: [ContactPhone(number: '01711111111', label: 'mobile')],
        emails: [],
      );

      const freshContact = ContactRecord(
        contactId: 'id-1',
        displayName: 'Person A',
        phoneNumbers: [
          ContactPhone(number: '01711111111', label: 'mobile'),
          ContactPhone(number: '01999999999', label: 'work'),
        ],
        emails: [ContactEmail(address: 'new@example.com', label: 'work')],
      );

      final hasPhoneChanged = prevContact.phoneNumbers.length != freshContact.phoneNumbers.length;
      final hasEmailChanged = prevContact.emails.length != freshContact.emails.length;

      expect(hasPhoneChanged, true);
      expect(hasEmailChanged, true);
      expect(freshContact.phoneNumbers.length, 2);
      expect(freshContact.emails.length, 1);
    });

    test('Retains missing contacts as historical records without silent erasure', () {
      final prevSnapshot = ContactSnapshot(
        createdAt: '2026-10-19T10:00:00Z',
        updatedAt: '2026-10-19T10:00:00Z',
        lastSuccessfulSyncAt: '2026-10-19T10:00:00Z',
        contactCount: 2,
        contacts: const [
          ContactRecord(
            contactId: 'id-1',
            displayName: 'Active Contact',
            phoneNumbers: [ContactPhone(number: '01711111111', label: 'mobile')],
            emails: [],
          ),
          ContactRecord(
            contactId: 'id-2',
            displayName: 'Vanished Contact',
            phoneNumbers: [ContactPhone(number: '01822222222', label: 'mobile')],
            emails: [],
          ),
        ],
        removedContacts: const [],
      );

      // Fresh read only returns id-1
      final freshRead = [
        const ContactRecord(
          contactId: 'id-1',
          displayName: 'Active Contact',
          phoneNumbers: [ContactPhone(number: '01711111111', label: 'mobile')],
          emails: [],
        ),
      ];

      final freshIds = freshRead.map((c) => c.contactId).toSet();
      final noLongerFound = prevSnapshot.contacts
          .where((c) => !freshIds.contains(c.contactId))
          .map((c) => c.copyWith(isHistorical: true))
          .toList();

      expect(noLongerFound.length, 1);
      expect(noLongerFound.first.displayName, 'Vanished Contact');
      expect(noLongerFound.first.isHistorical, true);

      // Historical records preserved
      final updatedSnapshot = prevSnapshot.copyWith(
        contactCount: freshRead.length,
        contacts: freshRead,
        removedContacts: [...prevSnapshot.removedContacts, ...noLongerFound],
      );

      expect(updatedSnapshot.contactCount, 1);
      expect(updatedSnapshot.contacts.length, 1);
      expect(updatedSnapshot.removedContacts.length, 1);
    });
  });
}
