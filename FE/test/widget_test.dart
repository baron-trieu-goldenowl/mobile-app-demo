import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_demo/l10n/app_strings.dart';
import 'package:mobile_app_demo/models/alarm.dart';
import 'package:mobile_app_demo/screens/login_screen.dart';
import 'package:mobile_app_demo/theme/app_theme.dart';

void main() {
  testWidgets('Login screen offers Google and email, no Facebook', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const LoginScreen()),
    );

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.textContaining('Facebook'), findsNothing);
  });

  group('Alarm.nextTrigger', () {
    // Wednesday 2026-10-28 07:00
    final now = DateTime(2026, 10, 28, 7);

    test('one-time alarm later today rings today', () {
      const a = Alarm(id: 1, title: 'a', time: '08:15');
      expect(a.nextTrigger(now), DateTime(2026, 10, 28, 8, 15));
    });

    test('one-time alarm already passed rings tomorrow', () {
      const a = Alarm(id: 1, title: 'a', time: '06:30');
      expect(a.nextTrigger(now), DateTime(2026, 10, 29, 6, 30));
    });

    test('repeating alarm skips to the next selected weekday', () {
      // Mon & Fri only; it's Wednesday -> Friday.
      const a = Alarm(id: 1, title: 'a', time: '06:30', repeatDays: [1, 5]);
      expect(a.nextTrigger(now), DateTime(2026, 10, 30, 6, 30));
    });

    test('repeating alarm for today that already passed waits a week', () {
      const a = Alarm(id: 1, title: 'a', time: '06:30', repeatDays: [3]);
      expect(a.nextTrigger(now), DateTime(2026, 11, 4, 6, 30));
    });
  });

  test('ringsIn formats hours and minutes', () {
    final vi = AppStrings(const Locale('vi'));
    final en = AppStrings(const Locale('en'));
    const d = Duration(hours: 7, minutes: 32);
    expect(vi.ringsIn(d), 'Reo sau 7 giờ 32 phút');
    expect(en.ringsIn(d), 'Rings in 7 h 32 min');
    expect(
      en.ringsIn(const Duration(seconds: 20)),
      'Rings in less than a minute',
    );
  });
}
