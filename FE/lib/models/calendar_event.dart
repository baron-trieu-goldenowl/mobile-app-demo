class CalendarEvent {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startAt;
  final DateTime? endAt;
  final bool allDay;
  final String source; // local | google_calendar

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startAt,
    this.endAt,
    this.allDay = false,
    required this.source,
  });

  bool get isGoogle => source == 'google_calendar';

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startAt: DateTime.parse(json['start_at'] as String).toLocal(),
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String).toLocal()
          : null,
      allDay: json['all_day'] as bool? ?? false,
      source: json['source'] as String? ?? 'local',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'location': location,
    'start_at': startAt.toUtc().toIso8601String(),
    'end_at': endAt?.toUtc().toIso8601String(),
    'all_day': allDay,
  };
}
