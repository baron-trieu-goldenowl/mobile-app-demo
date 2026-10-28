class Task {
  final int id;
  final String title;
  final String? description;
  final String priority; // low | medium | high | urgent
  final String status; // todo | in_progress | done
  final DateTime? dueAt;
  final DateTime? reminderAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.dueAt,
    this.reminderAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'todo',
      dueAt: json['due_at'] != null
          ? DateTime.parse(json['due_at'] as String).toLocal()
          : null,
      reminderAt: json['reminder_at'] != null
          ? DateTime.parse(json['reminder_at'] as String).toLocal()
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'priority': priority,
    'status': status,
    'due_at': dueAt?.toUtc().toIso8601String(),
    'reminder_at': reminderAt?.toUtc().toIso8601String(),
  };

  bool get isDone => status == 'done';
}
