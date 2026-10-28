import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';

/// Wraps flutter_local_notifications for scheduling alarms and reminders.
///
/// Notification ids per alarm: `id * 10` (one-time), `id * 10 + weekday`
/// (repeating), `id * 10 + 8` (snooze) and `id * 10 + 9` (wake-up check).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const quickAlarmId = 999998;
  static const taskReminderBase = 1500000000;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Callback invoked with the payload when a notification is tapped.
  void Function(String? payload)? onNotificationTap;

  static int snoozeId(int alarmId) =>
      alarmId > 0 ? alarmId * 10 + 8 : quickAlarmId;

  static int wakeCheckId(int alarmId) =>
      alarmId > 0 ? alarmId * 10 + 9 : quickAlarmId + 1;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (_) {
      // fallback to default
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );
    _initialized = true;
  }

  /// Payload of the notification that cold-started the app, if any.
  Future<String?> launchPayload() async {
    await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details!.notificationResponse?.payload;
  }

  Future<bool> requestPermissions() async {
    await init();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission() ?? false;
    // Opens system settings, so only ask when exact alarms are not allowed.
    if (await android?.canScheduleExactNotifications() == false) {
      await android?.requestExactAlarmsPermission();
    }
    return granted;
  }

  /// Alarm notifications play the alarm's own ringtone, bundled as
  /// `ios/Runner/Sounds/{sound}.wav` and Android `res/raw/{sound}.wav`.
  /// Android fixes the sound per channel, hence one channel per ringtone.
  NotificationDetails _alarmDetails({
    String sound = 'classic',
    bool vibration = true,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      'alarm_$sound',
      'Alarms ($sound)',
      channelDescription: 'Alarm reminders',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      enableVibration: vibration,
      sound: RawResourceAndroidNotificationSound(sound),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '$sound.wav',
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Task reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  /// Schedule (or cancel, when disabled) the device notifications for [alarm].
  Future<void> syncAlarm(Alarm alarm, {String? body}) async {
    await cancelAlarm(alarm.id);
    if (!alarm.enabled) return;

    final details = _alarmDetails(
      sound: alarm.sound,
      vibration: alarm.vibration,
    );
    if (alarm.repeatDays.isEmpty) {
      await _schedule(
        alarm.id * 10,
        alarm.title,
        body ?? alarm.time,
        _nextInstance(alarm.hour, alarm.minute),
        details,
        '${alarm.id}',
      );
      return;
    }
    for (final day in alarm.repeatDays) {
      await _schedule(
        alarm.id * 10 + day,
        alarm.title,
        body ?? alarm.time,
        _nextInstance(alarm.hour, alarm.minute, weekday: day),
        details,
        '${alarm.id}',
        match: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// One-shot alarm-style notification (snooze, quick alarm, wake-up check).
  Future<void> scheduleAlarmAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String payload,
    String sound = 'classic',
  }) async {
    await init();
    await _schedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _alarmDetails(sound: sound),
      payload,
    );
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    if (when.isBefore(DateTime.now())) return;
    await _schedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _reminderDetails,
      'task',
      exact: false,
    );
  }

  Future<void> _schedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
    NotificationDetails details,
    String payload, {
    DateTimeComponents? match,
    bool exact = true,
  }) async {
    await init();
    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      payload: payload,
      androidScheduleMode: mode,
      matchDateTimeComponents: match,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    try {
      await schedule(
        exact
            ? AndroidScheduleMode.alarmClock
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Exact alarms may be denied by the user; fall back to inexact.
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (_) {
        // scheduling failure should not crash the app
      }
    }
  }

  tz.TZDateTime _nextInstance(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (weekday != null) {
      // Move to the target weekday (1=Mon..7=Sun), then a week ahead if that
      // moment has already passed.
      var daysAhead = weekday - scheduled.weekday;
      if (daysAhead < 0) daysAhead += 7;
      scheduled = scheduled.add(Duration(days: daysAhead));
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }
    } else if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Cancels every notification that belongs to [alarmId] (all weekdays,
  /// snooze and wake-up check).
  Future<void> cancelAlarm(int alarmId) async {
    await init();
    for (var slot = 0; slot <= 9; slot++) {
      await _plugin.cancel(alarmId * 10 + slot);
    }
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
