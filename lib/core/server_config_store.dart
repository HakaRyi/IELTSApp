import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_config.dart';

/// Lưu URL backend (gateway) do người dùng nhập — để đổi server không cần build lại app.
class ServerConfigStore {
  ServerConfigStore._();

  static const _key = 'gateway_base_url';
  static const _storage = FlutterSecureStorage();

  /// Gọi lúc khởi động app: nạp URL đã lưu (nếu có) vào AppConfig.
  static Future<void> load() async {
    final saved = await _storage.read(key: _key);
    if (saved != null && saved.trim().isNotEmpty) {
      AppConfig.gatewayBase = saved.trim();
    }
  }

  static Future<void> save(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), ''); // bỏ '/' thừa cuối
    AppConfig.gatewayBase = clean;
    await _storage.write(key: _key, value: clean);
  }
}
