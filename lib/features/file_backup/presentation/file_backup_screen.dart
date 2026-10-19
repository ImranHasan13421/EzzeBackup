import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import 'file_backup_controller.dart';

class FileBackupScreen extends ConsumerWidget {
  const FileBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileBackupProvider);
    final notifier = ref.read(fileBackupProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<FileBackupState>(fileBackupProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      if (next.lastCompletedRecord != null &&
          next.lastCompletedRecord != prev?.lastCompletedRecord) {
        _showBackupCompleteDialog(context, next);
      }
    });

    final categories = [
      (FileBackupCategory.documents, Icons.description_outlined),
      (FileBackupCategory.images, Icons.image_outlined),
      (FileBackupCategory.videos, Icons.videocam_outlined),
      (FileBackupCategory.audio, Icons.audiotrack_outlined),
      (FileBackupCategory.other, Icons.insert_drive_file_outlined),
      (FileBackupCategory.custom, Icons.folder_open_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('File & Media Backup'),
        actions: [
          if (state.selectedFiles.isNotEmpty && !state.isBackingUp)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Selection',
              onPressed: () => notifier.clearSelection(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category Selector Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = state.selectedCategory == cat.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Icon(
                        cat.$2,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      label: Text(cat.$1),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : null,
                      ),
                      selectedColor: AppColors.primaryBlue,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        if (selected) notifier.selectCategory(cat.$1);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // File Selection Actions Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Select ${state.selectedCategory}',
                    icon: Icons.add_circle_outline_rounded,
                    isLoading: state.isSelecting,
                    onPressed: state.isBackingUp ? null : () => notifier.pickFilesForCategory(),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  text: 'Folder',
                  icon: Icons.drive_folder_upload_outlined,
                  variant: ButtonVariant.secondary,
                  onPressed: state.isBackingUp ? null : () => notifier.pickFolder(),
                ),
              ],
            ),
          ),

          // In-Progress Live Status Card
          if (state.isBackingUp) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppCard(
                color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEFF6FF),
                border: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Compressing ${state.selectedCategory} into ZIP...',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(state.progress.percentage * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: state.progress.percentage,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Processing (${state.progress.processedCount}/${state.progress.totalCount}): ${state.progress.currentFileName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Selected Files List
          Expanded(
            child: state.selectedFiles.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 56,
                            color: isDark
                                ? AppColors.darkTextSecondary.withAlpha(100)
                                : AppColors.lightTextSecondary.withAlpha(100),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No files selected yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Select ${state.selectedCategory}" above to choose documents, images, or media to compress.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.selectedFiles.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = state.selectedFiles[index];
                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file_outlined,
                              size: 24,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${FileSizeFormatter.format(item.size)}  •  ${item.relativePath}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (!state.isBackingUp)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => notifier.removeFile(item),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Confirmation Bar
          if (state.selectedFiles.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.selectedFiles.length} files selected',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Est. size: ${FileSizeFormatter.format(state.totalInputBytes)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'Create ZIP Backup',
                      icon: Icons.archive_rounded,
                      isLoading: state.isBackingUp,
                      onPressed: state.isBackingUp ? null : () => notifier.executeBackup(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showBackupCompleteDialog(BuildContext context, FileBackupState state) {
    final record = state.lastCompletedRecord;
    if (record == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 28),
            SizedBox(width: 10),
            Text('Backup Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archive: ${record.filename}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Files archived: ${record.itemCount}'),
            Text('Original size: ${FileSizeFormatter.format(record.inputSize)}'),
            Text('Compressed size: ${FileSizeFormatter.format(record.outputSize)}'),
            const SizedBox(height: 8),
            Text(
              'Saved to: ${record.destination}',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/history');
            },
            child: const Text('View In History'),
          ),
        ],
      ),
    );
  }
}
