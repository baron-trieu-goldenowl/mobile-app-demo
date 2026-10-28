import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Simple HTTP client for the Rails backend.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  /// Base URL of the backend API.
  ///
  /// For release builds the URL MUST be provided at compile time:
  ///   flutter build ipa --dart-define=API_BASE_URL=https://api.yourdomain.com
  ///   flutter build appbundle --dart-define=API_BASE_URL=https://api.yourdomain.com
  ///
  /// In debug the local backend is used (10.0.2.2 for the Android emulator,
  /// localhost elsewhere).
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL is not set. Pass '
        '--dart-define=API_BASE_URL=https://your-api-host before building '
        'for release.',
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// All endpoints are versioned under this prefix.
  static const apiPrefix = '/api/v1';

  /// Public pages served by the backend (linked from the app and the stores).
  static String get privacyPolicyUrl => '$baseUrl/privacy.html';
  static String get supportUrl => '$baseUrl/support.html';

  String? _token;
  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => _request('POST', path, body: body);

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) => _request('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _request('DELETE', path);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$apiPrefix$path');
    http.Response resp;
    try {
      switch (method) {
        case 'GET':
          resp = await http.get(uri, headers: _headers);
          break;
        case 'POST':
          resp = await http.post(
            uri,
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PATCH':
          resp = await http.patch(
            uri,
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          resp = await http.delete(uri, headers: _headers);
          break;
        default:
          throw ApiException('Unsupported method $method');
      }
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }

    final data = _decode(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return data;
    }
    final msg = data['error'] ?? 'Request failed (${resp.statusCode})';
    throw ApiException(msg.toString(), statusCode: resp.statusCode);
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return {};
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }
}
