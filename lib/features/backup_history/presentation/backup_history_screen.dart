import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../models/backup_record.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import 'backup_history_controller.dart';

class BackupHistoryScreen extends ConsumerWidget {
  const BackupHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupHistoryProvider);
    final notifier = ref.read(backupHistoryProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filterOptions = ['All', 'Files', 'Contacts'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.loadHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: filterOptions.map((opt) {
                final isSelected = state.selectedFilter == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(opt),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : null,
                    ),
                    selectedColor: AppColors.primaryBlue,
                    checkmarkColor: Colors.white,
                    onSelected: (_) => notifier.setFilter(opt),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Records List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredRecords.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 56,
                                color: isDark
                                    ? AppColors.darkTextSecondary.withAlpha(100)
                                    : AppColors.lightTextSecondary.withAlpha(100),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No ${state.selectedFilter} Backups Found',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Backup operations will appear here with full metadata and export actions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: state.filteredRecords.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final r = state.filteredRecords[index];
                          return _buildRecordCard(context, ref, r);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, WidgetRef ref, BackupRecord r) {
    IconData icon;
    Color iconColor;

    if (r.backupType == BackupType.contactPdf) {
      icon = Icons.picture_as_pdf_rounded;
      iconColor = AppColors.errorRed;
    } else if (r.backupType == BackupType.contactJson) {
      icon = Icons.data_object_rounded;
      iconColor = AppColors.successGreen;
    } else {
      icon = Icons.archive_rounded;
      iconColor = AppColors.primaryBlue;
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.filename,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.category} • ${DateFormatter.formatReadable(r.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: r.status),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Items: ${r.itemCount}  •  Size: ${FileSizeFormatter.format(r.outputSize)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (File(r.destination).existsSync()) ...[
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 19),
                  tooltip: 'Share',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: () {
                    ref.read(backupHistoryProvider.notifier).shareFile(r);
                  },
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.errorRed),
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () => _showDeleteConfirmation(context, ref, r),
              ),
            ],
          ),
          Text(
            r.destination,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, BackupRecord r) {
    bool deleteDiskFile = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete Backup Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete the record for "${r.filename}"?'),
              const SizedBox(height: 12),
              if (File(r.destination).existsSync())
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Also delete physical file from storage', style: TextStyle(fontSize: 13)),
                  value: deleteDiskFile,
                  onChanged: (val) {
                    setState(() => deleteDiskFile = val ?? true);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(backupHistoryProvider.notifier).deleteRecord(
                      r,
                      deleteFileFromDisk: deleteDiskFile,
                    );
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
