import 'dart:convert';
import 'package:flutter/services.dart';

/// Singleton — load một lần, tìm kiếm prefix tức thì (client-side).
class WordDictionary {
  WordDictionary._();
  static final WordDictionary instance = WordDictionary._();

  List<String> _words = [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/ielts_words.json');
    final list = (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    // Deduplicate + sort
    _words = list.toSet().toList()..sort();
    _loaded = true;
  }

  /// Trả về tối đa [limit] từ bắt đầu bằng [prefix] (case-insensitive).
  List<String> search(String prefix, {int limit = 8}) {
    if (prefix.isEmpty || !_loaded) return [];
    final lower = prefix.toLowerCase();
    return _words
        .where((w) => w.toLowerCase().startsWith(lower))
        .take(limit)
        .toList();
  }
}
