import 'package:flutter/foundation.dart';

import '../models/notification.dart';
import 'api_client.dart';

/// In-app notifications (bell icon) and their unread count.
class InboxService {
  InboxService._();
  static final InboxService instance = InboxService._();

  final ApiClient _api = ApiClient.instance;

  /// Unread notifications, shown as a badge on the bell icon.
  final unreadCount = ValueNotifier<int>(0);

  Future<List<AppNotification>> fetch() async {
    final data = await _api.get('/notifications');
    final list = (data['notifications'] as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    unreadCount.value = list.where((n) => !n.read).length;
    return list;
  }

  /// Refreshes the badge; failures keep the last known count.
  Future<void> refreshUnread() async {
    if (_api.token == null) return;
    try {
      await fetch();
    } catch (_) {}
  }

  Future<void> markRead(int id) => _api.patch('/notifications/$id/read');

  Future<void> markAllRead() => _api.patch('/notifications/read_all');

  void reset() => unreadCount.value = 0;
}
