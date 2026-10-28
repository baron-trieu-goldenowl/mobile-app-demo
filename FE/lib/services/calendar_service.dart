import '../models/calendar_event.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'auth_service.dart';

class CalendarService {
  final ApiClient _api = ApiClient.instance;

  Future<List<CalendarEvent>> getEvents() async {
    final data = await _api.get('/calendar_events');
    return _parse(data);
  }

  /// Import the user's Google Calendar (server-side, using the stored
  /// refresh token).
  Future<List<CalendarEvent>> syncGoogle() async {
    final data = await _api.post('/calendar_sync');
    return _parse(data);
  }

  /// Link Google Calendar to the current account with a server auth code.
  Future<User> connectGoogle(String serverAuthCode) async {
    final data = await _api.post(
      '/google_connection',
      body: {'server_auth_code': serverAuthCode},
    );
    return AuthService.instance.setUser(
      User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<User> disconnectGoogle() async {
    final data = await _api.delete('/google_connection');
    return AuthService.instance.setUser(
      User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    final data = await _api.post(
      '/calendar_events',
      body: {'calendar_event': event.toJson()},
    );
    return CalendarEvent.fromJson(
      data['calendar_event'] as Map<String, dynamic>,
    );
  }

  Future<CalendarEvent> updateEvent(int id, CalendarEvent event) async {
    final data = await _api.patch(
      '/calendar_events/$id',
      body: {'calendar_event': event.toJson()},
    );
    return CalendarEvent.fromJson(
      data['calendar_event'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteEvent(int id) async {
    await _api.delete('/calendar_events/$id');
  }

  List<CalendarEvent> _parse(Map<String, dynamic> data) {
    final list = data['calendar_events'] as List<dynamic>;
    return list
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
