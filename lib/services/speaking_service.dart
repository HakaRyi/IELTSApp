import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/speaking_practice.dart';

class SpeakingService {
  final http.Client _client;
  SpeakingService({http.Client? client}) : _client = client ?? http.Client();

  Future<SpeakingPractice> generateSpeaking({
    required String topic,
    required double targetBand,
    List<String> vocabularyWords = const [],
  }) async {
    final res = await _client.post(
      Uri.parse(AppConfig.speakingUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic': topic,
        'targetBand': targetBand,
        'vocabularyWords': vocabularyWords,
      }),
    );
    _ensureOk(res);
    return SpeakingPractice.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<SpeakingPractice>> getRecent({int limit = 20}) async {
    final res = await _client.get(
        Uri.parse('${AppConfig.speakingUrl}/recent?limit=$limit'));
    _ensureOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => SpeakingPractice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SpeakingPractice>> getByTopic(String topic) async {
    final res = await _client.get(
      Uri.parse('${AppConfig.speakingUrl}/topic/${Uri.encodeComponent(topic)}'),
    );
    _ensureOk(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => SpeakingPractice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
