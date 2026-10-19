import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/contact_snapshot.dart';
import '../../../services/service_providers.dart';
import '../../backup_history/presentation/backup_history_controller.dart';

class ContactBackupState {
  final ContactSnapshot? snapshot;
  final bool isLoading;
  final bool isSyncing;
  final bool isExporting;
  final ContactReconciliationResult? lastResult;
  final String? errorMessage;
  final String? successMessage;

  const ContactBackupState({
    this.snapshot,
    this.isLoading = false,
    this.isSyncing = false,
    this.isExporting = false,
    this.lastResult,
    this.errorMessage,
    this.successMessage,
  });

  ContactBackupState copyWith({
    ContactSnapshot? snapshot,
    bool? isLoading,
    bool? isSyncing,
    bool? isExporting,
    ContactReconciliationResult? lastResult,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ContactBackupState(
      snapshot: snapshot ?? this.snapshot,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      isExporting: isExporting ?? this.isExporting,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ContactBackupNotifier extends StateNotifier<ContactBackupState> {
  final Ref _ref;

  ContactBackupNotifier(this._ref) : super(const ContactBackupState(isLoading: true)) {
    loadSnapshot();
  }

  Future<void> loadSnapshot() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final jsonService = _ref.read(contactJsonServiceProvider);
      final active = await jsonService.loadActiveSnapshot();
      state = state.copyWith(snapshot: active, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> syncContacts() async {
    state = state.copyWith(isSyncing: true, clearMessages: true);
    try {
      final syncService = _ref.read(contactSyncServiceProvider);
      final result = await syncService.synchronizeContacts();
      final jsonService = _ref.read(contactJsonServiceProvider);
      final active = await jsonService.loadActiveSnapshot();

      // Refresh backup history
      _ref.read(backupHistoryProvider.notifier).loadHistory();

      state = state.copyWith(
        isSyncing: false,
        snapshot: active,
        lastResult: result,
        successMessage: result.summaryMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Contact backup failed: $e',
      );
    }
  }

  Future<File?> exportPdf([BuildContext? context]) async {
    if (state.snapshot == null) return null;
    if (context != null) {
      final perm = _ref.read(permissionServiceProvider);
      final hasPerm = await perm.ensureStoragePermission(context);
      if (!hasPerm) {
        state = state.copyWith(
          errorMessage: 'File access permission is required to save PDF into Download/EzzeBackUp.',
        );
        return null;
      }
    }

    state = state.copyWith(isExporting: true, clearMessages: true);
    try {
      final pdfService = _ref.read(pdfServiceProvider);
      final exported = await pdfService.exportPdfToSharedStorage(state.snapshot!);
      _ref.read(backupHistoryProvider.notifier).loadHistory();

      state = state.copyWith(
        isExporting: false,
        successMessage: 'PDF exported to ${exported.path}',
      );
      return exported;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Failed to export PDF: $e',
      );
      return null;
    }
  }

  Future<File?> exportJson([BuildContext? context]) async {
    if (state.snapshot == null) return null;
    if (context != null) {
      final perm = _ref.read(permissionServiceProvider);
      final hasPerm = await perm.ensureStoragePermission(context);
      if (!hasPerm) {
        state = state.copyWith(
          errorMessage: 'File access permission is required to save JSON into Download/EzzeBackUp.',
        );
        return null;
      }
    }

    state = state.copyWith(isExporting: true, clearMessages: true);
    try {
      final jsonService = _ref.read(contactJsonServiceProvider);
      final exported = await jsonService.exportSnapshotToSharedStorage(state.snapshot!);
      _ref.read(backupHistoryProvider.notifier).loadHistory();

      state = state.copyWith(
        isExporting: false,
        successMessage: 'JSON exported to ${exported.path}',
      );
      return exported;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Failed to export JSON: $e',
      );
      return null;
    }
  }
}

final contactBackupProvider =
    StateNotifierProvider<ContactBackupNotifier, ContactBackupState>((ref) {
  return ContactBackupNotifier(ref);
});
