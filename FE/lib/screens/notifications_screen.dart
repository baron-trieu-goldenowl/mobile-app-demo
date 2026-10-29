import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/notification.dart';
import '../services/inbox_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _inbox = InboxService.instance;
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
      _notifications = await _inbox.fetch();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Marks [n] read and opens the tab it is about.
  Future<void> _open(AppNotification n) async {
    if (!n.read) unawaited(_inbox.markRead(n.id).then((_) => _load()));
    final tab = _tabFor(n.kind);
    if (tab == null) return;
    AppShell.currentTab.value = tab;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _markAllRead() async {
    await _inbox.markAllRead();
    await _load();
  }

  static int? _tabFor(String kind) => switch (kind) {
    'calendar_synced' => AppShell.scheduleTab,
    'calendar_sync_failed' => AppShell.settingsTab,
    'wake_streak' => AppShell.reportTab,
    _ => null,
  };

  static (IconData, Color) _iconFor(String kind) => switch (kind) {
    'calendar_synced' => (Icons.event_available_rounded, AppColors.event),
    'calendar_sync_failed' => (Icons.sync_problem_rounded, AppColors.danger),
    'wake_streak' => (Icons.local_fire_department_rounded, AppColors.warning),
    _ => (Icons.notifications_active_rounded, AppColors.accent),
  };

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
                  final (icon, color) = _iconFor(n.kind);
                  return Card(
                    color: n.read
                        ? null
                        : AppColors.accent.withValues(alpha: 0.08),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      onTap: () => _open(n),
                      leading: IconBadge(
                        icon,
                        color: n.read
                            ? theme.colorScheme.onSurfaceVariant
                            : color,
                      ),
                      title: Text(
                        s.notificationTitle(n),
                        style: TextStyle(
                          fontWeight: n.read
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${s.notificationBody(n)}\n${DateFormat('d MMM · HH:mm', s.locale.languageCode).format(n.createdAt.toLocal())}',
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
