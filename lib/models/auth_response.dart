import 'auth_user.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final AuthUser user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
        accessTokenExpiresAt:
            DateTime.tryParse(json['accessTokenExpiresAt'] ?? '') ??
                DateTime.now(),
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
