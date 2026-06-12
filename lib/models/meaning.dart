class Meaning {
  final String definition;
  final String connotation;

  /// Độ mạnh sắc thái 1-5 (0 = không có dữ liệu — từ lưu trước đây).
  final int intensity;

  /// Giải thích sắc thái, so sánh với từ gần nghĩa.
  final String intensityNote;

  final List<String> examples;

  Meaning({
    required this.definition,
    this.connotation = 'Neutral',
    this.intensity = 0,
    this.intensityNote = '',
    this.examples = const [],
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      definition: json['definition'] ?? '',
      connotation: json['connotation'] ?? 'Neutral',
      intensity: (json['intensity'] as num?)?.toInt() ?? 0,
      intensityNote: json['intensityNote'] ?? '',
      examples: (json['examples'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'definition': definition,
        'connotation': connotation,
        'intensity': intensity,
        'intensityNote': intensityNote,
        'examples': examples,
      };
}
