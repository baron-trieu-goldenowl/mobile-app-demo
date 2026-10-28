import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/app_strings.dart';
import '../models/alarm.dart';
import '../models/calendar_event.dart';
import '../models/task.dart';
import '../services/alarm_service.dart';
import '../services/auth_service.dart';
import '../services/calendar_service.dart';
import '../services/google_auth_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Calendar + agenda: Google Calendar events, local events, alarms and
/// tasks for the selected day.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _calendar = CalendarService();
  List<CalendarEvent> _events = [];
  List<Alarm> _alarms = [];
  List<Task> _tasks = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.week;
  bool _loading = true;
  bool _syncing = false;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    AppShell.currentTab.addListener(_onTab);
    AuthService.instance.addListener(_onUser);
  }

  @override
  void dispose() {
    AppShell.currentTab.removeListener(_onTab);
    AuthService.instance.removeListener(_onUser);
    super.dispose();
  }

  void _onTab() {
    if (AppShell.currentTab.value == 1) _load(silent: _loadedOnce);
  }

  void _onUser() {
    if (mounted) setState(() {});
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    _loadedOnce = true;
    final results = await Future.wait([
      _calendar.getEvents().catchError((_) => _events),
      AlarmService().getAlarms().catchError((_) => _alarms),
      TaskService().getTasks().catchError((_) => _tasks),
    ]);
    if (!mounted) return;
    setState(() {
      _events = results[0] as List<CalendarEvent>;
      _alarms = results[1] as List<Alarm>;
      _tasks = results[2] as List<Task>;
      _loading = false;
    });
  }

  Future<void> _sync() async {
    final s = AppStrings.of(context);
    setState(() => _syncing = true);
    try {
      _events = await _calendar.syncGoogle();
      if (mounted) showSnack(context, s.syncDone);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _connectGoogle() async {
    final s = AppStrings.of(context);
    setState(() => _syncing = true);
    try {
      final code = await GoogleAuthService.instance.requestCalendarAccess();
      if (code == null) return;
      await _calendar.connectGoogle(code);
      await _load(silent: true);
      if (mounted) showSnack(context, s.googleConnected);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<CalendarEvent> _eventsFor(DateTime day) =>
      _events.where((e) => _sameDay(e.startAt, day)).toList();

  List<_AgendaItem> _agendaFor(DateTime day, AppStrings s) {
    final items = <_AgendaItem>[];
    for (final e in _eventsFor(day)) {
      items.add(
        _AgendaItem(
          at: e.allDay ? DateTime(day.year, day.month, day.day) : e.startAt,
          time: e.allDay ? s.allDay : DateFormat('HH:mm').format(e.startAt),
          endTime: e.endAt == null || e.allDay
              ? null
              : DateFormat('HH:mm').format(e.endAt!),
          title: e.title,
          subtitle:
              e.location ?? (e.isGoogle ? 'Google Calendar' : s.personalEvent),
          color: e.isGoogle ? AppColors.event : AppColors.violet,
          icon: e.isGoogle ? Icons.event_rounded : Icons.event_note_rounded,
          onTap: () => _showEvent(e),
        ),
      );
    }
    for (final a in _alarms.where((a) => a.enabled)) {
      final rings = a.isRepeating
          ? a.repeatDays.contains(day.weekday)
          : _sameDay(a.nextTrigger(), day);
      if (!rings) continue;
      items.add(
        _AgendaItem(
          at: DateTime(day.year, day.month, day.day, a.hour, a.minute),
          time: a.time,
          title: a.title,
          subtitle: a.hasChallenge
              ? s.missionName(a.challengeType)
              : s.alarmSingular,
          color: AppColors.accent,
          icon: Icons.alarm_rounded,
          onTap: () => AppShell.currentTab.value = 0,
        ),
      );
    }
    for (final t in _tasks.where(
      (t) => t.dueAt != null && _sameDay(t.dueAt!, day),
    )) {
      items.add(
        _AgendaItem(
          at: t.dueAt!,
          time: DateFormat('HH:mm').format(t.dueAt!),
          title: t.title,
          subtitle: s.priorityName(t.priority),
          color: AppColors.task,
          icon: t.isDone
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          done: t.isDone,
          onTap: () => AppShell.currentTab.value = 2,
        ),
      );
    }
    items.sort((a, b) => a.at.compareTo(b.at));
    return items;
  }

  Future<void> _showEvent(CalendarEvent e) async {
    final s = AppStrings.of(context);
    final locale = s.locale.languageCode;
    final theme = Theme.of(context);
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(
                    e.isGoogle ? Icons.event_rounded : Icons.event_note_rounded,
                    color: e.isGoogle ? AppColors.event : AppColors.violet,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e.title, style: theme.textTheme.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                e.allDay
                    ? '${DateFormat('EEEE, d MMMM', locale).format(e.startAt)} · ${s.allDay}'
                    : '${DateFormat('EEEE, d MMMM · HH:mm', locale).format(e.startAt)}'
                          '${e.endAt != null ? ' – ${DateFormat('HH:mm').format(e.endAt!)}' : ''}',
              ),
              if (e.location != null && e.location!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.location!)),
                  ],
                ),
              ],
              if (e.description != null && e.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  e.description!,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 20),
              if (e.isGoogle)
                Text(
                  s.googleEventReadOnly,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(s.delete),
                ),
            ],
          ),
        ),
      ),
    );
    if (deleted == true) {
      try {
        await _calendar.deleteEvent(e.id);
        setState(() => _events.removeWhere((x) => x.id == e.id));
      } catch (err) {
        if (mounted) showSnack(context, err.toString());
      }
    }
  }

  Future<void> _addEvent() async {
    final event = await showModalBottomSheet<CalendarEvent>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EventSheet(day: _selectedDay),
    );
    if (event == null) return;
    try {
      final created = await _calendar.createEvent(event);
      setState(() => _events.add(created));
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final connected =
        AuthService.instance.currentUser?.googleConnected ?? false;
    final agenda = _agendaFor(_selectedDay, s);
    final locale = s.locale.languageCode;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-event',
        onPressed: _addEvent,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: connected ? _sync : _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.schedule,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    if (connected)
                      IconButton(
                        tooltip: s.syncGoogle,
                        onPressed: _syncing ? null : _sync,
                        icon: _syncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                      ),
                    IconButton(
                      tooltip: _format == CalendarFormat.week
                          ? s.monthView
                          : s.weekView,
                      icon: Icon(
                        _format == CalendarFormat.week
                            ? Icons.calendar_view_month_rounded
                            : Icons.view_week_rounded,
                      ),
                      onPressed: () => setState(
                        () => _format = _format == CalendarFormat.week
                            ? CalendarFormat.month
                            : CalendarFormat.week,
                      ),
                    ),
                  ],
                ),
              ),
              if (!connected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const GoogleLogo(size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.connectGoogleTitle,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  s.connectGoogleHint,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _syncing ? null : _connectGoogle,
                            child: Text(s.connect),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TableCalendar(
                  locale: locale,
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarFormat: _format,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  selectedDayPredicate: (d) => _sameDay(d, _selectedDay),
                  eventLoader: _eventsFor,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: theme.textTheme.titleMedium!,
                    leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                    rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    weekendStyle: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedDecoration: const BoxDecoration(
                      gradient: AppColors.sunrise,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.event,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    markerSize: 5,
                    weekendTextStyle: const TextStyle(color: AppColors.accent),
                  ),
                  onDaySelected: (selected, focused) => setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  }),
                  onPageChanged: (focused) => _focusedDay = focused,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  _sameDay(_selectedDay, DateTime.now())
                      ? '${s.today} · ${DateFormat('d MMMM', locale).format(_selectedDay)}'
                      : DateFormat('EEEE, d MMMM', locale).format(_selectedDay),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (agenda.isEmpty)
                EmptyState(
                  icon: Icons.wb_sunny_outlined,
                  title: s.nothingScheduled,
                  subtitle: s.nothingScheduledHint,
                )
              else
                for (final item in agenda) _AgendaTile(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaItem {
  final DateTime at;
  final String time;
  final String? endTime;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool done;
  final VoidCallback onTap;

  _AgendaItem({
    required this.at,
    required this.time,
    this.endTime,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.done = false,
    required this.onTap,
  });
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.item});

  final _AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 56,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.time, style: theme.textTheme.labelLarge),
                    if (item.endTime != null)
                      Text(
                        item.endTime!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Material(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: item.onTap,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: item.color, width: 4),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  decoration: item.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(item.icon, color: item.color, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create a personal (local) event.
class _EventSheet extends StatefulWidget {
  const _EventSheet({required this.day});

  final DateTime day;

  @override
  State<_EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<_EventSheet> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _date = widget.day;
  TimeOfDay _start = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: 0,
  );
  late TimeOfDay _end = TimeOfDay(hour: (_start.hour + 1) % 24, minute: 0);
  bool _allDay = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay t) =>
      DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final start = _allDay
        ? DateTime(_date.year, _date.month, _date.day)
        : _at(_start);
    var end = _allDay ? start.add(const Duration(days: 1)) : _at(_end);
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    Navigator.pop(
      context,
      CalendarEvent(
        id: 0,
        title: title,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        startAt: start,
        endAt: end,
        allDay: _allDay,
        source: 'local',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final locale = s.locale.languageCode;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.newEvent, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: s.title),
              ),
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.today_rounded),
                      title: Text(
                        DateFormat('EEEE, d MMMM yyyy', locale).format(_date),
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (d != null) setState(() => _date = d);
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.wb_sunny_outlined),
                      title: Text(s.allDay),
                      value: _allDay,
                      onChanged: (v) => setState(() => _allDay = v),
                    ),
                    if (!_allDay)
                      ListTile(
                        leading: const Icon(Icons.schedule_rounded),
                        title: Row(
                          children: [
                            TextButton(
                              onPressed: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _start,
                                );
                                if (t != null) setState(() => _start = t);
                              },
                              child: Text(
                                _start.format(context),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const Text('→'),
                            TextButton(
                              onPressed: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _end,
                                );
                                if (t != null) setState(() => _end = t);
                              },
                              child: Text(
                                _end.format(context),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  hintText: s.location,
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: s.note,
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _submit, child: Text(s.save)),
            ],
          ),
        ),
      ),
    );
  }
}
