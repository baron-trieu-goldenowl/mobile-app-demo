import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'apple_auth_service.dart';
import 'google_auth_service.dart';
import 'inbox_service.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'auth_token';

  final ApiClient _api = ApiClient.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      _api.setToken(token);
      try {
        await refreshUser();
      } on ApiException catch (e) {
        // Only drop the session when the token is rejected, not when the
        // server is unreachable.
        if (e.statusCode == 401) await logout();
      } catch (_) {}
    }
  }

  Future<User> refreshUser() async {
    final data = await _api.get('/profile');
    return setUser(User.fromJson(data['user'] as Map<String, dynamic>));
  }

  User setUser(User user) {
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<User> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    final data = await _api.post(
      '/auth/signup',
      body: {'email': email, 'password': password, 'name': name},
    );
    return _storeAuth(data);
  }

  Future<User> login({required String email, required String password}) async {
    final data = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return _storeAuth(data);
  }

  /// Native Google Sign-In; the backend verifies the ID token and stores a
  /// refresh token (from the server auth code) for Calendar sync.
  /// Returns null if the user cancelled.
  Future<User?> loginWithGoogle() async {
    final credentials = await GoogleAuthService.instance.signIn();
    if (credentials == null) return null;
    final data = await _api.post(
      '/auth/google',
      body: {
        'id_token': credentials.idToken,
        'server_auth_code': ?credentials.serverAuthCode,
      },
    );
    return _storeAuth(data);
  }

  /// Sign in with Apple; the backend verifies the identity token against
  /// Apple's public keys. Returns null if the user cancelled.
  Future<User?> loginWithApple() async {
    final credentials = await AppleAuthService.instance.signIn();
    if (credentials == null) return null;
    final data = await _api.post(
      '/auth/apple',
      body: {
        'identity_token': credentials.identityToken,
        'authorization_code': credentials.authorizationCode,
        'name': ?credentials.name,
      },
    );
    return _storeAuth(data);
  }

  Future<User> _storeAuth(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    _api.setToken(token);
    final user = setUser(User.fromJson(data['user'] as Map<String, dynamic>));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    return user;
  }

  Future<void> logout() async {
    _api.setToken(null);
    _currentUser = null;
    InboxService.instance.reset();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    // Alarms belong to the account; don't keep ringing after logout.
    await NotificationService.instance.cancelAll();
    await GoogleAuthService.instance.signOut();
  }
}
