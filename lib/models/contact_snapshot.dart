import 'contact_record.dart';

class ContactSnapshot {
  final String app;
  final String backupType;
  final int schemaVersion;
  final String createdAt;
  final String updatedAt;
  final String lastSuccessfulSyncAt;
  final int contactCount;
  final List<ContactRecord> contacts;
  final List<ContactRecord> removedContacts;

  const ContactSnapshot({
    this.app = 'Ezze Backup',
    this.backupType = 'contacts',
    this.schemaVersion = 1,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSuccessfulSyncAt,
    required this.contactCount,
    required this.contacts,
    this.removedContacts = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'app': app,
      'backupType': backupType,
      'schemaVersion': schemaVersion,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastSuccessfulSyncAt': lastSuccessfulSyncAt,
      'contactCount': contactCount,
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'removedContacts': removedContacts.map((c) => c.toJson()).toList(),
    };
  }

  factory ContactSnapshot.fromJson(Map<String, dynamic> json) {
    final rawContacts = (json['contacts'] as List<dynamic>?)
            ?.map((c) => ContactRecord.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    final rawRemoved = (json['removedContacts'] as List<dynamic>?)
            ?.map((c) => ContactRecord.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    return ContactSnapshot(
      app: json['app'] as String? ?? 'Ezze Backup',
      backupType: json['backupType'] as String? ?? 'contacts',
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      lastSuccessfulSyncAt:
          json['lastSuccessfulSyncAt'] as String? ?? DateTime.now().toIso8601String(),
      contactCount: json['contactCount'] as int? ?? rawContacts.length,
      contacts: rawContacts,
      removedContacts: rawRemoved,
    );
  }

  ContactSnapshot copyWith({
    String? app,
    String? backupType,
    int? schemaVersion,
    String? createdAt,
    String? updatedAt,
    String? lastSuccessfulSyncAt,
    int? contactCount,
    List<ContactRecord>? contacts,
    List<ContactRecord>? removedContacts,
  }) {
    return ContactSnapshot(
      app: app ?? this.app,
      backupType: backupType ?? this.backupType,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      contactCount: contactCount ?? this.contactCount,
      contacts: contacts ?? this.contacts,
      removedContacts: removedContacts ?? this.removedContacts,
    );
  }
}

class ContactReconciliationResult {
  final int currentAvailableCount;
  final int newContactsCount;
  final int updatedContactsCount;
  final int noLongerFoundCount;
  final bool isUpToDate;
  final String summaryMessage;

  const ContactReconciliationResult({
    required this.currentAvailableCount,
    required this.newContactsCount,
    required this.updatedContactsCount,
    required this.noLongerFoundCount,
    required this.isUpToDate,
    required this.summaryMessage,
  });
}
