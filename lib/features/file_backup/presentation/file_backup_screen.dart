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
      (FileBackupCategory.documents, Icons.description_rounded),
      (FileBackupCategory.images, Icons.image_rounded),
      (FileBackupCategory.videos, Icons.videocam_rounded),
      (FileBackupCategory.audio, Icons.audiotrack_rounded),
      (FileBackupCategory.other, Icons.insert_drive_file_rounded),
      (FileBackupCategory.custom, Icons.folder_open_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('File & Media Backup'),
        actions: [
          if (state.selectedFiles.isNotEmpty && !state.isBackingUp)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.errorRed),
                tooltip: 'Clear Selection',
                onPressed: () => notifier.clearSelection(),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = state.selectedCategory == cat.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
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
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                          color: isSelected ? Colors.white : null,
                          letterSpacing: -0.2,
                        ),
                        selectedColor: AppColors.primaryBlue,
                        checkmarkColor: Colors.white,
                        side: isSelected
                            ? BorderSide.none
                            : BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        onSelected: (selected) {
                          if (selected) notifier.selectCategory(cat.$1);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // File Selection Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Select ${state.selectedCategory}',
                    icon: Icons.add_circle_outline_rounded,
                    isLoading: state.isSelecting,
                    variant: ButtonVariant.gradient,
                    onPressed: state.isBackingUp ? null : () => notifier.pickFilesForCategory(),
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(
                  text: 'Folder',
                  icon: Icons.drive_folder_upload_rounded,
                  variant: ButtonVariant.secondary,
                  onPressed: state.isBackingUp ? null : () => notifier.pickFolder(),
                ),
              ],
            ),
          ),

          // In-Progress Live Status Card
          if (state.isBackingUp) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: AppCard(
                border: BorderSide(
                  color: AppColors.primaryBlue.withAlpha(isDark ? 60 : 40),
                  width: 1.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                            backgroundColor: AppColors.primaryBlue.withAlpha(30),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Compressing ${state.selectedCategory} into ZIP...',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(state.progress.percentage * 100).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: state.progress.percentage,
                        minHeight: 6,
                        backgroundColor: AppColors.primaryBlue.withAlpha(isDark ? 30 : 20),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(${state.progress.processedCount}/${state.progress.totalCount}) ${state.progress.currentFileName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
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
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withAlpha(isDark ? 15 : 10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_upload_rounded,
                              size: 42,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'No files selected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Select ${state.selectedCategory}" above to choose files to compress.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: state.selectedFiles.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = state.selectedFiles[index];
                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withAlpha(isDark ? 25 : 15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_rounded,
                                size: 20,
                                color: AppColors.primaryBlue,
                              ),
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
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${FileSizeFormatter.format(item.size)}  ·  ${item.relativePath}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!state.isBackingUp)
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                                visualDensity: VisualDensity.compact,
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 40 : 8),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
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
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Est. size: ${FileSizeFormatter.format(state.totalInputBytes)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'Create ZIP',
                      icon: Icons.archive_rounded,
                      variant: ButtonVariant.gradient,
                      isLoading: state.isBackingUp,
                      onPressed: state.isBackingUp ? null : () => notifier.executeBackup(context),
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Backup Completed', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.filename, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildDialogInfoRow('Files archived', '${record.itemCount}'),
            const SizedBox(height: 4),
            _buildDialogInfoRow('Original size', FileSizeFormatter.format(record.inputSize)),
            const SizedBox(height: 4),
            _buildDialogInfoRow('Compressed', FileSizeFormatter.format(record.outputSize)),
            const SizedBox(height: 10),
            Text(
              record.destination,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          AppButton(
            text: 'View History',
            variant: ButtonVariant.gradient,
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/history');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
