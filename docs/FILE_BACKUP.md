# Ezze Backup — File & Media ZIP Backup Specification

## 1. Supported Categories & Selection Modes
1. **Category Selection**:
   - Documents (`.pdf`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.ppt`, `.pptx`, `.txt`, `.csv`, etc.)
   - Images (`.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.heic`, etc.)
   - Videos (`.mp4`, `.mkv`, `.mov`, `.avi`, `.webm`, etc.)
   - Audio (`.mp3`, `.m4a`, `.wav`, `.flac`, `.aac`, etc.)
   - Other Files (Compressed, code, database files, archives)
2. **Custom Selection**:
   - Explicit multi-file selection via system file picker (`file_picker`).
   - Folder selection where supported by the platform.

## 2. ZIP Archive Internal Structure
```
Documents_2026-10-19_211500.zip
├── Documents/
│   ├── Work_Contract.pdf
│   └── Certificate.pdf
├── Spreadsheets/
│   └── Q3_Expenses.xlsx
└── ezze_backup_manifest.json
```

## 3. Archive Manifest (`ezze_backup_manifest.json`)
Every ZIP archive includes a top-level manifest:
```json
{
  "appName": "Ezze Backup",
  "archiveFormatVersion": 1,
  "createdAt": "2026-10-19T21:15:00Z",
  "category": "Documents",
  "totalFiles": 3,
  "totalInputBytes": 1420580,
  "entries": [
    {
      "relativePath": "Documents/Work_Contract.pdf",
      "originalSizeBytes": 894020,
      "modifiedAt": "2026-10-15T12:00:00Z"
    }
  ]
}
```

## 4. Archive Verification & Security Rules
- **No Path Traversal**: Every relative path is checked to reject `../` or leading root slashes (`/` or `C:\`).
- **Archive Verification**: The generated archive is opened immediately upon creation and verified by reading entry headers.
- **Atomic Destination**: The archive is initially compressed into `temporary/` and moved to destination storage only upon full verification.
