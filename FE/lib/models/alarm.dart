import '../utils/number_utils.dart';

class Alarm {
  final int id;
  final String title;
  final String time; // "HH:mm"
  final List<int> repeatDays; // ISO weekday 1=Mon..7=Sun
  final bool enabled;
  final String sound; // classic|digital|chime|rising|birds
  final int volume; // 0..100
  final bool gradualVolume;
  final bool vibration;
  final int snoozeMinutes; // 0 = snooze disabled
  final int snoozeLimit; // 0 = unlimited
  final bool wakeUpCheck;
  final String challengeType; // none|math|memory|typing|shake|walk|puzzle|qr
  final String challengeDifficulty; // easy|medium|hard
  final String? qrCode;

  const Alarm({
    required this.id,
    required this.title,
    required this.time,
    this.repeatDays = const [],
    this.enabled = true,
    this.sound = 'classic',
    this.volume = 80,
    this.gradualVolume = true,
    this.vibration = true,
    this.snoozeMinutes = 5,
    this.snoozeLimit = 3,
    this.wakeUpCheck = false,
    this.challengeType = 'none',
    this.challengeDifficulty = 'easy',
    this.qrCode,
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    final sound = json['sound'] as String?;
    return Alarm(
      id: json['id'] as int,
      title: json['title'] as String,
      time: json['time'] as String? ?? '00:00',
      repeatDays: (json['repeat_days'] as List<dynamic>? ?? [])
          .map((e) => NumberUtils.toDouble(e).toInt())
          .toList(),
      enabled: NumberUtils.toBool(json['enabled'], fallback: true),
      // Older alarms were saved with sound "default".
      sound: sound == null || sound == 'default' ? 'classic' : sound,
      volume: NumberUtils.toDouble(json['volume'] ?? 80).toInt(),
      gradualVolume: NumberUtils.toBool(json['gradual_volume'], fallback: true),
      vibration: NumberUtils.toBool(json['vibration'], fallback: true),
      snoozeMinutes: NumberUtils.toDouble(json['snooze_minutes']).toInt(),
      snoozeLimit: NumberUtils.toDouble(json['snooze_limit'] ?? 3).toInt(),
      wakeUpCheck: NumberUtils.toBool(json['wake_up_check']),
      challengeType: json['challenge_type'] as String? ?? 'none',
      challengeDifficulty: json['challenge_difficulty'] as String? ?? 'easy',
      qrCode: json['qr_code'] as String?,
    );
  }

  bool get hasChallenge => challengeType != 'none';

  bool get isRepeating => repeatDays.isNotEmpty;

  bool get canSnooze => snoozeMinutes > 0;

  int get hour => int.tryParse(time.split(':').first) ?? 0;

  int get minute {
    final parts = time.split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }

  /// Next moment this alarm rings, strictly after [from].
  DateTime nextTrigger([DateTime? from]) {
    final now = from ?? DateTime.now();
    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset, hour, minute);
      if (!day.isAfter(now)) continue;
      if (repeatDays.isEmpty || repeatDays.contains(day.weekday)) return day;
    }
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  static String formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Alarm copyWith({
    int? id,
    String? title,
    String? time,
    List<int>? repeatDays,
    bool? enabled,
    String? sound,
    int? volume,
    bool? gradualVolume,
    bool? vibration,
    int? snoozeMinutes,
    int? snoozeLimit,
    bool? wakeUpCheck,
    String? challengeType,
    String? challengeDifficulty,
    String? qrCode,
  }) {
    return Alarm(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      volume: volume ?? this.volume,
      gradualVolume: gradualVolume ?? this.gradualVolume,
      vibration: vibration ?? this.vibration,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      snoozeLimit: snoozeLimit ?? this.snoozeLimit,
      wakeUpCheck: wakeUpCheck ?? this.wakeUpCheck,
      challengeType: challengeType ?? this.challengeType,
      challengeDifficulty: challengeDifficulty ?? this.challengeDifficulty,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'time': time,
    'repeat_days': repeatDays,
    'enabled': enabled,
    'sound': sound,
    'volume': volume,
    'gradual_volume': gradualVolume,
    'vibration': vibration,
    'snooze_minutes': snoozeMinutes,
    'snooze_limit': snoozeLimit,
    'wake_up_check': wakeUpCheck,
    'challenge_type': challengeType,
    'challenge_difficulty': challengeDifficulty,
    'qr_code': qrCode,
  };
}
