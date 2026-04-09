import 'package:flutter/material.dart';

import '../../core/system/theme_settings_repository.dart';

class AppController extends ChangeNotifier {
  AppController({required ThemeSettingsRepository themeRepo})
      : _themeRepo = themeRepo;

  final ThemeSettingsRepository _themeRepo;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    final stored = await _themeRepo.getThemeMode();
    _themeMode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _themeRepo.setThemeMode(
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
    notifyListeners();
  }
}

