# Ezze Backup — Android Storage & Permission Strategy

## 1. Storage Tiers

### Tier A: App-Private Storage (`path_provider.getApplicationDocumentsDirectory()`)
Used for private, internal state that must remain sandboxed from third-party apps:
```
<app_documents_dir>/EzzeBackup/
├── contacts/
│   ├── contacts_snapshot.json       # Versioned active snapshot
│   ├── contacts_metadata.json       # Sync counts & timestamps
│   └── snapshots/                   # Historical snapshots if requested
├── database/
│   └── backup_history.db            # SQLite metadata database
├── temporary/                       # Temp files during ZIP and PDF creation
└── logs/                            # Anonymized diagnostic logs
```

### Tier B: User-Accessible Storage (Shared Storage / User Designated Directory)
Used for exported archives, contact PDFs, and user exports:
```
<Storage_Root>/Ezze Backup/
├── Files/
│   ├── Documents_YYYY-MM-DD_HHMMSS.zip
│   ├── Photos_YYYY-MM-DD_HHMMSS.zip
│   └── Selected_Files_YYYY-MM-DD_HHMMSS.zip
├── Media/
│   ├── Images_YYYY-MM-DD_HHMMSS.zip
│   ├── Videos_YYYY-MM-DD_HHMMSS.zip
│   └── Audio_YYYY-MM-DD_HHMMSS.zip
├── Contacts/
│   ├── Contacts_YYYY-MM-DD_HHMMSS.pdf
│   └── Contacts_YYYY-MM-DD_HHMMSS.json
└── Backup_Logs/
    └── backup_manifest.json
```

## 2. Android Scoped Storage & Permission Handling
- **Android 13+ (API 33+)**:
  - `READ_MEDIA_IMAGES`
  - `READ_MEDIA_VIDEO`
  - `READ_MEDIA_AUDIO`
- **Android 10 - 12 (API 29-32)**:
  - `READ_EXTERNAL_STORAGE`
  - `WRITE_EXTERNAL_STORAGE` (maxSdkVersion=29)
  - `android:requestLegacyExternalStorage="true"`
- **Storage Access Framework (SAF) / Directory Picker**:
  - Users can configure a custom destination folder via `file_picker.getDirectoryPath()`.
  - When the app is unable to write directly to shared storage, it falls back to app-accessible directories or prompts the user to select an export folder.

## 3. Atomic File Writes & Safety
1. Create target data in `temporary/` with a temporary suffix.
2. Verify integrity (JSON parse or ZIP entry enumeration).
3. Atomically rename/replace the destination file.
4. Clean up any stale temporary files on startup or cancellation.
5. If a filename collision occurs, append `_1`, `_2` to avoid silent overwrites.
