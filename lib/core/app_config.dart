class AppConfig {
  AppConfig._(); // không cho khởi tạo

  // Đổi host theo môi trường chạy
  // Android emulator: 10.0.2.2 | iOS sim: localhost | thiết bị thật: IP máy
  static const String _host = '10.0.2.2';
  static const String _port = '5000';

  static const String apiBaseUrl = 'http://$_host:$_port/api';

  // Endpoint cụ thể build từ base
  static String get lexicalUrl => '$apiBaseUrl/lexical';
  static String get passagesUrl => '$apiBaseUrl/passages';
}