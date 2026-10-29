import '../models/wake_log.dart';
import 'api_client.dart';

class WakeLogService {
  final ApiClient _api = ApiClient.instance;

  Future<List<WakeLog>> getLogs({int days = 30}) async {
    final data = await _api.get('/wake_logs?days=$days');
    final list = data['wake_logs'] as List<dynamic>;
    return list
        .map((e) => WakeLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(WakeLog log) async {
    await _api.post(
      '/wake_logs',
      body: {
        'wake_log': log.toJson(),
        // Lets the backend count streak days in the device's time zone.
        'utc_offset': DateTime.now().timeZoneOffset.inSeconds,
      },
    );
  }
}
