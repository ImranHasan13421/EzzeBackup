import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/backup_record.dart';
import 'storage_service.dart';

class BackupHistoryService {
  final StorageService _storageService;
  Database? _db;

  BackupHistoryService(this._storageService);

  Future<void> initialize() async {
    if (_db != null) return;
    try {
      await _storageService.initialize();
      final dbPath = _storageService.backupHistoryDbFile.path;
      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE backup_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              backup_type TEXT NOT NULL,
              category TEXT NOT NULL,
              created_at TEXT NOT NULL,
              completed_at TEXT,
              destination TEXT NOT NULL,
              filename TEXT NOT NULL,
              item_count INTEGER NOT NULL DEFAULT 0,
              input_size INTEGER NOT NULL DEFAULT 0,
              output_size INTEGER NOT NULL DEFAULT 0,
              status TEXT NOT NULL,
              error_summary TEXT,
              manifest_version INTEGER NOT NULL DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE INDEX idx_backup_created_at ON backup_history (created_at DESC)
          ''');
        },
      );
    } catch (e) {
      debugPrint('Error initializing backup history database: $e');
      rethrow;
    }
  }

  Database get db {
    if (_db == null) {
      throw StateError('BackupHistoryService has not been initialized. Call initialize() first.');
    }
    return _db!;
  }

  Future<int> insertRecord(BackupRecord record) async {
    await initialize();
    return await db.insert('backup_history', record.toMap());
  }

  Future<void> updateRecord(BackupRecord record) async {
    await initialize();
    if (record.id == null) return;
    await db.update(
      'backup_history',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<List<BackupRecord>> getAllRecords() async {
    await initialize();
    final rows = await db.query(
      'backup_history',
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => BackupRecord.fromMap(r)).toList();
  }

  Future<List<BackupRecord>> getRecentRecords({int limit = 5}) async {
    await initialize();
    final rows = await db.query(
      'backup_history',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map((r) => BackupRecord.fromMap(r)).toList();
  }

  Future<BackupRecord?> getLatestSuccessfulBackup() async {
    await initialize();
    final rows = await db.query(
      'backup_history',
      where: 'status = ? OR status = ?',
      whereArgs: [BackupStatus.completed, BackupStatus.completedWithWarnings],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BackupRecord.fromMap(rows.first);
  }

  Future<void> deleteRecord(int id) async {
    await initialize();
    await db.delete(
      'backup_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    await initialize();
    await db.delete('backup_history');
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
