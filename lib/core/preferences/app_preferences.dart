enum ThemePreference {
  light('light', 'Claro'),
  dark('dark', 'Oscuro');

  const ThemePreference(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ThemePreference fromStorage(String? value) => values.firstWhere(
    (preference) => preference.storageValue == value,
    orElse: () => ThemePreference.light,
  );
}

class AppPreferences {
  const AppPreferences({
    this.theme = ThemePreference.light,
    this.reminderEnabled = false,
    this.reminderHour = 18,
    this.reminderMinute = 0,
    this.examCountdownMinimized = true,
  });

  final ThemePreference theme;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool examCountdownMinimized;

  AppPreferences copyWith({
    ThemePreference? theme,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? examCountdownMinimized,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    examCountdownMinimized:
        examCountdownMinimized ?? this.examCountdownMinimized,
  );
}
