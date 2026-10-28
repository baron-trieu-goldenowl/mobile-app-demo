import '../models/alarm.dart';
import 'alarm_scheduler.dart';
import 'api_client.dart';
import 'notification_service.dart';

class AlarmService {
  final ApiClient _api = ApiClient.instance;
  final NotificationService _notif = NotificationService.instance;

  Future<List<Alarm>> getAlarms() async {
    final data = await _api.get('/alarms');
    final list = data['alarms'] as List<dynamic>;
    final alarms = list
        .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
        .toList();
    AlarmScheduler.instance.updateAlarms(alarms);
    return alarms;
  }

  Future<Alarm> createAlarm(Alarm alarm) async {
    final data = await _api.post('/alarms', body: {'alarm': alarm.toJson()});
    final created = Alarm.fromJson(data['alarm'] as Map<String, dynamic>);
    await _notif.syncAlarm(created);
    return created;
  }

  Future<Alarm> updateAlarm(int id, Map<String, dynamic> body) async {
    final data = await _api.patch('/alarms/$id', body: {'alarm': body});
    final updated = Alarm.fromJson(data['alarm'] as Map<String, dynamic>);
    await _notif.syncAlarm(updated);
    return updated;
  }

  Future<void> deleteAlarm(int id) async {
    await _api.delete('/alarms/$id');
    await _notif.cancelAlarm(id);
  }

  Future<Alarm> setEnabled(Alarm alarm, bool enabled) =>
      updateAlarm(alarm.id, {'enabled': enabled});
}
