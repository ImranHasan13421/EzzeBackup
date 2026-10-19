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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Storage Location
          _buildSectionHeader('Storage & Export Folder'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.folder_shared_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Export Destination',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            locationState.isCustom ? 'Custom Storage Folder' : 'Default App Storage',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: locationState.isCustom
                            ? AppColors.primaryBlueSubtle
                            : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        locationState.isCustom ? 'Custom' : 'Default',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: locationState.isCustom
                              ? AppColors.primaryBlue
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Path container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 16,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationState.path,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'ZIP archives, contact PDFs, and JSON files are saved into the dedicated Download/EzzeBackUp folder, making them directly accessible in your device file manager. The active contact snapshot is kept encrypted in sandboxed private storage.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.35,
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
                  'Display Mode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Interactive Theme Mode Selector Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeModeOption(
                        mode: ThemeMode.system,
                        label: 'System',
                        icon: Icons.brightness_auto_rounded,
                        isSelected: themeMode == ThemeMode.system,
                        isDark: isDark,
                        onTap: () => themeNotifier.setTheme(ThemeMode.system),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildThemeModeOption(
                        mode: ThemeMode.light,
                        label: 'Light',
                        icon: Icons.light_mode_rounded,
                        isSelected: themeMode == ThemeMode.light,
                        isDark: isDark,
                        onTap: () => themeNotifier.setTheme(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildThemeModeOption(
                        mode: ThemeMode.dark,
                        label: 'Dark',
                        icon: Icons.dark_mode_rounded,
                        isSelected: themeMode == ThemeMode.dark,
                        isDark: isDark,
                        onTap: () => themeNotifier.setTheme(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Coming Later (Roadmap)
          _buildSectionHeader('Product Roadmap'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildUpcomingFeatureItem(
                  icon: Icons.lock_outline_rounded,
                  iconGradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  title: 'Encrypted Password Vault',
                  subtitle: 'Keystore authenticated zero-knowledge vault for sensitive credentials.',
                ),
                const Divider(height: 20),
                _buildUpcomingFeatureItem(
                  icon: Icons.cloud_sync_outlined,
                  iconGradient: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
                  title: 'Automated Scheduled Backups',
                  subtitle: 'Scheduled background backup to cloud drives and external storage.',
                ),
                const Divider(height: 20),
                _buildUpcomingFeatureItem(
                  icon: Icons.restore_rounded,
                  iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
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
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.successGreenSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.successGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% Offline & Private',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            'Zero telemetry • No external tracking',
                            style: TextStyle(fontSize: 11, color: AppColors.successGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Ezze Backup contains zero third-party analytics, advertisements, or background tracking. Contacts and files are processed strictly on your device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('App Version', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v${AppConstants.appVersion}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.brandStart,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildThemeModeOption({
    required ThemeMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.brandStart.withAlpha(40) : AppColors.primaryBlueSubtle)
              : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.brandStart
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.brandStart
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.brandStart)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingFeatureItem({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: iconGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
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
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Roadmap',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
