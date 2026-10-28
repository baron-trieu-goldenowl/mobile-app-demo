import '../models/task.dart';
import 'api_client.dart';
import 'notification_service.dart';

class TaskService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Task>> getTasks() async {
    final data = await _api.get('/tasks');
    final list = data['tasks'] as List<dynamic>;
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Task> createTask(Task task) async {
    final data = await _api.post('/tasks', body: {'task': task.toJson()});
    return _syncReminder(Task.fromJson(data['task'] as Map<String, dynamic>));
  }

  Future<Task> updateTask(int id, Map<String, dynamic> body) async {
    final data = await _api.patch('/tasks/$id', body: {'task': body});
    return _syncReminder(Task.fromJson(data['task'] as Map<String, dynamic>));
  }

  Future<void> deleteTask(int id) async {
    await _api.delete('/tasks/$id');
    await NotificationService.instance.cancel(
      NotificationService.taskReminderBase + id,
    );
  }

  /// Mark a task as done (or toggle back to todo).
  Future<Task> toggleComplete(Task task) async {
    final newStatus = task.status == 'done' ? 'todo' : 'done';
    return updateTask(task.id, {
      'status': newStatus,
      'completed_at': newStatus == 'done'
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    });
  }

  Future<Task> _syncReminder(Task task) async {
    final notif = NotificationService.instance;
    final id = NotificationService.taskReminderBase + task.id;
    await notif.cancel(id);
    if (task.reminderAt != null && !task.isDone) {
      await notif.scheduleReminder(
        id: id,
        title: task.title,
        body: task.description ?? '⏰',
        when: task.reminderAt!,
      );
    }
    return task;
  }
}
