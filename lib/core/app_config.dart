class AppConfig {
  AppConfig._();

  // Android emulator: 10.0.2.2 | iOS sim: localhost | thiết bị thật: IP máy
  static const String _host = '192.168.1.146';

  static const String lexicalUrl  = 'http://$_host:5101/api/lexical';
  static const String passagesUrl = 'http://$_host:5069/api/passages';
  static const String speakingUrl = 'http://$_host:5069/api/speaking';
  static const String reviewUrl   = 'http://$_host:5070/api/review';
  static const String authUrl     = 'http://$_host:5072/api/auth';
}
