import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/mission.dart';
import '../models/wake_log.dart';
import '../services/wake_log_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Wake-up report: streak, average wake time, snoozes and history.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _service = WakeLogService();
  List<WakeLog> _logs = [];
  bool _loading = true;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    AppShell.currentTab.addListener(_onTab);
  }

  @override
  void dispose() {
    AppShell.currentTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (AppShell.currentTab.value == 3) _load(silent: _loadedOnce);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    _loadedOnce = true;
    try {
      _logs = await _service.getLogs();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// First wake-up per day (later alarms the same day are naps etc.).
  Map<DateTime, WakeLog> get _firstPerDay {
    final map = <DateTime, WakeLog>{};
    for (final log in _logs) {
      final key = _day(log.dismissedAt);
      final current = map[key];
      if (current == null || log.dismissedAt.isBefore(current.dismissedAt)) {
        map[key] = log;
      }
    }
    return map;
  }

  int get _streak {
    final days = _firstPerDay.keys.toSet();
    var day = _day(DateTime.now());
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String? get _averageWake {
    final logs = _firstPerDay.values.toList();
    if (logs.isEmpty) return null;
    final minutes =
        logs
            .map((l) => l.dismissedAt.hour * 60 + l.dismissedAt.minute)
            .reduce((a, b) => a + b) ~/
        logs.length;
    return '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final snoozes = _logs.fold<int>(0, (sum, l) => sum + l.snoozeCount);
    final missionLogs = _logs
        .where(
          (l) =>
              l.missionSeconds != null && (l.challengeType ?? 'none') != 'none',
        )
        .toList();
    final avgMission = missionLogs.isEmpty
        ? null
        : missionLogs.map((l) => l.missionSeconds!).reduce((a, b) => a + b) ~/
              missionLogs.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(s.report, style: theme.textTheme.headlineMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Text(
                  s.last30Days,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_logs.isEmpty)
                EmptyState(
                  icon: Icons.insights_rounded,
                  title: s.noReportYet,
                  subtitle: s.noReportYetHint,
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.sunrise,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 44)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.streakDays(_streak),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              s.streakHint,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.wb_twilight_rounded,
                        color: AppColors.accent,
                        value: _averageWake ?? '--:--',
                        label: s.avgWakeTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.snooze_rounded,
                        color: AppColors.violet,
                        value: '$snoozes',
                        label: s.totalSnoozes,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.alarm_on_rounded,
                        color: AppColors.task,
                        value: '${_logs.length}',
                        label: s.alarmsDismissed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.timer_outlined,
                        color: AppColors.event,
                        value: avgMission == null
                            ? '–'
                            : s.secondsShort(avgMission),
                        label: s.avgMissionTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionCard(
                  title: s.wakeTimeLast7,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  children: [_WeekChart(firstPerDay: _firstPerDay, s: s)],
                ),
                const SizedBox(height: 24),
                SectionCard(
                  title: s.history,
                  children: [
                    for (final log in _logs.take(15))
                      ListTile(
                        leading: IconBadge(
                          Mission.of(log.challengeType ?? 'none').icon,
                          color: Mission.of(log.challengeType ?? 'none').color,
                        ),
                        title: Text(log.alarmTitle ?? s.alarmSingular),
                        subtitle: Text(
                          DateFormat(
                                'EEE d MMM',
                                s.locale.languageCode,
                              ).format(log.dismissedAt) +
                              (log.snoozeCount > 0
                                  ? ' · ${s.snoozedTimes(log.snoozeCount)}'
                                  : ''),
                        ),
                        trailing: Text(
                          DateFormat('HH:mm').format(log.dismissedAt),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bars for the last 7 days; taller bar = earlier wake-up.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.firstPerDay, required this.s});

  final Map<DateTime, WakeLog> firstPerDay;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];
    // Scale: 03:00 (full bar) .. 12:00 (empty bar).
    double heightFor(DateTime t) {
      final minutes = t.hour * 60 + t.minute;
      return (1 - ((minutes - 180) / 540)).clamp(0.08, 1.0);
    }

    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    firstPerDay[d] == null
                        ? ''
                        : DateFormat('HH:mm')
                              .format(firstPerDay[d]!.dismissedAt),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 22,
                    height:
                        110 *
                        (firstPerDay[d] == null
                            ? 0.04
                            : heightFor(firstPerDay[d]!.dismissedAt)),
                    decoration: BoxDecoration(
                      gradient: firstPerDay[d] == null
                          ? null
                          : AppColors.sunrise,
                      color: firstPerDay[d] == null
                          ? theme.colorScheme.surfaceContainerHighest
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.weekdayShort(d.weekday),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
