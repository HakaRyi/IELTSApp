import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_user.dart';
import '../services/auth_api.dart';
import '../services/auth_http_client.dart';
import 'app_http.dart';
import 'token_store.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  final AuthApi _api = AuthApi();
  final TokenStore _store = TokenStore.instance;
  late final AuthHttpClient authedClient;

  AuthStatus status = AuthStatus.unknown;
  AuthUser? user;

  AuthController() {
    authedClient = AuthHttpClient(authApi: _api, store: _store);
    // Khi refresh thất bại hoàn toàn → đăng xuất tại UI
    authedClient.onUnauthorized = () => _forceLogout();
    // Mọi service nghiệp vụ dùng chung client đã gắn token
    AppHttp.client = authedClient;
  }

  /// http.Client đã gắn token — dùng cho mọi service nghiệp vụ
  http.Client get client => authedClient;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Gọi khi mở app: kiểm tra token đã lưu còn dùng được không
  Future<void> tryAutoLogin() async {
    final access = await _store.getAccessToken();
    if (access == null) {
      _set(AuthStatus.unauthenticated, null);
      return;
    }

    // Thử lấy thông tin user bằng access token hiện tại
    var me = await _api.me(access);

    // Access hết hạn → thử refresh
    if (me == null) {
      final refresh = await _store.getRefreshToken();
      if (refresh != null) {
        final refreshed = await _api.refresh(refresh);
        if (refreshed != null) {
          await _store.save(refreshed.accessToken, refreshed.refreshToken);
          me = refreshed.user;
        }
      }
    }

    if (me == null) {
      await _store.clear();
      _set(AuthStatus.unauthenticated, null);
    } else {
      _set(AuthStatus.authenticated, me);
    }
  }

  Future<void> login(String emailOrUsername, String password) async {
    final res = await _api.login(
        emailOrUsername: emailOrUsername, password: password);
    await _store.save(res.accessToken, res.refreshToken);
    _set(AuthStatus.authenticated, res.user);
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    String displayName = '',
  }) async {
    final res = await _api.register(
      email: email,
      username: username,
      password: password,
      displayName: displayName,
    );
    await _store.save(res.accessToken, res.refreshToken);
    _set(AuthStatus.authenticated, res.user);
  }

  Future<void> logout() async {
    final refresh = await _store.getRefreshToken();
    if (refresh != null) await _api.logout(refresh);
    await _store.clear();
    _set(AuthStatus.unauthenticated, null);
  }

  void _forceLogout() {
    _store.clear();
    _set(AuthStatus.unauthenticated, null);
  }

  void _set(AuthStatus s, AuthUser? u) {
    status = s;
    user = u;
    notifyListeners();
  }
}
