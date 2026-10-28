import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../models/alarm.dart';
import '../models/mission.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import 'alarm_editor_screen.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final _service = AlarmService();
  final _scheduler = AlarmScheduler.instance;
  List<Alarm> _alarms = [];
  bool _loading = true;
  String? _error;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _load();
    _askPermissionsOnce();
    // Keep "rings in ..." fresh.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    AppShell.currentTab.addListener(_onTab);
  }

  void _onTab() {
    if (AppShell.currentTab.value == 0) _load(silent: true);
  }

  @override
  void dispose() {
    _clock?.cancel();
    AppShell.currentTab.removeListener(_onTab);
    super.dispose();
  }

  Future<void> _askPermissionsOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('asked_notification_permission') == true) return;
    await prefs.setBool('asked_notification_permission', true);
    await NotificationService.instance.requestPermissions();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final alarms = await _service.getAlarms();
      alarms.sort((a, b) => a.time.compareTo(b.time));
      _alarms = alarms;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(Alarm alarm, bool enabled) async {
    final s = AppStrings.of(context);
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    setState(() => _alarms[index] = alarm.copyWith(enabled: enabled));
    try {
      final updated = await _service.setEnabled(alarm, enabled);
      _alarms[index] = updated;
      _scheduler.updateAlarms(_alarms);
      if (enabled && mounted) {
        showSnack(
          context,
          s.ringsIn(updated.nextTrigger().difference(DateTime.now())),
        );
      }
    } catch (e) {
      _alarms[index] = alarm;
      if (mounted) showSnack(context, e.toString());
    }
    if (mounted) setState(() {});
  }

  Future<bool> _confirmDelete(Alarm alarm) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteAlarm),
        content: Text('${alarm.time} · ${alarm.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(88, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    try {
      await _service.deleteAlarm(alarm.id);
      _alarms.removeWhere((a) => a.id == alarm.id);
      _scheduler.updateAlarms(_alarms);
      if (mounted) setState(() {});
      return true;
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
      return false;
    }
  }

  Future<void> _openEditor([Alarm? alarm]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AlarmEditorScreen(alarm: alarm)),
    );
    if (changed == true) await _load(silent: true);
  }

  Future<void> _quickAlarm() async {
    final s = AppStrings.of(context);
    final minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => _QuickAlarmSheet(s: s),
    );
    if (minutes == null) return;
    await _scheduler.startQuickAlarm(
      Duration(minutes: minutes),
      title: s.quickAlarm,
    );
    if (mounted) showSnack(context, s.ringsIn(Duration(minutes: minutes)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-alarm',
        onPressed: _openEditor,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addAlarm),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.alarm,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: s.quickAlarm,
                        icon: const Icon(Icons.bolt_rounded),
                        onPressed: _quickAlarm,
                      ),
                      IconButton(
                        tooltip: s.notifications,
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/notifications'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _NextAlarmCard(alarms: _alarms, s: s),
                      ValueListenableBuilder<DateTime?>(
                        valueListenable: _scheduler.quickAlarmAt,
                        builder: (context, at, _) => at == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _QuickAlarmBanner(at: at, s: s),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _alarms.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: s.loadFailed,
                    subtitle: _error,
                    action: OutlinedButton(
                      onPressed: _load,
                      child: Text(s.retry),
                    ),
                  ),
                )
              else if (_alarms.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.alarm_add_rounded,
                    title: s.noAlarms,
                    subtitle: s.noAlarmsHint,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: _alarms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final alarm = _alarms[i];
                      return Dismissible(
                        key: ValueKey(alarm.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(alarm),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 28),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        child: _AlarmCard(
                          alarm: alarm,
                          s: s,
                          onTap: () => _openEditor(alarm),
                          onToggle: (v) => _toggle(alarm, v),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextAlarmCard extends StatelessWidget {
  const _NextAlarmCard({required this.alarms, required this.s});

  final List<Alarm> alarms;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    (Alarm, DateTime)? next;
    for (final a in alarms.where((a) => a.enabled)) {
      final at = a.nextTrigger(now);
      if (next == null || at.isBefore(next.$2)) next = (a, at);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: next == null ? AppColors.dusk : AppColors.sunrise,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: (next == null ? AppColors.violet : AppColors.accentPink)
                .withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next == null ? s.noActiveAlarm : s.nextAlarm,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? s.noActiveAlarmHint
                      : s.ringsIn(next.$2.difference(now)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${s.weekdayLong(next.$2.weekday)} · ${next.$1.time} · ${next.$1.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              next == null ? Icons.bedtime_rounded : Icons.wb_twilight_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.s,
    required this.onTap,
    required this.onToggle,
  });

  final Alarm alarm;
  final AppStrings s;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mission = Mission.of(alarm.challengeType);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: alarm.enabled ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                      Text(
                        alarm.time,
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (alarm.isRepeating)
                            for (var d = 1; d <= 7; d++)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  s.weekdayShort(d),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: alarm.repeatDays.contains(d)
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: alarm.repeatDays.contains(d)
                                        ? AppColors.accent
                                        : muted.withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                          else
                            Text(
                              s.once,
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (alarm.hasChallenge)
                  Tooltip(
                    message: s.missionName(alarm.challengeType),
                    child: IconBadge(
                      mission.icon,
                      color: mission.color,
                      size: 36,
                    ),
                  ),
                const SizedBox(width: 8),
                Switch(value: alarm.enabled, onChanged: onToggle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAlarmBanner extends StatefulWidget {
  const _QuickAlarmBanner({required this.at, required this.s});

  final DateTime at;
  final AppStrings s;

  @override
  State<_QuickAlarmBanner> createState() => _QuickAlarmBannerState();
}

class _QuickAlarmBannerState extends State<_QuickAlarmBanner> {
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
    final left = widget.at.difference(DateTime.now());
    final safe = left.isNegative ? Duration.zero : left;
    final mm = safe.inMinutes.toString().padLeft(2, '0');
    final ss = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return Card(
      child: ListTile(
        leading: const IconBadge(Icons.bolt_rounded, color: AppColors.warning),
        title: Text(widget.s.quickAlarm),
        subtitle: Text('$mm:$ss'),
        trailing: TextButton(
          onPressed: AlarmScheduler.instance.cancelQuickAlarm,
          child: Text(widget.s.cancel),
        ),
      ),
    );
  }
}

class _QuickAlarmSheet extends StatelessWidget {
  const _QuickAlarmSheet({required this.s});

  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.quickAlarm, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              s.quickAlarmHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final m in const [1, 5, 10, 15, 20, 30, 45, 60, 90])
                  Material(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(context, m),
                      child: Center(
                        child: Text(
                          s.minutesShort(m),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
