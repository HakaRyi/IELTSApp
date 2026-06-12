class GeneratedPassage {
  final String id;
  final String topic;
  final double targetBand;
  final String englishContent;
  final String vietnameseTranslation;
  final List<String> usedLexicalItemIds;
  final List<String> usedVocabulary;
  final DateTime createdAt;

  GeneratedPassage({
    required this.id,
    required this.topic,
    required this.targetBand,
    required this.englishContent,
    required this.vietnameseTranslation,
    required this.usedLexicalItemIds,
    required this.usedVocabulary,
    required this.createdAt,
  });

  factory GeneratedPassage.fromJson(Map<String, dynamic> json) {
    return GeneratedPassage(
      id: json['id'] ?? '',
      topic: json['topic'] ?? '',
      targetBand: (json['targetBand'] as num?)?.toDouble() ?? 6.0,
      englishContent: json['englishContent'] ?? '',
      vietnameseTranslation: json['vietnameseTranslation'] ?? '',
      usedLexicalItemIds:
          (json['usedLexicalItemIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      usedVocabulary:
          (json['usedVocabulary'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
