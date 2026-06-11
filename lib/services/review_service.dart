import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../core/app_http.dart';
import '../models/review_card.dart';

class ReviewStats {
  final int total;
  final int dueToday;
  final int mastered;
  ReviewStats(
      {required this.total, required this.dueToday, required this.mastered});
  factory ReviewStats.fromJson(Map<String, dynamic> json) => ReviewStats(
        total: json['total'] ?? 0,
        dueToday: json['dueToday'] ?? 0,
        mastered: json['mastered'] ?? 0,
      );
}

class ReviewService {
  final http.Client _client;
  ReviewService({http.Client? client}) : _client = client ?? AppHttp.client;

  Future<ReviewCard> enroll({
    required String lexicalItemId,
    required String word,
    required String type,
    required String definition,
    String example = '',
    List<String> topics = const [],
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.reviewUrl}/enroll'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'lexicalItemId': lexicalItemId,
        'word': word,
        'type': type,
        'definition': definition,
        'example': example,
        'topics': topics,
      }),
    );
    _ensureOk(res);
    return ReviewCard.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<ReviewCard>> getDue() async {
    final res = await _client.get(Uri.parse('${AppConfig.reviewUrl}/due'));
    _ensureOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => ReviewCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// quality: 1=Again, 3=Good, 5=Easy
  Future<ReviewCard> rate(String cardId, int quality) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.reviewUrl}/$cardId/rate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'quality': quality}),
    );
    _ensureOk(res);
    return ReviewCard.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ReviewStats> getStats() async {
    final res = await _client.get(Uri.parse('${AppConfig.reviewUrl}/stats'));
    _ensureOk(res);
    return ReviewStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> delete(String cardId) async {
    final res =
        await _client.delete(Uri.parse('${AppConfig.reviewUrl}/$cardId'));
    _ensureOk(res);
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
