import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu access + refresh token an toàn (Keychain/Keystore).
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _storage = FlutterSecureStorage();
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  // Cache in-memory để không phải đọc storage mỗi request
  String? _accessTokenCache;

  Future<void> save(String accessToken, String refreshToken) async {
    _accessTokenCache = accessToken;
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<void> updateAccessToken(String accessToken) async {
    _accessTokenCache = accessToken;
    await _storage.write(key: _kAccess, value: accessToken);
  }

  Future<String?> getAccessToken() async {
    _accessTokenCache ??= await _storage.read(key: _kAccess);
    return _accessTokenCache;
  }

  Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);

  String? get cachedAccessToken => _accessTokenCache;

  Future<void> clear() async {
    _accessTokenCache = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
