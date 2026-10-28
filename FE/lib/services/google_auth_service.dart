import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';

class GoogleCredentials {
  final String idToken;
  final String? serverAuthCode;

  const GoogleCredentials(this.idToken, this.serverAuthCode);
}

/// Native Google Sign-In.
///
/// Requires OAuth clients from Google Cloud Console, passed at build time:
///   `--dart-define=GOOGLE_SERVER_CLIENT_ID=WEB_CLIENT_ID.apps.googleusercontent.com`
///   `--dart-define=GOOGLE_IOS_CLIENT_ID=IOS_CLIENT_ID.apps.googleusercontent.com`
/// See README for the full setup (Android SHA-1, iOS URL scheme).
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  static const calendarScopes = [
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  Future<void>? _init;

  bool get isConfigured => _serverClientId.isNotEmpty;

  Future<void> _ensureInitialized() {
    if (!isConfigured) {
      throw ApiException(
        'Google Sign-In is not configured. Build with '
        '--dart-define=GOOGLE_SERVER_CLIENT_ID=...',
      );
    }
    return _init ??= GoogleSignIn.instance.initialize(
      clientId: _iosClientId.isEmpty ? null : _iosClientId,
      serverClientId: _serverClientId,
    );
  }

  /// Signs in and asks for read access to Google Calendar.
  /// Returns null when the user cancels. If the user signs in but declines
  /// calendar access, [GoogleCredentials.serverAuthCode] is null.
  Future<GoogleCredentials?> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: calendarScopes,
      );
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw ApiException('Google did not return an ID token');
      }
      return GoogleCredentials(idToken, await _serverAuthCode(account));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw ApiException(
        e.description ?? 'Google Sign-In failed (${e.code.name})',
      );
    }
  }

  /// Gets a fresh server auth code for linking Google Calendar to an
  /// existing account. Returns null when the user cancels.
  Future<String?> requestCalendarAccess() async {
    final credentials = await signIn();
    if (credentials == null) return null;
    if (credentials.serverAuthCode == null) {
      throw ApiException('Calendar access was not granted');
    }
    return credentials.serverAuthCode;
  }

  Future<String?> _serverAuthCode(GoogleSignInAccount account) async {
    try {
      final auth = await account.authorizationClient.authorizeServer(
        calendarScopes,
      );
      return auth?.serverAuthCode;
    } on GoogleSignInException catch (e) {
      // Declining the calendar scope still allows a normal sign-in.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Signing out of Google is best-effort.
    }
  }
}
