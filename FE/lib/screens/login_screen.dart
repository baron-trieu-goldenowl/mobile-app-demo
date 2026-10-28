import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/apple_auth_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth = AuthService.instance;
  bool _loading = false;
  bool _googleLoading = false;
  bool _appleLoading = false;
  bool _obscure = true;

  Future<void> _login() async {
    final s = AppStrings.of(context);
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      showSnack(context, s.fillEmailPassword);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      _goHome();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    try {
      final user = await _auth.loginWithGoogle();
      if (user != null) _goHome();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _apple() async {
    setState(() => _appleLoading = true);
    try {
      final user = await _auth.loginWithApple();
      if (user != null) _goHome();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  void _goHome() {
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final busy = _loading || _googleLoading || _appleLoading;
    return Scaffold(
      body: Stack(
        children: [
          const _SunriseBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppLogo(),
                      const SizedBox(height: 28),
                      Text(
                        s.welcomeBack,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.loginTagline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 36),
                      if (AppleAuthService.instance.isSupported) ...[
                        SizedBox(
                          height: 54,
                          child: SignInWithAppleButton(
                            text: s.loginApple,
                            style: theme.brightness == Brightness.dark
                                ? SignInWithAppleButtonStyle.white
                                : SignInWithAppleButtonStyle.black,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                            onPressed: busy ? () {} : _apple,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton(
                        onPressed: busy ? null : _google,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainer,
                        ),
                        child: _googleLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const GoogleLogo(),
                                  const SizedBox(width: 12),
                                  Text(s.loginGoogle),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.googleCalendarHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              s.orEmail,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          hintText: s.email,
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          hintText: s.password,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        label: s.login,
                        loading: _loading,
                        onPressed: busy ? null : _login,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => Navigator.of(context).pushNamed('/signup'),
                        child: Text(s.noAccount),
                      ),
                      const SizedBox(height: 8),
                      const LegalNotice(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "By continuing you agree to the Privacy Policy" with a tappable link.
class LegalNotice extends StatelessWidget {
  const LegalNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: '${s.legalPrefix} '),
          TextSpan(
            text: s.privacyPolicy,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(Uri.parse(ApiClient.privacyPolicyUrl)),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// App mark: sunrise gradient circle with an alarm clock.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.sunrise,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPink.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          Icons.alarm_rounded,
          color: Colors.white,
          size: size * 0.52,
        ),
      ),
    );
  }
}

class _SunriseBackdrop extends StatelessWidget {
  const _SunriseBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -160,
      left: -80,
      right: -80,
      child: Container(
        height: 420,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.28),
              AppColors.accentPink.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
