import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Plays alarm ringtones bundled in assets/sounds/.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const sounds = ['classic', 'digital', 'chime', 'rising', 'birds'];

  /// Seconds to go from quiet to full volume when gradual volume is on.
  static const rampSeconds = 30;

  final _player = AudioPlayer();
  Timer? _ramp;
  double _target = 1;
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    // Ring even when the iOS silent switch is on and keep the device awake.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(stayAwake: true).build(),
    );
  }

  Future<void> startAlarm(
    String sound, {
    required int volume,
    bool gradual = true,
  }) async {
    await _configure();
    await stop();
    _target = (volume / 100).clamp(0.05, 1.0);
    final start = gradual ? 0.08 : _target;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(_source(sound), volume: start);
    if (gradual) {
      final step = (_target - start) / rampSeconds;
      var current = start;
      _ramp = Timer.periodic(const Duration(seconds: 1), (t) {
        current = (current + step).clamp(0, _target);
        _player.setVolume(current);
        if (current >= _target) t.cancel();
      });
    }
  }

  /// Lower the volume while the user is doing the mission.
  Future<void> duck() async {
    _ramp?.cancel();
    await _player.setVolume(_target * 0.25);
  }

  Future<void> unduck() async {
    await _player.setVolume(_target);
  }

  Future<void> preview(String sound, {int volume = 80}) async {
    await _configure();
    await stop();
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(_source(sound), volume: (volume / 100).clamp(0.05, 1.0));
  }

  Future<void> stop() async {
    _ramp?.cancel();
    _ramp = null;
    await _player.stop();
  }

  Source _source(String sound) => AssetSource(
    'sounds/${sounds.contains(sound) ? sound : sounds.first}.wav',
  );
}
