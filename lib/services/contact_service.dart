import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../core/errors/app_exceptions.dart';
import '../models/contact_record.dart';

class ContactService {
  /// Checks if contact read permission is granted
  Future<bool> hasPermission() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        // Desktop / tests fallback
        return true;
      }
      return await FlutterContacts.permissions.has(PermissionType.read);
    } catch (e) {
      debugPrint('Error checking contact permission: $e');
      return false;
    }
  }

  /// Requests contact read permission from user
  Future<bool> requestPermission() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        return true;
      }
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting contact permission: $e');
      throw PermissionException('Unable to request contact access: $e');
    }
  }

  /// Reads all contacts accessible through the device's Contacts Provider.
  /// Preserves all phone numbers, email addresses, and organization details.
  /// Sorts records alphabetically (Unicode-safe for Bangla & English).
  Future<List<ContactRecord>> fetchDeviceContacts() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Return empty list or sample mock contacts on desktop/test environments
      return _generateSampleContacts();
    }

    final hasPerm = await hasPermission();
    if (!hasPerm) {
      final requested = await requestPermission();
      if (!requested) {
        throw const PermissionException('Contact permission was denied by the user.');
      }
    }

    try {
      final rawContacts = await FlutterContacts.getAll(
        properties: ContactProperties.allProperties,
      );

      final normalized = <ContactRecord>[];

      for (final c in rawContacts) {
        final phones = <ContactPhone>[];
        for (final p in c.phones) {
          final trimmed = p.number.trim();
          if (trimmed.isNotEmpty) {
            final lbl = p.label.customLabel ?? p.label.label.name;
            phones.add(
              ContactPhone(
                number: trimmed,
                label: lbl.isNotEmpty ? lbl : 'mobile',
              ),
            );
          }
        }

        final emails = <ContactEmail>[];
        for (final e in c.emails) {
          final trimmed = e.address.trim();
          if (trimmed.isNotEmpty) {
            final lbl = e.label.customLabel ?? e.label.label.name;
            emails.add(
              ContactEmail(
                address: trimmed,
                label: lbl.isNotEmpty ? lbl : 'home',
              ),
            );
          }
        }

        // Determine best display name
        String name = (c.displayName ?? '').trim();
        if (name.isEmpty) {
          final first = c.name?.first ?? '';
          final last = c.name?.last ?? '';
          final combined = '$first $last'.trim();
          if (combined.isNotEmpty) {
            name = combined;
          } else if (phones.isNotEmpty) {
            name = phones.first.number;
          } else {
            name = 'Unnamed Contact';
          }
        }

        normalized.add(
          ContactRecord(
            contactId: c.id ?? 'contact_${normalized.length}',
            displayName: name,
            givenName: (c.name?.first ?? '').isNotEmpty ? c.name!.first : null,
            middleName: (c.name?.middle ?? '').isNotEmpty ? c.name!.middle : null,
            familyName: (c.name?.last ?? '').isNotEmpty ? c.name!.last : null,
            phoneNumbers: phones,
            emails: emails,
            organization: c.organizations.isNotEmpty ? c.organizations.first.name : null,
            isHistorical: false,
            lastSeenAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      // Sort alphabetically A-Z (Unicode-safe)
      sortContactsAlphabetically(normalized);
      return normalized;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ContactException('Failed to read device contacts: $e', details: e);
    }
  }

  /// Sorts contacts list alphabetically in-place (Unicode collation)
  static void sortContactsAlphabetically(List<ContactRecord> list) {
    list.sort((a, b) {
      final nameA = a.displayName.trim().toLowerCase();
      final nameB = b.displayName.trim().toLowerCase();
      final cmp = nameA.compareTo(nameB);
      if (cmp != 0) return cmp;
      return a.contactId.compareTo(b.contactId);
    });
  }

  /// Sample mock contacts for desktop development / headless testing
  static List<ContactRecord> _generateSampleContacts() {
    final samples = [
      const ContactRecord(
        contactId: 'mock-1',
        displayName: 'Abdullah Al Mamun',
        givenName: 'Abdullah',
        familyName: 'Mamun',
        phoneNumbers: [
          ContactPhone(number: '01711000001', label: 'mobile'),
          ContactPhone(number: '01811000002', label: 'work'),
        ],
        emails: [ContactEmail(address: 'abdullah@example.com', label: 'work')],
        organization: 'Ezze Systems',
      ),
      const ContactRecord(
        contactId: 'mock-2',
        displayName: 'Imran Hasan',
        givenName: 'Imran',
        familyName: 'Hasan',
        phoneNumbers: [
          ContactPhone(number: '01911000003', label: 'mobile'),
        ],
        emails: [ContactEmail(address: 'imran@example.com', label: 'home')],
        organization: 'Ezze Backup',
      ),
      const ContactRecord(
        contactId: 'mock-3',
        displayName: 'Mahin Khan',
        givenName: 'Mahin',
        familyName: 'Khan',
        phoneNumbers: [
          ContactPhone(number: '01611000004', label: 'mobile'),
        ],
        emails: [],
        organization: null,
      ),
      const ContactRecord(
        contactId: 'mock-4',
        displayName: 'রফিকুল ইসলাম (Rafiqul Islam)',
        givenName: 'রফিকুল',
        familyName: 'ইসলাম',
        phoneNumbers: [
          ContactPhone(number: '01511000005', label: 'mobile'),
        ],
        emails: [ContactEmail(address: 'rafiqul@example.com', label: 'personal')],
        organization: 'ঢাকা বিশ্ববিদ্যালয়',
      ),
    ];
    sortContactsAlphabetically(samples);
    return samples;
  }
}
