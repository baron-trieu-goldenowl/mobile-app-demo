import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/notification.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.get('/notifications');
      final list = data['notifications'] as List<dynamic>;
      _notifications = list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markRead(int id) async {
    await ApiClient.instance.patch('/notifications/$id/read');
    await _load();
  }

  Future<void> _markAllRead() async {
    await ApiClient.instance.patch('/notifications/read_all');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifications),
        actions: [
          TextButton(
            onPressed: _notifications.any((n) => !n.read) ? _markAllRead : null,
            child: Text(s.markAllRead),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null || _notifications.isEmpty
            ? ListView(
                children: [
                  EmptyState(
                    icon: _error != null
                        ? Icons.cloud_off_rounded
                        : Icons.notifications_off_outlined,
                    title: _error != null ? s.loadFailed : s.noNotifications,
                    subtitle: _error,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return Card(
                    color: n.read
                        ? null
                        : AppColors.accent.withValues(alpha: 0.08),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      onTap: n.read ? null : () => _markRead(n.id),
                      leading: IconBadge(
                        n.read
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active_rounded,
                        color: n.read
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.accent,
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.read
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${n.body}\n${DateFormat('d MMM · HH:mm', s.locale.languageCode).format(n.createdAt.toLocal())}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
