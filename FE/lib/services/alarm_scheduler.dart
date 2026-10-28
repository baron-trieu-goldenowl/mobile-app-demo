import 'dart:async';

import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../models/wake_log.dart';
import '../screens/ringing_screen.dart';
import 'alarm_service.dart';
import 'api_client.dart';
import 'notification_service.dart';
import 'wake_log_service.dart';

/// One ringing of an alarm (it may be snoozed several times).
class RingSession {
  final Alarm alarm;
  final DateTime scheduledAt;
  final int snoozeCount;

  /// True when this ring is the follow-up of an unanswered wake-up check.
  final bool isWakeCheck;

  const RingSession(
    this.alarm, {
    required this.scheduledAt,
    this.snoozeCount = 0,
    this.isWakeCheck = false,
  });

  bool get canSnooze =>
      alarm.canSnooze &&
      !isWakeCheck &&
      (alarm.snoozeLimit == 0 || snoozeCount < alarm.snoozeLimit);

  int? get snoozesLeft =>
      alarm.snoozeLimit == 0 ? null : alarm.snoozeLimit - snoozeCount;
}

class _Pending {
  final DateTime fireAt;
  final RingSession session;
  final int notificationId;

  _Pending(this.fireAt, this.session, this.notificationId);
}

/// Watches the clock and shows the ringing screen when an alarm is due.
///
/// Alarms ring in-app while the app is in the foreground; device
/// notifications (scheduled by [NotificationService]) cover the background
/// case and open the ringing screen when tapped.
class AlarmScheduler {
  AlarmScheduler._();
  static final AlarmScheduler instance = AlarmScheduler._();

  /// Global navigator key so we can push screens from outside the widget tree.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// How long the user has to confirm they are awake.
  static const wakeCheckDelay = Duration(minutes: 3);

  final _service = AlarmService();
  final _notif = NotificationService.instance;
  Timer? _timer;
  List<Alarm> _alarms = [];
  final List<_Pending> _pending = [];
  final Set<String> _firedKeys = {};
  bool _ringing = false;

  /// Deadline of the active wake-up check, if any.
  final wakeCheckDeadline = ValueNotifier<DateTime?>(null);

