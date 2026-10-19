import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final locationState = ref.watch(backupLocationProvider);
    final locationNotifier = ref.read(backupLocationProvider.notifier);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Storage Location
          _buildSectionHeader('Storage & Export Location'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_shared_outlined, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    const Text(
                      'Export Destination Folder',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    if (locationState.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Custom',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  locationState.path,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
                Text(
                  'ZIP archives and exported contact PDFs/JSONs are saved into subfolders here (Files, Media, Contacts). The active contact database is kept in private sandboxed storage.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Choose Folder',
                        icon: Icons.drive_folder_upload_outlined,
                        variant: ButtonVariant.secondary,
                        onPressed: () async {
                          final picked = await FilePicker.getDirectoryPath();
                          if (picked != null) {
                            await locationNotifier.setCustomLocation(picked);
                          }
                        },
                      ),
                    ),
                    if (locationState.isCustom) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          text: 'Reset Default',
                          variant: ButtonVariant.outline,
                          onPressed: () async {
                            await locationNotifier.resetToDefault();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Theme / Appearance
          _buildSectionHeader('Appearance & Theme'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Preference',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_rounded, size: 18),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (newSelection) {
                      themeNotifier.setTheme(newSelection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Coming Later (Roadmap)
          _buildSectionHeader('Coming in Future Updates'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildUpcomingFeatureItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Encrypted Password Vault',
                  subtitle: 'Keystore authenticated zero-knowledge vault for sensitive credentials.',
                ),
                const Divider(height: 16),
                _buildUpcomingFeatureItem(
                  icon: Icons.cloud_sync_outlined,
                  title: 'Automated Scheduled Backups',
                  subtitle: 'Scheduled background backup to cloud drives and external storage.',
                ),
                const Divider(height: 16),
                _buildUpcomingFeatureItem(
                  icon: Icons.restore_rounded,
                  title: 'Archive & Contact Restoration',
                  subtitle: 'One-tap restore from validated ZIP archives and contact snapshots.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: Privacy & App Details
          _buildSectionHeader('Privacy & Application Information'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: AppColors.successGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '100% Offline & Private',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Ezze Backup contains zero third-party analytics, advertisements, or background tracking. Contacts and files are processed strictly on your device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('App Version', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(
                      AppConstants.appVersion,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryBlue,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildUpcomingFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Coming Later', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
