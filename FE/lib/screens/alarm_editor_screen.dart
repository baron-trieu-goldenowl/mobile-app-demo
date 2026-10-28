import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/alarm.dart';
import '../models/mission.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'qr_scan_screen.dart';

/// Create / edit an alarm. Pops `true` when something was saved or deleted.
class AlarmEditorScreen extends StatefulWidget {
  const AlarmEditorScreen({super.key, this.alarm});

  final Alarm? alarm;

  @override
  State<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends State<AlarmEditorScreen> {
  final _service = AlarmService();
  late Alarm _draft;
  late final TextEditingController _titleCtrl;
  bool _saving = false;

  bool get _isNew => widget.alarm == null;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.alarm ??
        const Alarm(
          id: 0,
          title: '',
          time: '06:30',
          repeatDays: [1, 2, 3, 4, 5],
        );
    _titleCtrl = TextEditingController(text: _draft.title);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    SoundService.instance.stop();
    super.dispose();
  }

  void _update(Alarm Function(Alarm a) change) =>
      setState(() => _draft = change(_draft));

  Alarm _withTitle(AppStrings s) {
    final title = _titleCtrl.text.trim();
    return _draft.copyWith(title: title.isEmpty ? s.alarm : title);
  }

  Future<void> _save() async {
    final s = AppStrings.of(context);
    if (_draft.challengeType == 'qr' && (_draft.qrCode ?? '').isEmpty) {
      showSnack(context, s.qrNotRegistered);
      return;
    }
    setState(() => _saving = true);
    try {
      final alarm = _withTitle(s).copyWith(enabled: true);
      final saved = _isNew
          ? await _service.createAlarm(alarm)
          : await _service.updateAlarm(alarm.id, alarm.toJson());
      await AlarmScheduler.instance.refresh();
      if (!mounted) return;
      showSnack(
        context,
        s.ringsIn(saved.nextTrigger().difference(DateTime.now())),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    try {
      await _service.deleteAlarm(_draft.id);
      await AlarmScheduler.instance.refresh();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    }
  }

  Future<void> _pickMission() async {
    final result = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MissionSheet(alarm: _draft),
    );
    if (result != null) setState(() => _draft = result);
  }

  Future<void> _pickSound() async {
    final result = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SoundSheet(alarm: _draft),
    );
    await SoundService.instance.stop();
    if (result != null) setState(() => _draft = result);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final mission = Mission.of(_draft.challengeType);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? s.addAlarm : s.editAlarm),
        actions: [
          TextButton.icon(
            onPressed: () => AlarmScheduler.instance.preview(_withTitle(s)),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(s.preview),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: GradientButton(
            label: s.save,
            loading: _saving,
            onPressed: _save,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            s.ringsIn(_draft.nextTrigger(now).difference(now)),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 190,
            child: CupertinoDatePicker(
              key: ValueKey(widget.alarm?.id),
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: DateTime(
                now.year,
                now.month,
                now.day,
                _draft.hour,
                _draft.minute,
              ),
              onDateTimeChanged: (d) => _update(
                (a) => a.copyWith(time: Alarm.formatTime(d.hour, d.minute)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: s.repeat,
            padding: const EdgeInsets.all(14),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var d = 1; d <= 7; d++)
                    _DayToggle(
                      label: s.weekdayShort(d),
                      selected: _draft.repeatDays.contains(d),
                      onTap: () => _update((a) {
                        final days = {...a.repeatDays};
                        days.contains(d) ? days.remove(d) : days.add(d);
                        return a.copyWith(repeatDays: days.toList()..sort());
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final preset in [
                    (s.everyday, const [1, 2, 3, 4, 5, 6, 7]),
                    (s.weekdays, const [1, 2, 3, 4, 5]),
                    (s.weekends, const [6, 7]),
                    (s.once, const <int>[]),
                  ])
                    ChoiceChip(
                      label: Text(preset.$1),
                      selected: _sameDays(_draft.repeatDays, preset.$2),
                      onSelected: (_) =>
                          _update((a) => a.copyWith(repeatDays: preset.$2)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: s.label,
            padding: const EdgeInsets.all(12),
            children: [
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: s.labelHint,
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: s.mission,
            children: [
              ListTile(
                onTap: _pickMission,
                leading: IconBadge(mission.icon, color: mission.color),
                title: Text(s.missionName(_draft.challengeType)),
                subtitle: Text(
                  _draft.hasChallenge
                      ? s.difficultyName(_draft.challengeDifficulty)
                      : s.missionNoneHint,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: s.soundAndVibration,
            children: [
              ListTile(
                onTap: _pickSound,
                leading: const IconBadge(
                  Icons.music_note_rounded,
                  color: AppColors.violet,
                ),
                title: Text(s.soundName(_draft.sound)),
                subtitle: Text(
                  '${s.volume} ${_draft.volume}%${_draft.gradualVolume ? ' · ${s.gradualVolume}' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
              SwitchListTile(
                secondary: const IconBadge(
                  Icons.vibration_rounded,
                  color: AppColors.warning,
                ),
                title: Text(s.vibration),
                value: _draft.vibration,
                onChanged: (v) => _update((a) => a.copyWith(vibration: v)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: s.snooze,
            padding: const EdgeInsets.all(14),
            children: [
              Text(s.snoozeInterval, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in const [0, 1, 3, 5, 10, 15])
                    ChoiceChip(
                      label: Text(m == 0 ? s.off : s.minutesShort(m)),
                      selected: _draft.snoozeMinutes == m,
                      onSelected: (_) =>
                          _update((a) => a.copyWith(snoozeMinutes: m)),
                    ),
                ],
              ),
              if (_draft.canSnooze) ...[
                const SizedBox(height: 14),
                Text(s.snoozeLimit, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in const [1, 2, 3, 5, 10, 0])
                      ChoiceChip(
                        label: Text(n == 0 ? s.unlimited : s.timesCount(n)),
                        selected: _draft.snoozeLimit == n,
                        onSelected: (_) =>
                            _update((a) => a.copyWith(snoozeLimit: n)),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: s.wakeUpCheck,
            children: [
              SwitchListTile(
                secondary: const IconBadge(
                  Icons.verified_user_outlined,
                  color: AppColors.task,
                ),
                title: Text(s.wakeUpCheck),
                subtitle: Text(s.wakeUpCheckHint),
                value: _draft.wakeUpCheck,
                onChanged: (v) => _update((a) => a.copyWith(wakeUpCheck: v)),
              ),
            ],
          ),
          if (!_isNew) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(s.deleteAlarm),
            ),
          ],
        ],
      ),
    );
  }

  static bool _sameDays(List<int> a, List<int> b) =>
      a.length == b.length && a.toSet().containsAll(b);
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: selected ? AppColors.sunrise : null,
          color: selected ? null : theme.colorScheme.surfaceContainerHigh,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Pick the mission (and difficulty / QR code) needed to dismiss the alarm.
class _MissionSheet extends StatefulWidget {
  const _MissionSheet({required this.alarm});

  final Alarm alarm;

  @override
  State<_MissionSheet> createState() => _MissionSheetState();
}

class _MissionSheetState extends State<_MissionSheet> {
  late Alarm _alarm = widget.alarm;

  Future<void> _registerQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanScreen.register()),
    );
    if (code != null) setState(() => _alarm = _alarm.copyWith(qrCode: code));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final needsDifficulty = const [
      'math',
      'memory',
      'typing',
      'shake',
      'walk',
      'puzzle',
    ].contains(_alarm.challengeType);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(s.mission, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            s.missionHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final m in Mission.all)
                _MissionTile(
                  mission: m,
                  title: s.missionName(m.type),
                  subtitle: s.missionDesc(m.type),
                  selected: _alarm.challengeType == m.type,
                  onTap: () => setState(
                    () => _alarm = _alarm.copyWith(challengeType: m.type),
                  ),
                ),
            ],
          ),
          if (needsDifficulty) ...[
            const SizedBox(height: 20),
            Text(s.difficulty, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final d in const ['easy', 'medium', 'hard'])
                  ButtonSegment(value: d, label: Text(s.difficultyName(d))),
              ],
              selected: {_alarm.challengeDifficulty},
              onSelectionChanged: (v) => setState(
                () => _alarm = _alarm.copyWith(challengeDifficulty: v.first),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.missionGoal(_alarm.challengeType, _alarm.challengeDifficulty),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (_alarm.challengeType == 'qr') ...[
            const SizedBox(height: 20),
            Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: ListTile(
                leading: Icon(
                  (_alarm.qrCode ?? '').isEmpty
                      ? Icons.qr_code_2_rounded
                      : Icons.check_circle_rounded,
                  color: (_alarm.qrCode ?? '').isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : AppColors.task,
                ),
                title: Text(
                  (_alarm.qrCode ?? '').isEmpty
                      ? s.qrNotRegistered
                      : s.qrRegistered,
                ),
                subtitle: Text(s.qrRegisterHint),
                trailing: TextButton(
                  onPressed: _registerQr,
                  child: Text(s.scan),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (_alarm.hasChallenge) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => AlarmScheduler.instance.preview(
                      _alarm.copyWith(
                        title: _alarm.title.isEmpty ? s.alarm : _alarm.title,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(s.tryIt),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _alarm),
                  child: Text(s.done),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.mission,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Mission mission;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected
            ? mission.color.withValues(alpha: 0.14)
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? mission.color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(mission.icon, color: mission.color, size: 36),
              const Spacer(),
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundSheet extends StatefulWidget {
  const _SoundSheet({required this.alarm});

  final Alarm alarm;

  @override
  State<_SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<_SoundSheet> {
  late Alarm _alarm = widget.alarm;
  final _sound = SoundService.instance;

  void _select(String sound) {
    setState(() => _alarm = _alarm.copyWith(sound: sound));
    _sound.preview(sound, volume: _alarm.volume);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.sound, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final sound in SoundService.sounds)
              ListTile(
                onTap: () => _select(sound),
                leading: Icon(
                  _alarm.sound == sound
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: _alarm.sound == sound ? AppColors.accent : null,
                ),
                title: Text(s.soundName(sound)),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  onPressed: () => _sound.preview(sound, volume: _alarm.volume),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.volume_down_rounded),
                Expanded(
                  child: Slider(
                    value: _alarm.volume.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 9,
                    label: '${_alarm.volume}%',
                    onChanged: (v) => setState(
                      () => _alarm = _alarm.copyWith(volume: v.round()),
                    ),
                    onChangeEnd: (_) =>
                        _sound.preview(_alarm.sound, volume: _alarm.volume),
                  ),
                ),
                const Icon(Icons.volume_up_rounded),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.gradualVolume),
              subtitle: Text(s.gradualVolumeHint),
              value: _alarm.gradualVolume,
              onChanged: (v) =>
                  setState(() => _alarm = _alarm.copyWith(gradualVolume: v)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context, _alarm),
              child: Text(s.done),
            ),
          ],
        ),
      ),
    );
  }
}
