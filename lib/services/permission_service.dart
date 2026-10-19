import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_theme.dart';
import '../shared/widgets/app_button.dart';

class PermissionService {
  /// Checks whether storage/file management permission is granted.
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Check MANAGE_EXTERNAL_STORAGE for Android 11+ (API 30+)
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Check standard storage permission (Android 10 and below)
    if (await Permission.storage.isGranted) {
      return true;
    }

    return false;
  }

  /// Requests storage/file access permission directly.
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Request MANAGE_EXTERNAL_STORAGE on Android 11+
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) {
      return true;
    }

    // Fallback to standard storage permission (Android 10 and below)
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Opens the device App Settings page
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Ensures storage permission is granted. If not, shows an explanatory dialog
  /// asking the user to grant permission so files can be saved in Download/EzzeBackUp.
  Future<bool> ensureStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final hasPerm = await hasStoragePermission();
    if (hasPerm) return true;

    if (!context.mounted) return false;

    // Show educational rationale dialog
    final userWantsToGrant = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildPermissionDialog(ctx),
    );

    if (userWantsToGrant != true) {
      return false;
    }

    // Request permission
    final granted = await requestStoragePermission();
    if (granted) {
      return true;
    }

    // If still not granted, notify user and provide Open Settings shortcut
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'All Files Access is required to save backups into Download/EzzeBackUp.',
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => openSettings(),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return false;
  }

  Widget _buildPermissionDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandStart.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.folder_shared_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'File Access Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ezze Backup saves your ZIP archives and contact PDFs directly into your device’s visible Download folder:',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.folder_open_rounded, size: 16, color: AppColors.brandStart),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Download/EzzeBackUp',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Under Android security policies, saving visible files outside hidden app directories requires "All files access". Please tap Grant Access to enable it.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Not Now',
                variant: ButtonVariant.outline,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                text: 'Grant Access',
                variant: ButtonVariant.gradient,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
