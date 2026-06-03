import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';

import '../models/lexical_item.dart';
import '../models/lookup_result.dart';
import '../models/suggest_item.dart';

class LexicalService {
  String get _baseUrl => AppConfig.lexicalUrl;

  final http.Client _client;
  LexicalService({http.Client? client}) : _client = client ?? http.Client();

  Future<LookupResult> lookup(String word) async {
    final uri = Uri.parse('$_baseUrl/lookup?word=${Uri.encodeComponent(word)}');
    final res = await _client.get(uri);
    _ensureOk(res);
    return LookupResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<PagedResult> getVault({String? topic, int page = 1, int pageSize = 20}) async {
    final params = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    };
    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
    final res = await _client.get(uri);
    _ensureOk(res);
    return PagedResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<SuggestItem>> suggest(String prefix, {int limit = 8}) async {
    if (prefix.trim().isEmpty) return [];
    final uri = Uri.parse('$_baseUrl/suggest').replace(
        queryParameters: {'q': prefix.trim(), 'limit': '$limit'});
    final res = await _client.get(uri);
    _ensureOk(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => SuggestItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getTopics() async {
    final res = await _client.get(Uri.parse('$_baseUrl/topics'));
    _ensureOk(res);
    return (jsonDecode(res.body) as List).map((e) => e.toString()).toList();
  }

  Future<LexicalItem> create(LexicalItem item) async {
    final res = await _client.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    _ensureOk(res);
    return LexicalItem.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> update(String id, LexicalItem item) async {
    final res = await _client.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    _ensureOk(res);
  }

  Future<void> delete(String id) async {
    final res = await _client.delete(Uri.parse('$_baseUrl/$id'));
    _ensureOk(res);
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
