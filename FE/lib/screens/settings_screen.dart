import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/user.dart';
import '../services/alarm_scheduler.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/calendar_service.dart';
import '../services/google_auth_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService.instance;
  final _settings = SettingsService.instance;
  final _calendar = CalendarService();
  bool _googleBusy = false;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_refresh);
    _settings.addListener(_refresh);
  }

  @override
  void dispose() {
    _auth.removeListener(_refresh);
    _settings.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _connectGoogle() async {
    final s = AppStrings.of(context);
    setState(() => _googleBusy = true);
    try {
      final code = await GoogleAuthService.instance.requestCalendarAccess();
      if (code == null) return;
      await _calendar.connectGoogle(code);
      if (mounted) showSnack(context, s.googleConnected);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _disconnectGoogle() async {
    final s = AppStrings.of(context);
    final ok = await _confirm(
      s.disconnectGoogle,
      s.disconnectGoogleConfirm,
      s.disconnect,
    );
    if (!ok) return;
    setState(() => _googleBusy = true);
    try {
      await _calendar.disconnectGoogle();
      await GoogleAuthService.instance.signOut();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _syncNow() async {
    final s = AppStrings.of(context);
    setState(() => _googleBusy = true);
    try {
      await _calendar.syncGoogle();
      await _auth.refreshUser();
      if (mounted) showSnack(context, s.syncDone);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(88, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _logout() async {
    final s = AppStrings.of(context);
    if (!await _confirm(s.logout, s.logoutConfirm, s.logout)) return;
    AlarmScheduler.instance.reset();
    await _auth.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  Future<void> _deleteAccount() async {
    final s = AppStrings.of(context);
    if (!await _confirm(s.deleteAccount, s.deleteAccountConfirm, s.delete)) {
      return;
    }
    try {
      await ApiClient.instance.delete('/account');
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
      return;
    }
    AlarmScheduler.instance.reset();
    await _auth.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  Future<void> _editProfile(User user) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProfileSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final user = _auth.currentUser;
    final connected = user?.googleConnected ?? false;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: Text(s.settings, style: theme.textTheme.headlineMedium),
            ),
            if (user != null)
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _editProfile(user),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _Avatar(user: user, radius: 30),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name?.isNotEmpty == true
                                    ? user.name!
                                    : s.noName,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                user.email,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SectionCard(
              title: s.googleCalendar,
              children: [
                ListTile(
                  leading: const SizedBox(
                    width: 40,
                    child: Center(child: GoogleLogo(size: 26)),
                  ),
                  title: Text(connected ? s.connected : s.notConnected),
                  subtitle: Text(
                    connected ? s.googleSyncHint : s.connectGoogleHint,
                  ),
                  trailing: _googleBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : connected
                      ? IconButton(
                          tooltip: s.syncGoogle,
                          icon: const Icon(Icons.sync_rounded),
                          onPressed: _syncNow,
                        )
                      : TextButton(
                          onPressed: _connectGoogle,
                          child: Text(s.connect),
                        ),
                ),
                if (connected)
                  ListTile(
                    leading: const IconBadge(
                      Icons.link_off_rounded,
                      color: AppColors.danger,
                    ),
                    title: Text(s.disconnectGoogle),
                    onTap: _googleBusy ? null : _disconnectGoogle,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: s.appearance,
              padding: const EdgeInsets.all(14),
              children: [
                Text(s.theme, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_rounded),
                      label: Text(s.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_rounded),
                      label: Text(s.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_rounded),
                      label: Text(s.themeDark),
                    ),
                  ],
                  selected: {_settings.themeMode},
                  onSelectionChanged: (v) => _settings.setThemeMode(v.first),
                ),
                const SizedBox(height: 16),
                Text(s.language, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'vi', label: Text('Tiếng Việt')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {_settings.locale.languageCode},
                  onSelectionChanged: (v) =>
                      _settings.setLocale(Locale(v.first)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: s.general,
              children: [
                ListTile(
                  leading: const IconBadge(
                    Icons.notifications_active_outlined,
                    color: AppColors.warning,
                  ),
                  title: Text(s.notificationPermission),
                  subtitle: Text(s.notificationPermissionHint),
                  onTap: () async {
                    final granted = await NotificationService.instance
                        .requestPermissions();
                    if (context.mounted) {
                      showSnack(
                        context,
                        granted ? s.permissionGranted : s.permissionDenied,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const IconBadge(
                    Icons.inbox_outlined,
                    color: AppColors.event,
                  ),
                  title: Text(s.notifications),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.of(context).pushNamed('/notifications'),
                ),
                ListTile(
                  leading: const IconBadge(
                    Icons.privacy_tip_outlined,
                    color: AppColors.violet,
                  ),
                  title: Text(s.privacyPolicy),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => launchUrl(Uri.parse(ApiClient.privacyPolicyUrl)),
                ),
                ListTile(
                  leading: const IconBadge(
                    Icons.help_outline_rounded,
                    color: AppColors.task,
                  ),
                  title: Text(s.helpSupport),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => launchUrl(Uri.parse(ApiClient.supportUrl)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionCard(
              children: [
                ListTile(
                  leading: const IconBadge(
                    Icons.logout_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(s.logout),
                  onTap: _logout,
                ),
                ListTile(
                  leading: const IconBadge(
                    Icons.delete_forever_outlined,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    s.deleteAccount,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  onTap: _deleteAccount,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'DayFlow · ${DateFormat.y().format(DateTime.now())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, this.radius = 28});

  final User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = (user.name?.isNotEmpty == true ? user.name! : user.email)
        .characters
        .first
        .toUpperCase();
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.sunrise,
      ),
      clipBehavior: Clip.antiAlias,
      child: user.avatarUrl != null
          ? Image.network(
              user.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(),
            )
          : Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.user});

  final User user;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _profile = ProfileService();
  late final _nameCtrl = TextEditingController(text: widget.user.name);
  late final _emailCtrl = TextEditingController(text: widget.user.email);
  late User _user = widget.user;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );
    if (file == null) return;
    setState(() => _saving = true);
    try {
      final user = await _profile.updateAvatar(
        filename: file.name,
        bytes: await file.readAsBytes(),
      );
      _user = AuthService.instance.setUser(user);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    final s = AppStrings.of(context);
    setState(() => _saving = true);
    try {
      final user = await _profile.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      AuthService.instance.setUser(user);
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, s.profileUpdated);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.editProfile, style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _saving ? null : _pickAvatar,
                  child: Stack(
                    children: [
                      _Avatar(user: _user, radius: 44),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: s.name,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: s.email,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
              ),
              if (_user.providers.contains('google')) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const GoogleLogo(size: 16),
                    const SizedBox(width: 8),
                    Text(
                      s.signedInWithGoogle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (_user.providers.contains('apple')) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.apple, size: 18),
                    const SizedBox(width: 8),
                    Text(s.signedInWithApple, style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              GradientButton(
                label: s.saveChanges,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
