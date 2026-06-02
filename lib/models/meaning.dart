class Meaning {
  final String definition;
  final String connotation;
  final List<String> examples;

  Meaning({
    required this.definition,
    this.connotation = 'Neutral',
    this.examples = const [],
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      definition: json['definition'] ?? '',
      connotation: json['connotation'] ?? 'Neutral',
      examples: (json['examples'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'definition': definition,
        'connotation': connotation,
        'examples': examples,
      };
}
