import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings: theme mode and language.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _themeKey = 'theme_mode';
  static const _langKey = 'language_code';

  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('vi');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_themeKey);
    final lang = prefs.getString(_langKey);

    _themeMode = switch (theme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      // Dark by default: alarms are mostly used at night / right after waking.
      _ => ThemeMode.dark,
    };
    _locale = Locale(lang ?? 'vi');
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    });
  }

  Future<void> toggleDarkMode(bool dark) async {
    await setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.languageCode);
  }
}
