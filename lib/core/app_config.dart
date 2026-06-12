class AppConfig {
  AppConfig._();

  // URL gateway mặc định (emulator). Có thể đổi NGAY TRONG APP (màn Đăng nhập → ⚙)
  // mà không cần build lại — phù hợp khi dùng Cloudflare Tunnel (URL đổi mỗi lần chạy).
  //   • Emulator:                 http://10.0.2.2:5000
  //   • Phone cùng WiFi:          http://<IP_LAN_PC>:5000
  //   • Cloudflare Tunnel/VM:      https://<tunnel>.trycloudflare.com  hoặc  http://<IP_VM>:5000
  static const String defaultGateway = 'http://192.168.1.146:5000';

  /// Base URL hiện tại — nạp từ bộ nhớ lúc khởi động (ServerConfigStore).
  static String gatewayBase = defaultGateway;

  static String get authUrl     => '$gatewayBase/api/auth';
  static String get lexicalUrl  => '$gatewayBase/api/lexical';
  static String get passagesUrl => '$gatewayBase/api/passages';
  static String get speakingUrl => '$gatewayBase/api/speaking';
  static String get essaysUrl   => '$gatewayBase/api/essays';
  static String get reviewUrl   => '$gatewayBase/api/review';
}
