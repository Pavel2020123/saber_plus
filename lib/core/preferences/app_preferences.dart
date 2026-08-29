enum ThemePreference {
  light('light', 'Claro'),
  dark('dark', 'Oscuro'),
  system('system', 'Automático');

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
    this.answerStreakVibrationEnabled = true,
    this.answerStreakSoundEnabled = true,
  });

  final ThemePreference theme;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool examCountdownMinimized;
  final bool answerStreakVibrationEnabled;
  final bool answerStreakSoundEnabled;

  AppPreferences copyWith({
    ThemePreference? theme,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? examCountdownMinimized,
    bool? answerStreakVibrationEnabled,
    bool? answerStreakSoundEnabled,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    examCountdownMinimized:
        examCountdownMinimized ?? this.examCountdownMinimized,
    answerStreakVibrationEnabled:
        answerStreakVibrationEnabled ?? this.answerStreakVibrationEnabled,
    answerStreakSoundEnabled:
        answerStreakSoundEnabled ?? this.answerStreakSoundEnabled,
  );
}
