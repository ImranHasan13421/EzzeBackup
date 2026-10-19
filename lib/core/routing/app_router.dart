import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/backup_history/presentation/backup_history_screen.dart';
import '../../features/contact_backup/presentation/contact_backup_screen.dart';
import '../../features/contact_backup/presentation/contact_pdf_preview_screen.dart';
import '../../features/file_backup/presentation/file_backup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/file-backup',
      builder: (context, state) => const FileBackupScreen(),
    ),
    GoRoute(
      path: '/contact-backup',
      builder: (context, state) => const ContactBackupScreen(),
    ),
    GoRoute(
      path: '/contact-pdf-preview',
      builder: (context, state) => const ContactPdfPreviewScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const BackupHistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
