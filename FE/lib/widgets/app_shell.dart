import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../screens/alarm_screen.dart';
import '../screens/report_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tasks_screen.dart';
import '../services/alarm_scheduler.dart';
import '../services/auth_service.dart';

/// Main screen with the bottom navigation bar.
/// Alarms(0) · Schedule(1) · Tasks(2) · Report(3) · Settings(4)
///
/// Tabs live in an IndexedStack so they keep their state and scroll position.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Currently visible tab; screens listen to it to refresh when shown.
  static final currentTab = ValueNotifier<int>(0);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _tabs = [
    AlarmScreen(),
    ScheduleScreen(),
    TasksScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    AppShell.currentTab.value = 0;
    // Start watching the clock so alarms fire the ringing screen on time.
    AlarmScheduler.instance.start();
    AuthService.instance.addListener(_onAuth);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    if (AuthService.instance.currentUser == null) {
      AlarmScheduler.instance.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: AppShell.currentTab,
      builder: (context, index, _) => Scaffold(
        body: IndexedStack(index: index, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => AppShell.currentTab.value = i,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.alarm_outlined),
              selectedIcon: const Icon(Icons.alarm_rounded),
              label: s.alarm,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month_rounded),
              label: s.schedule,
            ),
            NavigationDestination(
              icon: const Icon(Icons.check_circle_outline_rounded),
              selectedIcon: const Icon(Icons.check_circle_rounded),
              label: s.tasks,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights_rounded),
              label: s.report,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: s.settings,
            ),
          ],
        ),
      ),
    );
  }
}
