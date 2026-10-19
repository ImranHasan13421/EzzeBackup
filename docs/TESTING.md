# Ezze Backup — Testing Strategy & Results

## 1. Test Architecture
Tests are partitioned into:
- **Unit Tests (`test/unit/`)**:
  - `contact_reconciliation_test.dart`: Verifies new contact detection, updated field detection, historical retention without loss, and empty result safety.
  - `unicode_sorting_test.dart`: Validates case-insensitive alphabetical sorting across English and Bengali (Bangla) names, special characters, and empty names.
  - `backup_manifest_test.dart`: Validates manifest serialization, format versioning, and entry metadata.
  - `zip_security_test.dart`: Validates sanitization of relative paths against path traversal attacks (`../../`).
  - `backup_record_test.dart`: Validates SQLite serialization/deserialization of `BackupRecord`.
- **Widget & Flow Tests (`test/widget/`)**:
  - `home_screen_test.dart`: Verifies dashboard cards, status indicators, and navigation triggers.
  - `file_backup_ui_test.dart`: Verifies category picker, file list display, and progress modal.

## 2. Privacy & Synthetic Data Rules
No real personal data or personal phone numbers are ever used in automated tests. All tests use synthetic mock records.

## 3. Running Test Suites
```bash
flutter test
```
