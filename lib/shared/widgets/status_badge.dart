import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/backup_record.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case BackupStatus.completed:
        bg = isDark ? AppColors.successGreen.withAlpha(30) : AppColors.successGreenSubtle;
        fg = AppColors.successGreen;
        icon = Icons.check_circle_rounded;
        break;
      case BackupStatus.completedWithWarnings:
        bg = isDark ? AppColors.warningAmber.withAlpha(30) : AppColors.warningAmberSubtle;
        fg = AppColors.warningAmber;
        icon = Icons.warning_amber_rounded;
        break;
      case BackupStatus.failed:
        bg = isDark ? AppColors.errorRed.withAlpha(30) : AppColors.errorRedSubtle;
        fg = AppColors.errorRed;
        icon = Icons.cancel_rounded;
        break;
      case BackupStatus.inProgress:
        bg = isDark ? AppColors.primaryBlue.withAlpha(30) : AppColors.primaryBlueSubtle;
        fg = AppColors.primaryBlue;
        icon = Icons.hourglass_top_rounded;
        break;
      case BackupStatus.cancelled:
        bg = isDark ? Colors.grey.withAlpha(30) : Colors.grey.shade100;
        fg = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;
        icon = Icons.block_rounded;
        break;
      default:
        bg = isDark ? AppColors.primaryBlue.withAlpha(30) : AppColors.primaryBlueSubtle;
        fg = AppColors.primaryBlue;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
