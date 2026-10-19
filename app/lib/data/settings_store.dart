import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsStore(prefs);
  }

  static const _nameKey = 'adventurer_name';
  static const _onboardedKey = 'onboarded_v1';
  static const _themeKey = 'theme_mode';
  static const _locationModeKey = 'location_mode';
  static const _cityNameKey = 'city_name';
  static const _cityLatKey = 'city_lat';
  static const _cityLonKey = 'city_lon';
  static const _lastBackupKey = 'last_backup_at';
  static const _lastBackupPathKey = 'last_backup_path';

  String get name {
    final value = _prefs.getString(_nameKey)?.trim() ?? '';
    return value.isEmpty ? '冒险者' : value;
  }

  Future<void> setName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_nameKey);
    } else {
      await _prefs.setString(_nameKey, trimmed);
    }
  }

  bool get onboarded => _prefs.getBool(_onboardedKey) ?? false;

  Future<void> setOnboarded(bool value) => _prefs.setBool(_onboardedKey, value);

  ThemeMode get themeMode {
    switch (_prefs.getString(_themeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_themeKey, mode.name);

  bool get autoLocation => (_prefs.getString(_locationModeKey) ?? 'manual') == 'auto';

  Future<void> setAutoLocation(bool value) =>
      _prefs.setString(_locationModeKey, value ? 'auto' : 'manual');

  String get cityName => _prefs.getString(_cityNameKey) ?? '西安';

  double get latitude => _prefs.getDouble(_cityLatKey) ?? 34.2583;

  double get longitude => _prefs.getDouble(_cityLonKey) ?? 108.9286;

  Future<void> setCity({required String name, required double latitude, required double longitude}) async {
    await _prefs.setString(_cityNameKey, name);
    await _prefs.setDouble(_cityLatKey, latitude);
    await _prefs.setDouble(_cityLonKey, longitude);
  }

  DateTime? get lastBackupAt =>
      DateTime.tryParse(_prefs.getString(_lastBackupKey) ?? '');

  String? get lastBackupPath => _prefs.getString(_lastBackupPathKey);

  Future<void> setLastBackupAt(DateTime value) =>
      _prefs.setString(_lastBackupKey, value.toIso8601String());

  Future<void> setLastBackupPath(String value) =>
      _prefs.setString(_lastBackupPathKey, value);

  Map<String, Object?> exportForBackup() => {
        'name': name,
        'theme_mode': themeMode.name,
        'location_mode': autoLocation ? 'auto' : 'manual',
        'city_name': cityName,
        'city_lat': latitude,
        'city_lon': longitude,
        'onboarded': true,
      };

  Future<void> importFromBackup(Map<String, Object?> data) async {
    final nameValue = data['name'];
    if (nameValue is String && nameValue.trim().isNotEmpty) {
      await setName(nameValue);
    }

    final themeName = data['theme_mode'];
    if (themeName is String) {
      for (final mode in ThemeMode.values) {
        if (mode.name == themeName) {
          await setThemeMode(mode);
          break;
        }
      }
    }

    final cityName = data['city_name'];
    final lat = (data['city_lat'] as num?)?.toDouble();
    final lon = (data['city_lon'] as num?)?.toDouble();
    if (cityName is String && cityName.trim().isNotEmpty && lat != null && lon != null) {
      await setCity(name: cityName, latitude: lat, longitude: lon);
    }

    final locationMode = data['location_mode'];
    if (locationMode is String) {
      await setAutoLocation(locationMode == 'auto');
    }

    await setOnboarded(true);
  }
}
