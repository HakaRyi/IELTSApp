import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/token_store.dart';
import 'auth_api.dart';

/// http.Client tự động:
///  - Gắn Authorization: Bearer {accessToken}
///  - Khi gặp 401 → thử refresh token 1 lần rồi retry request
///  - Nếu refresh thất bại → gọi onUnauthorized (đăng xuất)
class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final AuthApi _authApi;
  final TokenStore _store;

  /// Callback khi phiên hết hạn hoàn toàn (cần đăng nhập lại)
  void Function()? onUnauthorized;

  AuthHttpClient({
    http.Client? inner,
    AuthApi? authApi,
    TokenStore? store,
  })  : _inner = inner ?? http.Client(),
        _authApi = authApi ?? AuthApi(),
        _store = store ?? TokenStore.instance;

  // Tránh nhiều request cùng refresh một lúc
  Future<bool>? _refreshing;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _store.getAccessToken();
    var response = await _sendWith(request, token);

    if (response.statusCode == 401) {
      final ok = await _tryRefresh();
      if (ok) {
        final newToken = await _store.getAccessToken();
        response = await _sendWith(_copyRequest(request), newToken);
      } else {
        onUnauthorized?.call();
      }
    }
    return response;
  }

  Future<http.StreamedResponse> _sendWith(
      http.BaseRequest request, String? token) {
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }

  Future<bool> _tryRefresh() {
    // Gộp các lần refresh đồng thời thành một
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _store.getRefreshToken();
    if (refreshToken == null) return false;

    final result = await _authApi.refresh(refreshToken);
    if (result == null) {
      await _store.clear();
      return false;
    }
    await _store.save(result.accessToken, result.refreshToken);
    return true;
  }

  /// Clone request để retry (request cũ đã bị "finalize" sau khi send)
  http.BaseRequest _copyRequest(http.BaseRequest original) {
    if (original is http.Request) {
      final clone = http.Request(original.method, original.url)
        ..headers.addAll(original.headers)
        ..followRedirects = original.followRedirects
        ..maxRedirects = original.maxRedirects
        ..persistentConnection = original.persistentConnection;
      clone.bodyBytes = original.bodyBytes;
      return clone;
    }
    // Các loại request khác (multipart...) — trả nguyên bản
    return original;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
