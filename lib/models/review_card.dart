class ReviewCard {
  final String id;
  final String lexicalItemId;
  final String word;
  final String type;
  final String definition;
  final String example;
  final List<String> topics;
  final int repetitions;
  final double easeFactor;
  final int interval;
  final DateTime nextReviewAt;
  final DateTime enrolledAt;
  final DateTime? lastReviewedAt;

  ReviewCard({
    required this.id,
    required this.lexicalItemId,
    required this.word,
    required this.type,
    required this.definition,
    required this.example,
    required this.topics,
    required this.repetitions,
    required this.easeFactor,
    required this.interval,
    required this.nextReviewAt,
    required this.enrolledAt,
    this.lastReviewedAt,
  });

  factory ReviewCard.fromJson(Map<String, dynamic> json) => ReviewCard(
        id: json['id'] ?? '',
        lexicalItemId: json['lexicalItemId'] ?? '',
        word: json['word'] ?? '',
        type: json['type'] ?? '',
        definition: json['definition'] ?? '',
        example: json['example'] ?? '',
        topics:
            (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
        repetitions: json['repetitions'] ?? 0,
        easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
        interval: json['interval'] ?? 1,
        nextReviewAt: DateTime.tryParse(json['nextReviewAt'] ?? '') ?? DateTime.now(),
        enrolledAt: DateTime.tryParse(json['enrolledAt'] ?? '') ?? DateTime.now(),
        lastReviewedAt: json['lastReviewedAt'] != null
            ? DateTime.tryParse(json['lastReviewedAt'])
            : null,
      );

  bool get isDue => nextReviewAt.isBefore(DateTime.now().toUtc());
  bool get isMastered => interval >= 21;
}
