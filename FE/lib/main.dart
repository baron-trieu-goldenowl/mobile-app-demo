import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/signup_screen.dart';
import 'services/alarm_scheduler.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SettingsService.instance.load();
  // When a notification is tapped, open the matching alarm's ringing screen.
  NotificationService.instance.onNotificationTap =
      AlarmScheduler.instance.triggerByPayload;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Rebuild the whole app whenever theme/language changes.
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    return MaterialApp(
      title: 'DayFlow',
      debugShowCheckedModeBanner: false,
      navigatorKey: AlarmScheduler.navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (_) => const _SplashGate(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const AppShell(),
        '/notifications': (_) => const NotificationsScreen(),
      },
    );
  }
}

/// Determines the initial route: main shell if already logged in,
/// otherwise login.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AuthService.instance.init();
    await NotificationService.instance.init();
    if (!mounted) return;
    final loggedIn = AuthService.instance.currentUser != null;
    Navigator.of(context).pushReplacementNamed(loggedIn ? '/home' : '/login');
    if (!loggedIn) return;

    // App cold-started from an alarm notification: ring right away.
    final payload = await NotificationService.instance.launchPayload();
    if (payload != null) {
      await AlarmScheduler.instance.triggerByPayload(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AppLogo()));
  }
}
