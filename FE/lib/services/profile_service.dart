import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _api = ApiClient.instance;

  Future<User> getProfile() async {
    final data = await _api.get('/profile');
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> updateProfile({String? name, String? email}) async {
    final body = <String, dynamic>{'name': ?name, 'email': ?email};
    final data = await _api.patch('/profile', body: body);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Upload avatar as multipart/form-data. Works on all platforms (including
  /// web) by reading the picked file into bytes.
  Future<User> updateAvatar({
    required String filename,
    required List<int> bytes,
  }) async {
    final uri = Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPrefix}/profile');
    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Bearer ${_api.token}'
      ..files.add(
        http.MultipartFile.fromBytes('avatar', bytes, filename: filename),
      );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    final data = json.decode(resp.body) as Map<String, dynamic>;

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return User.fromJson(data['user'] as Map<String, dynamic>);
    }
    throw ApiException(
      data['error']?.toString() ?? 'Upload failed',
      statusCode: resp.statusCode,
    );
  }
}
