import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/study_reminder_service.dart';
import 'app_preferences.dart';
import 'app_preferences_store.dart';

class NotificationPermissionDenied implements Exception {
  const NotificationPermissionDenied();
}

class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  @override
  Future<AppPreferences> build() async {
    final preferences = await ref.read(appPreferencesStoreProvider).load();
    if (preferences.reminderEnabled) {
      unawaited(
        ref
            .read(studyReminderServiceProvider)
            .scheduleDaily(
              hour: preferences.reminderHour,
              minute: preferences.reminderMinute,
            )
            .catchError((Object _) {}),
      );
    }
    return preferences;
  }

  Future<void> setTheme(ThemePreference theme) async {
    final current = state.valueOrNull;
    if (current == null || current.theme == theme) return;
    final updated = current.copyWith(theme: theme);
    state = AsyncData(updated);
    try {
      await ref.read(appPreferencesStoreProvider).save(updated);
    } on Object {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null || current.reminderEnabled == enabled) return;
    final service = ref.read(studyReminderServiceProvider);

    if (enabled) {
      final granted = await service.requestPermission();
      if (!granted) throw const NotificationPermissionDenied();
      await service.scheduleDaily(
        hour: current.reminderHour,
        minute: current.reminderMinute,
      );
    } else {
      await service.cancel();
    }

    final updated = current.copyWith(reminderEnabled: enabled);
    try {
      await ref.read(appPreferencesStoreProvider).save(updated);
      state = AsyncData(updated);
    } on Object {
      if (enabled) {
        await service.cancel();
      } else {
        await service.scheduleDaily(
          hour: current.reminderHour,
          minute: current.reminderMinute,
        );
      }
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setReminderTime({required int hour, required int minute}) async {
    final current = state.valueOrNull;
    if (current == null ||
        (current.reminderHour == hour && current.reminderMinute == minute)) {
      return;
    }
    final updated = current.copyWith(
      reminderHour: hour,
      reminderMinute: minute,
    );
    final service = ref.read(studyReminderServiceProvider);
    if (current.reminderEnabled) {
      await service.scheduleDaily(hour: hour, minute: minute);
    }
    try {
      await ref.read(appPreferencesStoreProvider).save(updated);
      state = AsyncData(updated);
    } on Object {
      if (current.reminderEnabled) {
        await service.scheduleDaily(
          hour: current.reminderHour,
          minute: current.reminderMinute,
        );
      }
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setExamCountdownMinimized(bool minimized) async {
    final current = state.valueOrNull;
    if (current == null || current.examCountdownMinimized == minimized) return;
    final updated = current.copyWith(examCountdownMinimized: minimized);
    state = AsyncData(updated);
    try {
      await ref.read(appPreferencesStoreProvider).save(updated);
    } on Object {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setAnswerStreakVibrationEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null || current.answerStreakVibrationEnabled == enabled) {
      return;
    }
    final updated = current.copyWith(answerStreakVibrationEnabled: enabled);
    state = AsyncData(updated);
    try {
      await ref.read(appPreferencesStoreProvider).save(updated);
    } on Object {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setAnswerStreakSoundEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null || current.answerStreakSoundEnabled == enabled) return;
    final updated = current.copyWith(answerStreakSoundEnabled: enabled);
    state = AsyncData(updated);
    try {
      await ref.read(appPreferencesStoreProvider).save(updated);
    } on Object {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final appPreferencesControllerProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );
