class WakeLog {
  final int? id;
  final int? alarmId;
  final String? alarmTitle;
  final DateTime? scheduledAt;
  final DateTime dismissedAt;
  final int snoozeCount;
  final String? challengeType;
  final int? missionSeconds;

  WakeLog({
    this.id,
    this.alarmId,
    this.alarmTitle,
    this.scheduledAt,
    required this.dismissedAt,
    this.snoozeCount = 0,
    this.challengeType,
    this.missionSeconds,
  });

  factory WakeLog.fromJson(Map<String, dynamic> json) {
    return WakeLog(
      id: json['id'] as int?,
      alarmId: json['alarm_id'] as int?,
      alarmTitle: json['alarm_title'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String).toLocal()
          : null,
      dismissedAt: DateTime.parse(json['dismissed_at'] as String).toLocal(),
      snoozeCount: json['snooze_count'] as int? ?? 0,
      challengeType: json['challenge_type'] as String?,
      missionSeconds: json['mission_seconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'alarm_id': alarmId,
    'alarm_title': alarmTitle,
    'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
    'dismissed_at': dismissedAt.toUtc().toIso8601String(),
    'snooze_count': snoozeCount,
    'challenge_type': challengeType,
    'mission_seconds': missionSeconds,
  };
}
