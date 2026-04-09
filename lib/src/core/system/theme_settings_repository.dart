import '../db/app_database.dart';

class ThemeSettingsRepository {
  ThemeSettingsRepository({required AppDatabase db}) : _db = db;
  final AppDatabase _db;

  static const _kThemeMode = 'theme_mode'; // system|light|dark

  Future<String?> getThemeMode() => _db.getSetting(_kThemeMode);
  Future<void> setThemeMode(String mode) => _db.setSetting(_kThemeMode, mode);
}

