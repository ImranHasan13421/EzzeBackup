import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/service_providers.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefThemeMode);
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(AppConstants.prefThemeMode, 'dark');
    } else if (mode == ThemeMode.light) {
      await prefs.setString(AppConstants.prefThemeMode, 'light');
    } else {
      await prefs.remove(AppConstants.prefThemeMode);
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class BackupLocationState {
  final String path;
  final bool isCustom;
  final bool isLoading;

  const BackupLocationState({
    required this.path,
    required this.isCustom,
    this.isLoading = false,
  });

  BackupLocationState copyWith({
    String? path,
    bool? isCustom,
    bool? isLoading,
  }) {
    return BackupLocationState(
      path: path ?? this.path,
      isCustom: isCustom ?? this.isCustom,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BackupLocationNotifier extends StateNotifier<BackupLocationState> {
  final Ref _ref;

  BackupLocationNotifier(this._ref)
      : super(const BackupLocationState(path: 'Loading...', isCustom: false, isLoading: true)) {
    loadLocation();
  }

  Future<void> loadLocation() async {
    state = state.copyWith(isLoading: true);
    final storage = _ref.read(storageServiceProvider);
    final custom = await storage.getCustomBackupPath();
    final effectiveDir = await storage.getUserAccessibleBackupDir();
    state = BackupLocationState(
      path: effectiveDir.path,
      isCustom: custom != null && custom.isNotEmpty,
      isLoading: false,
    );
  }

  Future<void> setCustomLocation(String newPath) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setCustomBackupPath(newPath);
    await loadLocation();
  }

  Future<void> resetToDefault() async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setCustomBackupPath(null);
    await loadLocation();
  }
}

final backupLocationProvider =
    StateNotifierProvider<BackupLocationNotifier, BackupLocationState>((ref) {
  return BackupLocationNotifier(ref);
});
