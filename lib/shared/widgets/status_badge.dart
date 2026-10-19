import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/backup_record.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case BackupStatus.completed:
        bg = AppColors.successGreenSubtle;
        fg = AppColors.successGreen;
        icon = Icons.check_circle_rounded;
        break;
      case BackupStatus.completedWithWarnings:
        bg = AppColors.warningAmberSubtle;
        fg = AppColors.warningAmber;
        icon = Icons.warning_amber_rounded;
        break;
      case BackupStatus.failed:
        bg = AppColors.errorRedSubtle;
        fg = AppColors.errorRed;
        icon = Icons.cancel_rounded;
        break;
      case BackupStatus.inProgress:
        bg = AppColors.primaryBlueSubtle;
        fg = AppColors.primaryBlue;
        icon = Icons.hourglass_top_rounded;
        break;
      case BackupStatus.cancelled:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        icon = Icons.block_rounded;
        break;
      default:
        bg = AppColors.primaryBlueSubtle;
        fg = AppColors.primaryBlue;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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
            ),
          ),
        ],
      ),
    );
  }
}
