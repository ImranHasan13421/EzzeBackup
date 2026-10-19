# Ezze Backup — Contact Backup & Synchronization Specification

## 1. Contact Snapshot JSON Schema (Version 1)
```json
{
  "app": "Ezze Backup",
  "backupType": "contacts",
  "schemaVersion": 1,
  "createdAt": "2026-10-19T15:00:00Z",
  "updatedAt": "2026-10-19T15:00:00Z",
  "lastSuccessfulSyncAt": "2026-10-19T15:00:00Z",
  "contactCount": 2,
  "contacts": [
    {
      "contactId": "raw-provider-id-1",
      "displayName": "Imran Hasan",
      "givenName": "Imran",
      "familyName": "Hasan",
      "phoneNumbers": [
        { "number": "017XXXXXXXX", "label": "mobile" },
        { "number": "018XXXXXXXX", "label": "work" }
      ],
      "emails": [
        { "address": "imran@example.com", "label": "home" }
      ],
      "organization": "Ezze",
      "isHistorical": false,
      "lastSeenAt": "2026-10-19T15:00:00Z"
    }
  ],
  "removedContacts": []
}
```

## 2. Reconciliation & Non-Destructive Synchronization Rules
When the user triggers **"Update Numbers Backup"**:
1. Request `READ_CONTACTS` permission if not already granted.
2. Read all accessible contacts from the device's Contacts Provider.
3. Compare incoming contacts against the existing active JSON snapshot:
   - **New Contacts**: Contacts present in the device provider that do not match existing active records by ID or composite phone/email identity.
   - **Updated Contacts**: Contacts whose names, phone numbers, or email addresses have changed.
   - **Retained Historical Contacts**: Contacts that are present in the previous snapshot but missing from the current device read are **NEVER silently deleted**. They are preserved in the snapshot, marked with `isHistorical: true` (or moved to `removedContacts`), and omitted from the active contact count.
4. If zero changes are detected, report "Your contact backup is already up to date" without producing duplicate files.
5. Write the updated snapshot atomically via temporary staging.
6. Record sync details in SQLite history.

## 3. Alphabetical Sorting & Multilingual Safety
- Names are normalized and sorted using Unicode-safe case-insensitive collation.
- Both Bengali (Bangla) and English (Latin) scripts are supported seamlessly without character corruption.
- Fallback for contacts without display names: First phone number or "Unnamed Contact".
