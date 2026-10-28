import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth = AuthService.instance;
  bool _loading = false;
  bool _obscure = true;
  String? _emailError;
  String? _passwordError;
  String? _nameError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? _validateEmail(AppStrings s, String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return s.emailRequired;
    if (!_emailRegex.hasMatch(email)) return s.emailInvalid;
    return null;
  }

  String? _validatePassword(AppStrings s, String? value) {
    final password = value ?? '';
    if (password.isEmpty) return s.passwordRequired;
    if (password.length < 8) return s.passwordShort;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return s.passwordUpper;
    if (!RegExp(r'[a-z]').hasMatch(password)) return s.passwordLower;
    if (!RegExp(r'[0-9]').hasMatch(password)) return s.passwordDigit;
    return null;
  }

  Future<void> _signup() async {
    final s = AppStrings.of(context);
    setState(() {
      _emailError = _validateEmail(s, _emailCtrl.text);
      _passwordError = _validatePassword(s, _passwordCtrl.text);
      _nameError = _nameCtrl.text.trim().isEmpty ? s.nameRequired : null;
    });

    if (_emailError != null || _passwordError != null || _nameError != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.signup(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.createAccount, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                s.signupTagline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _nameError = null),
                decoration: InputDecoration(
                  hintText: s.name,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _emailError = null),
                decoration: InputDecoration(
                  hintText: s.email,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                onChanged: (_) => setState(() => _passwordError = null),
                onSubmitted: (_) => _signup(),
                decoration: InputDecoration(
                  hintText: s.password,
                  helperText: s.passwordHelper,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: s.signup,
                loading: _loading,
                onPressed: _signup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
