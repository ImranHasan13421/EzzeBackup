import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'features/settings/presentation/settings_controller.dart';

class EzzeBackupApp extends ConsumerWidget {
  const EzzeBackupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: createLightTheme(),
      darkTheme: createDarkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
