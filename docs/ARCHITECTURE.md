# Ezze Backup — Technical Architecture

## 1. System Overview
Ezze Backup is an Android-first mobile backup utility built with Flutter and Dart. Its primary mission is to protect vital personal data—specifically user files, media collections, and device contacts—without compromising user privacy, stability, or system performance.

## 2. Core Architectural Principles
- **Privacy by Design**: All contact snapshots and metadata are kept in app-private storage by default. No background servers, analytics, or external trackers are utilized.
- **Separation of Concerns**: Clean feature-based layering divides UI (presentation), business state (Riverpod StateNotifiers/Notifiers), domain models, and platform I/O services.
- **Format Integrity**:
  - **ZIP**: Compressed archives for file and media backups with internal JSON manifests.
  - **JSON**: Machine-readable, versioned contact snapshots that support on-demand atomic reconciliation.
  - **PDF**: Human-readable, printable A4 contact directories supporting Unicode (Bangla and English).
  - **SQLite**: Local relational database tracking all backup and export operations.
- **Defensive I/O**: Atomic file writes via temporary files, path validation preventing directory traversal (`../`), and verification of archive structures prior to success declaration.

## 3. Layered Module Structure
```
lib/
├── core/                  # Constants, exceptions, themes, formatting utils, router
├── models/                # Immutables: BackupRecord, BackupManifest, ContactRecord, ContactSnapshot
├── services/              # Low-level infrastructure services (I/O, SQLite, Archive, PDF, Contacts)
├── features/              # Feature modules:
│   ├── home/              # Dashboard overview, storage status, action cards
│   ├── file_backup/       # Category selection, file picking, ZIP compression
│   ├── contact_backup/    # Contact fetching, reconciliation, JSON snapshot, PDF export
│   ├── backup_history/    # Persistent log inspection, file opening, sharing, deletion
│   └── settings/          # Destination selection, theme toggles, app metadata
└── shared/widgets/        # Design system reusable UI components
```

## 4. State Management with Riverpod
- `backupHistoryProvider`: Exposes stream/future of historical backup records from SQLite.
- `contactBackupProvider`: Manages contact snapshot state, sync reconciliation, and PDF generation status.
- `fileBackupProvider`: Manages category selection, selected file lists, compression progress, and outcome.
- `settingsProvider`: Manages user preferences (theme mode, custom backup destination directory).

## 5. Security & Isolation
- Contacts are processed in-memory and written directly to app-private sandboxed storage (`context.filesDir` equivalent).
- Exports to shared storage or external sharing only occur upon explicit user intent.
