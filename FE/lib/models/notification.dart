/// In-app notification from the backend (bell icon).
class AppNotification {
  final int id;

  /// general, calendar_synced, calendar_sync_failed or wake_streak.
  final String kind;

  /// Values for the localized text, e.g. {count: 12} or {days: 7}.
  final Map<String, dynamic> data;

  /// English fallback text from the server.
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.kind,
    required this.data,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      kind: json['kind'] as String? ?? 'general',
      data: json['data'] as Map<String, dynamic>? ?? const {},
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  int dataInt(String key) => (data[key] as num?)?.toInt() ?? 0;
}
