import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_client.dart';

class AppleCredentials {
  final String identityToken;
  final String authorizationCode;

  /// Apple only shares the name on the very first sign-in.
  final String? name;

  const AppleCredentials(this.identityToken, this.authorizationCode, this.name);
}

/// Native "Sign in with Apple" (iOS). Required by App Store Review
/// Guideline 4.8 because the app also offers Google sign-in.
class AppleAuthService {
  AppleAuthService._();
  static final AppleAuthService instance = AppleAuthService._();

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns null when the user cancels.
  Future<AppleCredentials?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final token = credential.identityToken;
      if (token == null) {
        throw ApiException('Apple did not return an identity token');
      }
      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
      return AppleCredentials(
        token,
        credential.authorizationCode,
        name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw ApiException(e.message);
    }
  }
}
