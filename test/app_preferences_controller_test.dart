import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/notifications/study_reminder_service.dart';
import 'package:saber_plus/core/preferences/app_preferences.dart';
import 'package:saber_plus/core/preferences/app_preferences_controller.dart';
import 'package:saber_plus/core/preferences/app_preferences_store.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('cambia el tema y lo persiste', () async {
    final store = _MemoryPreferencesStore();
    final reminders = _FakeReminderService();
    final container = _container(store, reminders);
    addTearDown(container.dispose);

    await container.read(appPreferencesControllerProvider.future);
    await container
        .read(appPreferencesControllerProvider.notifier)
        .setTheme(ThemePreference.dark);

    expect(
      container.read(appPreferencesControllerProvider).valueOrNull?.theme,
      ThemePreference.dark,
    );
    expect(store.value.theme, ThemePreference.dark);
  });

  test('no activa el recordatorio si el permiso es rechazado', () async {
    final store = _MemoryPreferencesStore();
    final reminders = _FakeReminderService(permissionGranted: false);
    final container = _container(store, reminders);
    addTearDown(container.dispose);

    await container.read(appPreferencesControllerProvider.future);
    await expectLater(
      container
          .read(appPreferencesControllerProvider.notifier)
          .setReminderEnabled(true),
      throwsA(isA<NotificationPermissionDenied>()),
    );

    expect(store.value.reminderEnabled, isFalse);
    expect(reminders.scheduleCalls, 0);
  });

  test('activa, reprograma y cancela el recordatorio', () async {
    final store = _MemoryPreferencesStore();
    final reminders = _FakeReminderService();
    final container = _container(store, reminders);
    addTearDown(container.dispose);

    await container.read(appPreferencesControllerProvider.future);
    final controller = container.read(
      appPreferencesControllerProvider.notifier,
    );
    await controller.setReminderEnabled(true);
    await controller.setReminderTime(hour: 7, minute: 30);
    await controller.setReminderEnabled(false);

    expect(reminders.permissionRequests, 1);
    expect(reminders.scheduleCalls, 2);
    expect(reminders.lastHour, 7);
    expect(reminders.lastMinute, 30);
    expect(reminders.cancelCalls, 1);
    expect(store.value.reminderEnabled, isFalse);
    expect(store.value.reminderHour, 7);
    expect(store.value.reminderMinute, 30);
  });

  test('restaura el recordatorio si falla guardar al desactivarlo', () async {
    final store = _MemoryPreferencesStore();
    final reminders = _FakeReminderService();
    final container = _container(store, reminders);
    addTearDown(container.dispose);

    await container.read(appPreferencesControllerProvider.future);
    final controller = container.read(
      appPreferencesControllerProvider.notifier,
    );
    await controller.setReminderEnabled(true);
    store.failOnSave = true;

    await expectLater(controller.setReminderEnabled(false), throwsException);

    expect(reminders.cancelCalls, 1);
    expect(reminders.scheduleCalls, 2);
    expect(
      container
          .read(appPreferencesControllerProvider)
          .valueOrNull
          ?.reminderEnabled,
      isTrue,
    );
  });

  test('calcula la siguiente hora diaria sin programar en el pasado', () {
    tz_data.initializeTimeZones();
    final location = tz.getLocation('America/Bogota');
    final now = tz.TZDateTime(location, 2026, 8, 28, 18, 30);

    final sameDay = nextDailyReminder(hour: 19, minute: 0, now: now);
    final nextDay = nextDailyReminder(hour: 18, minute: 0, now: now);

    expect(sameDay, tz.TZDateTime(location, 2026, 8, 28, 19));
    expect(nextDay, tz.TZDateTime(location, 2026, 8, 29, 18));
  });
}

ProviderContainer _container(
  AppPreferencesStore store,
  StudyReminderService reminders,
) => ProviderContainer(
  overrides: [
    appPreferencesStoreProvider.overrideWithValue(store),
    studyReminderServiceProvider.overrideWithValue(reminders),
  ],
);

class _MemoryPreferencesStore implements AppPreferencesStore {
  AppPreferences value = const AppPreferences();
  bool failOnSave = false;

  @override
  Future<AppPreferences> load() async => value;

  @override
  Future<void> save(AppPreferences preferences) async {
    if (failOnSave) throw Exception('storage unavailable');
    value = preferences;
  }
}

class _FakeReminderService implements StudyReminderService {
  _FakeReminderService({this.permissionGranted = true});

  final bool permissionGranted;
  int permissionRequests = 0;
  int scheduleCalls = 0;
  int cancelCalls = 0;
  int? lastHour;
  int? lastMinute;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    scheduleCalls++;
    lastHour = hour;
    lastMinute = minute;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }
}
