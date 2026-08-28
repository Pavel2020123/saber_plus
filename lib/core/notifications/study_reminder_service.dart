import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract interface class StudyReminderService {
  Future<bool> requestPermission();

  Future<void> scheduleDaily({required int hour, required int minute});

  Future<void> cancel();
}

class LocalStudyReminderService implements StudyReminderService {
  LocalStudyReminderService([FlutterLocalNotificationsPlugin? notifications])
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const _reminderId = 5100;
  static const _channelId = 'study_reminders';

  final FlutterLocalNotificationsPlugin _notifications;
  Future<void>? _initialization;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureInitialized() => _initialization ??= _initializePlugin();

  Future<void> _initializePlugin() async {
    if (!_isSupported) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_saber_plus'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    await _ensureInitialized();

    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    if (!_isSupported) return;
    await _ensureInitialized();
    await _notifications.zonedSchedule(
      id: _reminderId,
      title: 'Es hora de avanzar en SaberPlus',
      body: 'Una sesión corta hoy te acerca a tu meta ICFES.',
      scheduledDate: nextDailyReminder(hour: hour, minute: minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Recordatorios de estudio',
          channelDescription: 'Recordatorio diario elegido por el estudiante',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'study',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() async {
    if (!_isSupported) return;
    await _ensureInitialized();
    await _notifications.cancel(id: _reminderId);
  }
}

tz.TZDateTime nextDailyReminder({
  required int hour,
  required int minute,
  tz.TZDateTime? now,
}) {
  final current = now ?? tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(
    current.location,
    current.year,
    current.month,
    current.day,
    hour,
    minute,
  );
  if (!scheduled.isAfter(current)) {
    scheduled = tz.TZDateTime(
      current.location,
      current.year,
      current.month,
      current.day + 1,
      hour,
      minute,
    );
  }
  return scheduled;
}

final studyReminderServiceProvider = Provider<StudyReminderService>(
  (ref) => LocalStudyReminderService(),
);
