class ContactPhone {
  final String number;
  final String label;

  const ContactPhone({required this.number, this.label = 'mobile'});

  Map<String, dynamic> toJson() => {
        'number': number,
        'label': label,
      };

  factory ContactPhone.fromJson(Map<String, dynamic> json) => ContactPhone(
        number: json['number'] as String? ?? '',
        label: json['label'] as String? ?? 'mobile',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactPhone &&
          runtimeType == other.runtimeType &&
          number.replaceAll(RegExp(r'\s+'), '') ==
              other.number.replaceAll(RegExp(r'\s+'), '') &&
          label.toLowerCase() == other.label.toLowerCase();

  @override
  int get hashCode => number.hashCode ^ label.hashCode;
}

class ContactEmail {
  final String address;
  final String label;

  const ContactEmail({required this.address, this.label = 'home'});

  Map<String, dynamic> toJson() => {
        'address': address,
        'label': label,
      };

  factory ContactEmail.fromJson(Map<String, dynamic> json) => ContactEmail(
        address: json['address'] as String? ?? '',
        label: json['label'] as String? ?? 'home',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactEmail &&
          runtimeType == other.runtimeType &&
          address.toLowerCase().trim() == other.address.toLowerCase().trim() &&
          label.toLowerCase() == other.label.toLowerCase();

  @override
  int get hashCode => address.hashCode ^ label.hashCode;
}

class ContactRecord {
  final String contactId;
  final String displayName;
  final String? givenName;
  final String? middleName;
  final String? familyName;
  final List<ContactPhone> phoneNumbers;
  final List<ContactEmail> emails;
  final String? organization;
  final bool isHistorical;
  final String? lastSeenAt;

  const ContactRecord({
    required this.contactId,
    required this.displayName,
    this.givenName,
    this.middleName,
    this.familyName,
    required this.phoneNumbers,
    required this.emails,
    this.organization,
    this.isHistorical = false,
    this.lastSeenAt,
  });

  String get primaryPhone =>
      phoneNumbers.isNotEmpty ? phoneNumbers.first.number : '';

  String get alternativePhone =>
      phoneNumbers.length > 1 ? phoneNumbers[1].number : '';

  List<ContactPhone> get extraPhones =>
      phoneNumbers.length > 2 ? phoneNumbers.sublist(2) : const [];

  String get primaryEmail =>
      emails.isNotEmpty ? emails.first.address : '';

  List<ContactEmail> get extraEmails =>
      emails.length > 1 ? emails.sublist(1) : const [];

  Map<String, dynamic> toJson() => {
        'contactId': contactId,
        'displayName': displayName,
        if (givenName != null) 'givenName': givenName,
        if (middleName != null) 'middleName': middleName,
        if (familyName != null) 'familyName': familyName,
        'phoneNumbers': phoneNumbers.map((p) => p.toJson()).toList(),
        'emails': emails.map((e) => e.toJson()).toList(),
        if (organization != null) 'organization': organization,
        'isHistorical': isHistorical,
        if (lastSeenAt != null) 'lastSeenAt': lastSeenAt,
      };

  factory ContactRecord.fromJson(Map<String, dynamic> json) => ContactRecord(
        contactId: json['contactId'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'Unnamed Contact',
        givenName: json['givenName'] as String?,
        middleName: json['middleName'] as String?,
        familyName: json['familyName'] as String?,
        phoneNumbers: (json['phoneNumbers'] as List<dynamic>?)
                ?.map((p) => ContactPhone.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        emails: (json['emails'] as List<dynamic>?)
                ?.map((e) => ContactEmail.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        organization: json['organization'] as String?,
        isHistorical: json['isHistorical'] as bool? ?? false,
        lastSeenAt: json['lastSeenAt'] as String?,
      );

  ContactRecord copyWith({
    String? contactId,
    String? displayName,
    String? givenName,
    String? middleName,
    String? familyName,
    List<ContactPhone>? phoneNumbers,
    List<ContactEmail>? emails,
    String? organization,
    bool? isHistorical,
    String? lastSeenAt,
  }) {
    return ContactRecord(
      contactId: contactId ?? this.contactId,
      displayName: displayName ?? this.displayName,
      givenName: givenName ?? this.givenName,
      middleName: middleName ?? this.middleName,
      familyName: familyName ?? this.familyName,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      emails: emails ?? this.emails,
      organization: organization ?? this.organization,
      isHistorical: isHistorical ?? this.isHistorical,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
