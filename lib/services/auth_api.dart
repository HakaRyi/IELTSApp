import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/auth_response.dart';
import '../models/auth_user.dart';

/// Gọi trực tiếp Auth.API — KHÔNG đi qua interceptor (tránh vòng lặp refresh).
class AuthApi {
  final http.Client _client;
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
    String displayName = '',
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.authUrl}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
        'displayName': displayName,
      }),
    );
    if (res.statusCode == 409) {
      throw AuthException(_extractMessage(res.body, 'Email hoặc username đã tồn tại.'));
    }
    _ensureOk(res);
    return AuthResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AuthResponse> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.authUrl}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'emailOrUsername': emailOrUsername,
        'password': password,
      }),
    );
    if (res.statusCode == 401) {
      throw AuthException('Sai email/username hoặc mật khẩu.');
    }
    _ensureOk(res);
    return AuthResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Trả về null nếu refresh thất bại (token hết hạn / bị thu hồi)
  Future<AuthResponse?> refresh(String refreshToken) async {
    try {
      final res = await _client.post(
        Uri.parse('${AppConfig.authUrl}/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (res.statusCode != 200) return null;
      return AuthResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _client.post(
        Uri.parse('${AppConfig.authUrl}/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    } catch (_) {}
  }

  Future<AuthUser?> me(String accessToken) async {
    try {
      final res = await _client.get(
        Uri.parse('${AppConfig.authUrl}/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (res.statusCode != 200) return null;
      return AuthUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthException('Lỗi máy chủ (${res.statusCode}).');
    }
  }

  String _extractMessage(String body, String fallback) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      return m['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
