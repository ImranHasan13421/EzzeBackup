import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../models/backup_record.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../backup_history/presentation/backup_history_controller.dart';
import '../../contact_backup/presentation/contact_backup_controller.dart';
import '../../settings/presentation/settings_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final locationState = ref.watch(backupLocationProvider);
    final historyState = ref.watch(backupHistoryProvider);
    final contactState = ref.watch(contactBackupProvider);

    final recentRecords = historyState.records.take(3).toList();
    final latestSuccess = historyState.records
        .where((r) => r.status == BackupStatus.completed || r.status == BackupStatus.completedWithWarnings)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/image/logo/applogo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Ezze Backup',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(backupHistoryProvider.notifier).loadHistory();
          ref.read(contactBackupProvider.notifier).loadSnapshot();
          ref.read(backupLocationProvider.notifier).loadLocation();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Storage Summary Card
            _buildStorageSummaryCard(context, locationState, latestSuccess),
            const SizedBox(height: 16),

            // Primary Feature Cards
            Row(
              children: [
                Expanded(
                  child: _buildFeatureActionCard(
                    context: context,
                    title: 'File Backup',
                    subtitle: 'Compress files into ZIP archives',
                    icon: Icons.archive_outlined,
                    iconColor: AppColors.primaryBlue,
                    buttonText: 'Back Up Files',
                    onTap: () => context.push('/file-backup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFeatureActionCard(
                    context: context,
                    title: 'Contact Backup',
                    subtitle: 'Save contacts as JSON & PDF',
                    icon: Icons.contact_phone_outlined,
                    iconColor: AppColors.successGreen,
                    buttonText: 'Back Up Contacts',
                    onTap: () => context.push('/contact-backup'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contact Snapshot Card
            if (contactState.snapshot != null) ...[
              _buildContactSnapshotCard(context, ref, contactState),
              const SizedBox(height: 16),
            ],

            // Recent Backups Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Backups',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (historyState.records.isNotEmpty)
                  TextButton(
                    onPressed: () => context.push('/history'),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent Backups List
            if (historyState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (recentRecords.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 40,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No backups created yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select files or contacts above to create your first backup.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentRecords.map((r) => _buildRecentRecordItem(context, ref, r)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSummaryCard(
    BuildContext context,
    BackupLocationState location,
    BackupRecord? latestSuccess,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_special_outlined, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Backup Location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const Spacer(),
              if (location.isCustom)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Custom',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            location.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Last Backup: ${latestSuccess != null ? DateFormatter.formatReadable(latestSuccess.completedAt ?? latestSuccess.createdAt) : 'None yet'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          AppButton(
            text: buttonText,
            onPressed: onTap,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSnapshotCard(
    BuildContext context,
    WidgetRef ref,
    ContactBackupState contactState,
  ) {
    final snapshot = contactState.snapshot!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(16),
      border: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Active Contact Snapshot',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${snapshot.contactCount} Contacts',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: ${DateFormatter.formatReadable(DateTime.tryParse(snapshot.updatedAt))}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            text: 'Update Numbers Backup',
            icon: Icons.sync_rounded,
            isFullWidth: true,
            isLoading: contactState.isSyncing,
            onPressed: () {
              ref.read(contactBackupProvider.notifier).syncContacts();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Preview PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  variant: ButtonVariant.outline,
                  isLoading: contactState.isExporting,
                  onPressed: () {
                    context.push('/contact-pdf-preview');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  text: 'Export JSON',
                  icon: Icons.data_object_rounded,
                  variant: ButtonVariant.secondary,
                  onPressed: () {
                    ref.read(contactBackupProvider.notifier).exportJson();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact JSON exported to Ezze Backup folder.')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordItem(
    BuildContext context,
    WidgetRef ref,
    BackupRecord record,
  ) {
    IconData icon;
    Color iconColor;
    if (record.backupType == BackupType.contactPdf) {
      icon = Icons.picture_as_pdf_rounded;
      iconColor = AppColors.errorRed;
    } else if (record.backupType == BackupType.contactJson) {
      icon = Icons.data_object_rounded;
      iconColor = AppColors.successGreen;
    } else {
      icon = Icons.folder_zip_rounded;
      iconColor = AppColors.primaryBlue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push('/history'),
        child: Row(
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
                    record.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormatter.formatReadable(record.createdAt)} • ${FileSizeFormatter.format(record.outputSize)} • ${record.itemCount} items',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: record.status),
          ],
        ),
      ),
    );
  }
}