  /// Set while a quick alarm (nap timer) is counting down.
  final quickAlarmAt = ValueNotifier<DateTime?>(null);

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) => _tick());
    refresh();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Clears in-memory state (on logout).
  void reset() {
    _alarms = [];
    _pending.clear();
    wakeCheckDeadline.value = null;
    quickAlarmAt.value = null;
  }

  Future<void> refresh() async {
    if (ApiClient.instance.token == null) return;
    try {
      await _service.getAlarms(); // calls updateAlarms
    } catch (_) {
      // Keep the last known list when offline.
    }
  }

  void updateAlarms(List<Alarm> alarms) {
    _alarms = alarms;
  }

  /// The next enabled alarm and when it rings.
  (Alarm, DateTime)? nextAlarm() {
    (Alarm, DateTime)? best;
    final now = DateTime.now();
    for (final a in _alarms.where((a) => a.enabled)) {
      final at = a.nextTrigger(now);
      if (best == null || at.isBefore(best.$2)) best = (a, at);
    }
    return best;
  }

  void _tick() {
    final now = DateTime.now();

    for (final p in List.of(_pending)) {
      if (!p.fireAt.isAfter(now)) {
        _pending.remove(p);
        if (p.session.isWakeCheck) wakeCheckDeadline.value = null;
        if (p.session.alarm.id < 0) quickAlarmAt.value = null;
        _notif.cancel(p.notificationId);
        _ring(p.session);
      }
    }

    for (final a in _alarms) {
      if (!a.enabled) continue;
      if (now.hour != a.hour || now.minute != a.minute) continue;
      if (a.isRepeating && !a.repeatDays.contains(now.weekday)) continue;

      final key = '${a.id}-${now.year}-${now.month}-${now.day}-${a.time}';
      if (!_firedKeys.add(key)) continue;
      _ring(
        RingSession(
          a,
          scheduledAt: DateTime(now.year, now.month, now.day, a.hour, a.minute),
        ),
      );
    }
  }

  void _ring(RingSession session) {
    final nav = navigatorKey.currentState;
    if (nav == null || _ringing) return;
    _ringing = true;
    nav
        .push(
          MaterialPageRoute<void>(
            builder: (_) => RingingScreen(session: session),
            fullscreenDialog: true,
          ),
        )
        .whenComplete(() => _ringing = false);
  }

  /// Preview an alarm from the editor (does not log or snooze for real).
  void preview(Alarm alarm) {
    navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => RingingScreen(
          session: RingSession(alarm, scheduledAt: DateTime.now()),
          preview: true,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> snooze(RingSession session) async {
    final alarm = session.alarm;
    final fireAt = DateTime.now().add(Duration(minutes: alarm.snoozeMinutes));
    final next = RingSession(
      alarm,
      scheduledAt: session.scheduledAt,
      snoozeCount: session.snoozeCount + 1,
    );
    final id = NotificationService.snoozeId(alarm.id);
    _pending.add(_Pending(fireAt, next, id));
    if (alarm.id < 0) quickAlarmAt.value = fireAt;
    await _notif.scheduleAlarmAt(
      id: id,
      title: alarm.title,
      body: '💤 ${Alarm.formatTime(fireAt.hour, fireAt.minute)}',
      when: fireAt,
      payload: 'pending:$id',
      sound: alarm.sound,
    );
  }

  /// Start a nap / quick alarm that rings after [after].
  Future<void> startQuickAlarm(Duration after, {required String title}) async {
    await cancelQuickAlarm();
    final fireAt = DateTime.now().add(after);
    final alarm = Alarm(
      id: -1,
      title: title,
      time: Alarm.formatTime(fireAt.hour, fireAt.minute),
      snoozeLimit: 0,
    );
    const id = NotificationService.quickAlarmId;
    _pending.add(_Pending(fireAt, RingSession(alarm, scheduledAt: fireAt), id));
    quickAlarmAt.value = fireAt;
    await _notif.scheduleAlarmAt(
      id: id,
      title: title,
      body: Alarm.formatTime(fireAt.hour, fireAt.minute),
      when: fireAt,
      payload: 'pending:$id',
      sound: alarm.sound,
    );
  }

  Future<void> cancelQuickAlarm() async {
    _pending.removeWhere((p) => p.session.alarm.id < 0);
    quickAlarmAt.value = null;
    await _notif.cancel(NotificationService.quickAlarmId);
  }

  /// Called once the alarm is dismissed (mission completed).
  Future<void> complete(RingSession session, {int? missionSeconds}) async {
    final alarm = session.alarm;

    if (alarm.id > 0) {
      try {
        await WakeLogService().create(
          WakeLog(
            alarmId: alarm.id,
            alarmTitle: alarm.title,
            scheduledAt: session.scheduledAt,
            dismissedAt: DateTime.now(),
            snoozeCount: session.snoozeCount,
            challengeType: alarm.challengeType,
            missionSeconds: missionSeconds,
          ),
        );
      } catch (_) {
        // History is best-effort.
      }

      // A non-repeating alarm turns itself off after ringing.
      if (!alarm.isRepeating && !session.isWakeCheck) {
        try {
          await _service.setEnabled(alarm, false);
          await refresh();
        } catch (_) {}
      }
    }

    if (alarm.wakeUpCheck && !session.isWakeCheck) {
      final fireAt = DateTime.now().add(wakeCheckDelay);
      final id = NotificationService.wakeCheckId(alarm.id);
      _pending.add(
        _Pending(
          fireAt,
          RingSession(
            alarm,
            scheduledAt: session.scheduledAt,
            isWakeCheck: true,
          ),
          id,
        ),
      );
      wakeCheckDeadline.value = fireAt;
      await _notif.scheduleAlarmAt(
        id: id,
        title: alarm.title,
        body: '⏰ ${Alarm.formatTime(fireAt.hour, fireAt.minute)}',
        when: fireAt,
        payload: 'pending:$id',
        sound: alarm.sound,
      );
    }
  }

  /// The user confirmed they are awake: cancel the follow-up ring.
  Future<void> confirmAwake() async {
    final checks = _pending.where((p) => p.session.isWakeCheck).toList();
    for (final p in checks) {
      _pending.remove(p);
      await _notif.cancel(p.notificationId);
    }
    wakeCheckDeadline.value = null;
  }

  /// Called when the user taps a local notification.
  /// Payload is an alarm id, or `pending:<notificationId>` for snooze /
  /// quick alarm / wake-up check rings.
  Future<void> triggerByPayload(String? payload) async {
    if (payload == null) return;

    if (payload.startsWith('pending:')) {
      final id = int.tryParse(payload.substring(8));
      final match = _pending.where((p) => p.notificationId == id).toList();
      if (match.isEmpty) return;
      _pending.remove(match.first);
      if (match.first.session.isWakeCheck) wakeCheckDeadline.value = null;
      if (match.first.session.alarm.id < 0) quickAlarmAt.value = null;
      _ring(match.first.session);
      return;
    }

    final id = int.tryParse(payload);
    if (id == null) return;
    if (_alarms.isEmpty) await refresh();
    final match = _alarms.where((a) => a.id == id).toList();
    if (match.isEmpty) return;
    final a = match.first;
    final now = DateTime.now();
    _firedKeys.add('${a.id}-${now.year}-${now.month}-${now.day}-${a.time}');
    _ring(
      RingSession(
        a,
        scheduledAt: DateTime(now.year, now.month, now.day, a.hour, a.minute),
      ),
    );
  }
}
