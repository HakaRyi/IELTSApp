import 'meaning.dart';

class LexicalItem {
  final String? id;
  final String value;
  final String type;
  final List<String> topics;
  final List<Meaning> meanings;
  final List<String> synonyms;
  final List<String> antonyms;
  final String personalNotes;

  /// Ngày tra/lưu từ — null với dữ liệu cũ (không có trường này).
  final DateTime? createdAt;

  LexicalItem({
    this.id,
    required this.value,
    required this.type,
    this.topics = const [],
    this.meanings = const [],
    this.synonyms = const [],
    this.antonyms = const [],
    this.personalNotes = '',
    this.createdAt,
  });

  factory LexicalItem.fromJson(Map<String, dynamic> json) {
    return LexicalItem(
      id: json['id'] as String?,
      value: json['value'] ?? '',
      type: json['type'] ?? '',
      topics:
          (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      meanings: (json['meanings'] as List?)
              ?.map((e) => Meaning.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      synonyms:
          (json['synonyms'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      antonyms:
          (json['antonyms'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      personalNotes: json['personalNotes'] ?? '',
      createdAt: _parseCreatedAt(json['createdAt']),
    );
  }

  static DateTime? _parseCreatedAt(dynamic raw) {
    if (raw == null) return null;
    final d = DateTime.tryParse(raw.toString());
    // Data cũ không có CreatedAt → backend trả 0001-01-01 → coi như null
    if (d == null || d.year < 2000) return null;
    return d.toLocal();
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'type': type,
        'topics': topics,
        'meanings': meanings.map((m) => m.toJson()).toList(),
        'synonyms': synonyms,
        'antonyms': antonyms,
        'personalNotes': personalNotes,
      };

  LexicalItem copyWith({
    String? id,
    String? value,
    String? type,
    List<String>? topics,
    List<Meaning>? meanings,
    List<String>? synonyms,
    List<String>? antonyms,
    String? personalNotes,
  }) {
    return LexicalItem(
      id: id ?? this.id,
      value: value ?? this.value,
      type: type ?? this.type,
      topics: topics ?? this.topics,
      meanings: meanings ?? this.meanings,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      personalNotes: personalNotes ?? this.personalNotes,
      createdAt: createdAt,
    );
  }
}
