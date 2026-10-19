import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_backup/models/contact_record.dart';
import 'package:ezze_backup/services/contact_service.dart';

void main() {
  group('Unicode & Multilingual Sorting Tests', () {
    test('Sorts English names alphabetically case-insensitively', () {
      final contacts = [
        const ContactRecord(
          contactId: '3',
          displayName: 'charlie',
          phoneNumbers: [],
          emails: [],
        ),
        const ContactRecord(
          contactId: '1',
          displayName: 'Alice',
          phoneNumbers: [],
          emails: [],
        ),
        const ContactRecord(
          contactId: '2',
          displayName: 'BOB',
          phoneNumbers: [],
          emails: [],
        ),
      ];

      ContactService.sortContactsAlphabetically(contacts);

      expect(contacts[0].displayName, 'Alice');
      expect(contacts[1].displayName, 'BOB');
      expect(contacts[2].displayName, 'charlie');
    });

    test('Preserves Bangla Unicode characters without corruption', () {
      final contacts = [
        const ContactRecord(
          contactId: 'b2',
          displayName: 'রফিকুল ইসলাম',
          phoneNumbers: [],
          emails: [],
        ),
        const ContactRecord(
          contactId: 'b1',
          displayName: 'আব্দুল্লাহ',
          phoneNumbers: [],
          emails: [],
        ),
      ];

      ContactService.sortContactsAlphabetically(contacts);

      expect(contacts[0].displayName, 'আব্দুল্লাহ');
      expect(contacts[1].displayName, 'রফিকুল ইসলাম');
    });

    test('Handles mixed English and Bengali contact lists gracefully', () {
      final contacts = [
        const ContactRecord(
          contactId: '1',
          displayName: 'Imran Hasan',
          phoneNumbers: [],
          emails: [],
        ),
        const ContactRecord(
          contactId: '2',
          displayName: 'আব্দুল',
          phoneNumbers: [],
          emails: [],
        ),
      ];

      ContactService.sortContactsAlphabetically(contacts);
      expect(contacts.length, 2);
    });

    test('Handles contacts with leading/trailing whitespace stably', () {
      final contacts = [
        const ContactRecord(
          contactId: '2',
          displayName: '  Zubair',
          phoneNumbers: [],
          emails: [],
        ),
        const ContactRecord(
          contactId: '1',
          displayName: 'Aaron  ',
          phoneNumbers: [],
          emails: [],
        ),
      ];

      ContactService.sortContactsAlphabetically(contacts);

      expect(contacts[0].displayName.trim(), 'Aaron');
      expect(contacts[1].displayName.trim(), 'Zubair');
    });
  });
}
