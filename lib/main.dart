import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/service_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appContainer = ProviderContainer();

  try {
    final storage = appContainer.read(storageServiceProvider);
    await storage.initialize();

    final history = appContainer.read(backupHistoryServiceProvider);
    await history.initialize();
  } catch (e) {
    debugPrint('Startup warning: Storage initialization: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: appContainer,
      child: const EzzeBackupApp(),
    ),
  );
}
