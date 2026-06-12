import 'package:http/http.dart' as http;

/// Holder cho http.Client dùng chung toàn app.
/// AuthController sẽ gán client đã gắn token (AuthHttpClient) vào đây.
/// Mọi service nghiệp vụ mặc định dùng [AppHttp.client].
class AppHttp {
  static http.Client client = http.Client();
}
