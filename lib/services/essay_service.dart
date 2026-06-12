import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../core/app_http.dart';
import '../models/essay_result.dart';

class EssayService {
  final http.Client _client;
  EssayService({http.Client? client}) : _client = client ?? AppHttp.client;

  Future<EssayResult> score({
    required String prompt,
    required String essayText,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.essaysUrl}/score'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt, 'essayText': essayText}),
    );
    _ensureOk(res);
    return EssayResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<EssayResult>> getRecent({int limit = 20}) async {
    final res = await _client.get(
      Uri.parse('${AppConfig.essaysUrl}/recent?limit=$limit'),
    );
    _ensureOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => EssayResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
