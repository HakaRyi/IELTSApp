import 'package:flutter/material.dart';

/// Gán emoji + màu cho mỗi chủ đề (match theo từ khóa, fallback theo hash).
class TopicStyle {
  TopicStyle._();

  static const _palette = [
    Color(0xFF2563EB), // blue
    Color(0xFF06B6D4), // cyan
    Color(0xFF16A34A), // green
    Color(0xFF7C3AED), // purple
    Color(0xFFEA580C), // orange
    Color(0xFFDB2777), // pink
    Color(0xFF0D9488), // teal
    Color(0xFFCA8A04), // amber
  ];

  static const _keywords = <String, String>{
    'environment': '🌿', 'nature': '🌿', 'climate': '🌍', 'pollution': '🏭',
    'technology': '💻', 'computer': '💻', 'internet': '🌐', 'ai': '🤖',
    'health': '🏥', 'medic': '💊', 'fitness': '💪', 'sport': '⚽',
    'education': '🎓', 'school': '🏫', 'study': '📖', 'learn': '📖',
    'work': '💼', 'job': '💼', 'career': '💼', 'business': '📈',
    'money': '💰', 'econom': '💹', 'finance': '💰',
    'travel': '✈️', 'tourism': '🧳', 'transport': '🚗',
    'food': '🍜', 'cook': '🍳', 'diet': '🥗',
    'family': '👨‍👩‍👧', 'relationship': '💞', 'friend': '🤝',
    'culture': '🎭', 'art': '🎨', 'music': '🎵', 'movie': '🎬', 'film': '🎬',
    'book': '📚', 'read': '📚', 'media': '📰', 'news': '📰',
    'city': '🏙️', 'urban': '🏙️', 'house': '🏠', 'home': '🏠',
    'science': '🔬', 'space': '🚀', 'animal': '🐾', 'plant': '🌱',
    'fashion': '👗', 'shop': '🛍️', 'communicat': '💬', 'language': '🗣️',
    'crime': '⚖️', 'law': '⚖️', 'government': '🏛️', 'politic': '🏛️',
    'energy': '⚡', 'water': '💧', 'weather': '⛅', 'history': '📜',
    'psychology': '🧠', 'emotion': '💗', 'society': '🌏', 'social': '🌏',
  };

  static String emoji(String topic) {
    final t = topic.toLowerCase();
    for (final e in _keywords.entries) {
      if (t.contains(e.key)) return e.value;
    }
    return '📚';
  }

  static Color color(String topic) =>
      _palette[topic.toLowerCase().hashCode.abs() % _palette.length];
}
