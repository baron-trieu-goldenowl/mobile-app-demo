import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/mission.dart';
import '../services/alarm_scheduler.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'challenge_screen.dart';
import 'morning_screen.dart';

/// Full-screen alarm: plays the ringtone until the user snoozes or
/// completes the mission.
class RingingScreen extends StatefulWidget {
  const RingingScreen({super.key, required this.session, this.preview = false});

  final RingSession session;

  /// Preview from the editor: no snooze scheduling, logging or briefing.
  final bool preview;

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen>
    with SingleTickerProviderStateMixin {
  final _sound = SoundService.instance;
  late final AnimationController _pulse;
  Timer? _clock;
  Timer? _vibrate;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    final alarm = widget.session.alarm;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _sound.startAlarm(
      alarm.sound,
      volume: alarm.volume,
      gradual: alarm.gradualVolume,
    );
    if (alarm.vibration) {
      _vibrate = Timer.periodic(
        const Duration(milliseconds: 1500),
        (_) => HapticFeedback.vibrate(),
      );
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _clock?.cancel();
    _vibrate?.cancel();
    _sound.stop();
    super.dispose();
  }

  void _stopRinging() {
    _vibrate?.cancel();
    _sound.stop();
  }

  Future<void> _snooze() async {
    _stopRinging();
    if (!widget.preview) await AlarmScheduler.instance.snooze(widget.session);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _dismiss() async {
    final alarm = widget.session.alarm;
    int? missionSeconds;
    if (alarm.hasChallenge) {
      _vibrate?.cancel();
      await _sound.duck();
      if (!mounted) return;
      final started = DateTime.now();
      final solved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ChallengeScreen(alarm: alarm),
          fullscreenDialog: true,
        ),
      );
      if (solved != true) {
        // Back out of the mission: keep ringing.
        await _sound.unduck();
        return;
      }
      missionSeconds = DateTime.now().difference(started).inSeconds;
    }

    _stopRinging();
    if (!mounted) return;
    if (widget.preview) {
      Navigator.pop(context);
      return;
    }

    await AlarmScheduler.instance.complete(
      widget.session,
      missionSeconds: missionSeconds,
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => MorningScreen(alarm: alarm)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final alarm = widget.session.alarm;
    final mission = Mission.of(alarm.challengeType);
    final locale = s.locale.languageCode;
    final left = widget.session.snoozesLeft;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.night),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  if (widget.preview)
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    DateFormat('EEEE, d MMMM', locale).format(_now),
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(_now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 92,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -3,
                    ),
                  ),
                  Text(
                    widget.session.isWakeCheck ? s.wakeCheckRing : alarm.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ScaleTransition(
                    scale: Tween(begin: 0.92, end: 1.08).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.sunrise,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPink.withValues(alpha: 0.55),
                            blurRadius: 60,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.alarm_rounded,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (alarm.hasChallenge)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(mission.icon, color: mission.color, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            s.missionToDismiss(
                              s.missionName(alarm.challengeType),
                            ),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  _RingButton(
                    label: alarm.hasChallenge ? s.startMission : s.dismiss,
                    gradient: AppColors.sunrise,
                    onTap: _dismiss,
                  ),
                  if (widget.session.canSnooze) ...[
                    const SizedBox(height: 12),
                    _RingButton(
                      label: left == null
                          ? s.snoozeFor(alarm.snoozeMinutes)
                          : '${s.snoozeFor(alarm.snoozeMinutes)} · ${s.snoozesLeft(left)}',
                      onTap: _snooze,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingButton extends StatelessWidget {
  const _RingButton({required this.label, required this.onTap, this.gradient});

  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? Colors.white.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: SizedBox(
            height: 62,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
