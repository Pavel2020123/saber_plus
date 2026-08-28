import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';

abstract interface class AppPreferencesStore {
  Future<AppPreferences> load();

  Future<void> save(AppPreferences preferences);
}

class SharedPreferencesAppPreferencesStore implements AppPreferencesStore {
  SharedPreferencesAppPreferencesStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _themeKey = 'saberplus.theme';
  static const _reminderEnabledKey = 'saberplus.reminder.enabled';
  static const _reminderHourKey = 'saberplus.reminder.hour';
  static const _reminderMinuteKey = 'saberplus.reminder.minute';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppPreferences> load() async {
    final values = await Future.wait<Object?>([
      _preferences.getString(_themeKey),
      _preferences.getBool(_reminderEnabledKey),
      _preferences.getInt(_reminderHourKey),
      _preferences.getInt(_reminderMinuteKey),
    ]);
    final hour = values[2] as int?;
    final minute = values[3] as int?;

    return AppPreferences(
      theme: ThemePreference.fromStorage(values[0] as String?),
      reminderEnabled: values[1] as bool? ?? false,
      reminderHour: hour != null && hour >= 0 && hour <= 23 ? hour : 18,
      reminderMinute: minute != null && minute >= 0 && minute <= 59
          ? minute
          : 0,
    );
  }

  @override
  Future<void> save(AppPreferences preferences) async {
    await Future.wait<void>([
      _preferences.setString(_themeKey, preferences.theme.storageValue),
      _preferences.setBool(_reminderEnabledKey, preferences.reminderEnabled),
      _preferences.setInt(_reminderHourKey, preferences.reminderHour),
      _preferences.setInt(_reminderMinuteKey, preferences.reminderMinute),
    ]);
  }
}

final appPreferencesStoreProvider = Provider<AppPreferencesStore>(
  (ref) => SharedPreferencesAppPreferencesStore(),
);
