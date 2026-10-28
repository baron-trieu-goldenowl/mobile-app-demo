import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/alarm.dart';
import '../models/calendar_event.dart';
import '../models/task.dart';
import '../services/alarm_scheduler.dart';
import '../services/auth_service.dart';
import '../services/calendar_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Morning briefing shown right after the alarm is dismissed: wake-up
/// check (if enabled) and today's agenda from the calendar and tasks.
class MorningScreen extends StatefulWidget {
  const MorningScreen({super.key, required this.alarm});

  final Alarm alarm;

  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen> {
  final _wakeTime = DateTime.now();
  List<CalendarEvent> _events = [];
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    bool sameDay(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;
    try {
      final results = await Future.wait([
        CalendarService().getEvents(),
        TaskService().getTasks(),
      ]);
      _events =
          (results[0] as List<CalendarEvent>)
              .where((e) => sameDay(e.startAt))
              .toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
      _tasks = (results[1] as List<Task>)
          .where(
            (t) =>
                !t.isDone &&
                (t.dueAt == null ||
                    !t.dueAt!.isAfter(
                      DateTime(now.year, now.month, now.day, 23, 59),
                    )),
          )
          .take(5)
          .toList();
    } catch (_) {
      // The briefing is optional; show what we have.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final name = AuthService.instance.currentUser?.name;
    final locale = s.locale.languageCode;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.paddingOf(context).top + 32,
              24,
              32,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.sunrise,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Colors.white,
                  size: 44,
                ),
                const SizedBox(height: 16),
                Text(
                  name == null || name.isEmpty
                      ? s.greeting(_wakeTime)
                      : '${s.greeting(_wakeTime)}\n$name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.wokeUpAt(DateFormat('HH:mm').format(_wakeTime)),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMMM', locale).format(_wakeTime),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<DateTime?>(
                  valueListenable: AlarmScheduler.instance.wakeCheckDeadline,
                  builder: (context, deadline, _) => deadline == null
                      ? const SizedBox.shrink()
                      : _WakeCheckCard(deadline: deadline, s: s),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  SectionCard(
                    title: s.todaySchedule,
                    children: [
                      if (_events.isEmpty)
                        ListTile(
                          leading: const IconBadge(
                            Icons.event_available_rounded,
                            color: AppColors.event,
                          ),
                          title: Text(s.noEventsToday),
                        )
                      else
                        for (final e in _events)
                          ListTile(
                            leading: IconBadge(
                              e.isGoogle
                                  ? Icons.event_rounded
                                  : Icons.event_note_rounded,
                              color: AppColors.event,
                            ),
                            title: Text(e.title),
                            subtitle: Text(
                              e.allDay
                                  ? s.allDay
                                  : DateFormat('HH:mm').format(e.startAt),
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: s.todayTasks,
                    children: [
                      if (_tasks.isEmpty)
                        ListTile(
                          leading: const IconBadge(
                            Icons.task_alt_rounded,
                            color: AppColors.task,
                          ),
                          title: Text(s.noTasksToday),
                        )
                      else
                        for (final t in _tasks)
                          ListTile(
                            leading: const IconBadge(
                              Icons.radio_button_unchecked_rounded,
                              color: AppColors.task,
                            ),
                            title: Text(t.title),
                            subtitle: t.dueAt == null
                                ? null
                                : Text(DateFormat('HH:mm').format(t.dueAt!)),
                          ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                GradientButton(
                  label: s.startDay,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WakeCheckCard extends StatefulWidget {
  const _WakeCheckCard({required this.deadline, required this.s});

  final DateTime deadline;
  final AppStrings s;

  @override
  State<_WakeCheckCard> createState() => _WakeCheckCardState();
}

class _WakeCheckCardState extends State<_WakeCheckCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.deadline.difference(DateTime.now());
    final safe = left.isNegative ? Duration.zero : left;
    final mm = safe.inMinutes.toString().padLeft(2, '0');
    final ss = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return Card(
      color: AppColors.task.withValues(alpha: 0.14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const IconBadge(
              Icons.verified_user_rounded,
              color: AppColors.task,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.s.areYouAwake,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    widget.s.confirmWithin('$mm:$ss'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.task,
                minimumSize: const Size(0, 44),
              ),
              onPressed: AlarmScheduler.instance.confirmAwake,
              child: Text(widget.s.imAwake),
            ),
          ],
        ),
      ),
    );
  }
}
