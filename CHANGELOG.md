# Changelog

All notable changes to the Ezze Backup project will be documented in this file.

## [1.0.0] - 2026-10-19

### Initial Release (MVP)
- **Architecture**: Clean feature-based modular design using Flutter, Dart null-safety, Riverpod state management, and GoRouter navigation.
- **Storage Foundation**: Two-tier storage architecture with app-private sandboxed directory and user-accessible shared directory (`Ezze Backup/`).
- **File & Media Backup**: Multi-category file discovery (Documents, Images, Videos, Audio, Other, Custom), ZIP compression with embedded JSON manifests, progress reporting, archive integrity verification, and path traversal prevention.
- **Contact Backup**: Complete contact extraction via Android Contacts Provider, multi-number and multi-email preservation, Bengali and English Unicode-safe alphabetical sorting, atomic versioned JSON snapshot storage, and non-destructive on-demand update reconciliation ("Update Numbers Backup").
- **Contact PDF Export**: Professional A4 printable directory with 4-column layout (Name, Phone, Alternative Phone, Email), pagination, repeated headers, continuation rows, and bundled Bangla and Latin Unicode font typography.
- **Backup History**: Persistent SQLite database tracking all backup and export operations with item counts, byte sizes, statuses, and file actions (Open, Share, Delete).
- **Design System**: Material 3 UI with dark mode (deep navy/charcoal) and light mode, blue primary accents, status indicators, and persistent theme switching.
