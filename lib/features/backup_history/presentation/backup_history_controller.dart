import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/backup_record.dart';
import '../../../services/service_providers.dart';

class BackupHistoryState {
  final List<BackupRecord> records;
  final bool isLoading;
  final String? errorMessage;
  final String selectedFilter; // 'All', 'Files', 'Contacts'

  const BackupHistoryState({
    required this.records,
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter = 'All',
  });

  List<BackupRecord> get filteredRecords {
    if (selectedFilter == 'All') return records;
    if (selectedFilter == 'Files') {
      return records.where((r) => r.backupType == BackupType.file).toList();
    }
    if (selectedFilter == 'Contacts') {
      return records
          .where((r) =>
              r.backupType == BackupType.contactJson ||
              r.backupType == BackupType.contactPdf)
          .toList();
    }
    return records;
  }

  BackupHistoryState copyWith({
    List<BackupRecord>? records,
    bool? isLoading,
    String? errorMessage,
    String? selectedFilter,
  }) {
    return BackupHistoryState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class BackupHistoryNotifier extends StateNotifier<BackupHistoryState> {
  final Ref _ref;

  BackupHistoryNotifier(this._ref)
      : super(const BackupHistoryState(records: [], isLoading: true)) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final historyService = _ref.read(backupHistoryServiceProvider);
      final list = await historyService.getAllRecords();
      state = state.copyWith(records: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<void> deleteRecord(BackupRecord record, {bool deleteFileFromDisk = true}) async {
    try {
      final historyService = _ref.read(backupHistoryServiceProvider);
      if (record.id != null) {
        await historyService.deleteRecord(record.id!);
      }

      if (deleteFileFromDisk && record.destination.isNotEmpty) {
        final file = File(record.destination);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }

      await loadHistory();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete record: $e');
    }
  }

  Future<void> shareFile(BackupRecord record) async {
    final file = File(record.destination);
    if (!await file.exists()) {
      state = state.copyWith(errorMessage: 'The file no longer exists at ${record.destination}');
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(record.destination)],
          subject: record.filename,
          text: 'Backup exported from Ezze Backup: ${record.filename}',
        ),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not share file: $e');
    }
  }
}

final backupHistoryProvider =
    StateNotifierProvider<BackupHistoryNotifier, BackupHistoryState>((ref) {
  return BackupHistoryNotifier(ref);
});
