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
      body: CustomScrollView(
        slivers: [
          // Premium AppBar with gradient
          _buildSliverAppBar(context, isDark),

          // Refresh wrapper
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(backupHistoryProvider.notifier).loadHistory();
                ref.read(contactBackupProvider.notifier).loadSnapshot();
                ref.read(backupLocationProvider.notifier).loadLocation();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Welcome Banner
                    _buildHeroBanner(context, isDark, locationState, latestSuccess),
                    const SizedBox(height: 20),

                    // Feature Action Cards
                    _buildSectionLabel(context, 'Quick Actions', isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureActionCard(
                            context: context,
                            isDark: isDark,
                            title: 'File Backup',
                            subtitle: 'Compress into ZIP',
                            icon: Icons.folder_zip_rounded,
                            gradientColors: [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                            onTap: () => context.push('/file-backup'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureActionCard(
                            context: context,
                            isDark: isDark,
                            title: 'Contact Backup',
                            subtitle: 'Save as JSON & PDF',
                            icon: Icons.contacts_rounded,
                            gradientColors: [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)],
                            onTap: () => context.push('/contact-backup'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Contact Snapshot Card
                    if (contactState.snapshot != null) ...[
                      _buildContactSnapshotCard(context, ref, contactState, isDark),
                      const SizedBox(height: 24),
                    ],

                    // Recent Backups
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionLabel(context, 'Recent Activity', isDark),
                        if (historyState.records.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => context.push('/history'),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('View All', style: TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (historyState.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (recentRecords.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      ...recentRecords.map((r) => _buildRecentRecordItem(context, ref, r, isDark)),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/image/logo/applogo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 28,
                  height: 28,
                  color: Colors.white,
                  child: const Icon(Icons.shield_rounded, color: AppColors.primaryBlue, size: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Ezze Backup',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    bool isDark,
    BackupLocationState location,
    BackupRecord? latestSuccess,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkSurfaceVariant, AppColors.darkSurface]
              : [const Color(0xFFEEF2FF), const Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_special_rounded, size: 20, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup Location',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (location.isCustom)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Custom',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  latestSuccess != null
                      ? 'Last backup: ${DateFormatter.formatReadable(latestSuccess.completedAt ?? latestSuccess.createdAt)}'
                      : 'No backups created yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildFeatureActionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(180),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSnapshotCard(
    BuildContext context,
    WidgetRef ref,
    ContactBackupState contactState,
    bool isDark,
  ) {
    final snapshot = contactState.snapshot!;

    return AppCard(
      padding: const EdgeInsets.all(18),
      border: BorderSide(
        color: AppColors.accentTeal.withAlpha(isDark ? 60 : 40),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_rounded, color: AppColors.accentTeal, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Contact Snapshot',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withAlpha(isDark ? 30 : 20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${snapshot.contactCount}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${DateFormatter.formatReadable(DateTime.tryParse(snapshot.updatedAt))}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Update Numbers Backup',
            icon: Icons.sync_rounded,
            isFullWidth: true,
            variant: ButtonVariant.gradient,
            isLoading: contactState.isSyncing,
            onPressed: () {
              ref.read(contactBackupProvider.notifier).syncContacts();
            },
          ),
          const SizedBox(height: 10),
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
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: 'Export JSON',
                  icon: Icons.data_object_rounded,
                  onPressed: () async {
                    final exported = await ref.read(contactBackupProvider.notifier).exportJson(context);
                    if (context.mounted && exported != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact JSON exported to Download/EzzeBackUp folder.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withAlpha(isDark ? 20 : 12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 32,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No backups yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first backup using the quick actions above.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecordItem(
    BuildContext context,
    WidgetRef ref,
    BackupRecord record,
    bool isDark,
  ) {
    IconData icon;
    Color iconColor;
    if (record.backupType == BackupType.contactPdf) {
      icon = Icons.picture_as_pdf_rounded;
      iconColor = AppColors.errorRed;
    } else if (record.backupType == BackupType.contactJson) {
      icon = Icons.data_object_rounded;
      iconColor = AppColors.accentTeal;
    } else {
      icon = Icons.folder_zip_rounded;
      iconColor = AppColors.primaryBlue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/history'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(isDark ? 30 : 18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormatter.formatReadable(record.createdAt)} · ${FileSizeFormatter.format(record.outputSize)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
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
