import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/generated_passage.dart';

class PracticeService {
  final http.Client _client;
  PracticeService({http.Client? client}) : _client = client ?? http.Client();

  Future<GeneratedPassage> generatePassage({
    required String topic,
    required double targetBand,
    required List<String> lexicalItemIds,
  }) async {
    final res = await _client.post(
      Uri.parse(AppConfig.passagesUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic': topic,
        'targetBand': targetBand,
        'lexicalItemIds': lexicalItemIds,
      }),
    );
    _ensureOk(res);
    return GeneratedPassage.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<GeneratedPassage>> getRecent({int limit = 20}) async {
    final res = await _client.get(
        Uri.parse('${AppConfig.passagesUrl}/recent?limit=$limit'));
    _ensureOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => GeneratedPassage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GeneratedPassage>> getPassagesByTopic(String topic) async {
    final res = await _client.get(
      Uri.parse('${AppConfig.passagesUrl}/topic/${Uri.encodeComponent(topic)}'),
    );
    _ensureOk(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => GeneratedPassage.fromJson(e as Map<String, dynamic>)).toList();
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
