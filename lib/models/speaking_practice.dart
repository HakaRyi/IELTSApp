class SpeakingPractice {
  final String id;
  final String topic;
  final double targetBand;
  final List<SpeakingQA> part1;
  final SpeakingPart2 part2;
  final List<SpeakingQA> part3;
  final List<String> usedVocabulary;
  final DateTime createdAt;

  SpeakingPractice({
    required this.id,
    required this.topic,
    required this.targetBand,
    required this.part1,
    required this.part2,
    required this.part3,
    required this.usedVocabulary,
    required this.createdAt,
  });

  factory SpeakingPractice.fromJson(Map<String, dynamic> json) {
    return SpeakingPractice(
      id: json['id'] ?? '',
      topic: json['topic'] ?? '',
      targetBand: (json['targetBand'] as num?)?.toDouble() ?? 6.0,
      part1: (json['part1'] as List?)
              ?.map((e) => SpeakingQA.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      part2: json['part2'] != null
          ? SpeakingPart2.fromJson(json['part2'] as Map<String, dynamic>)
          : SpeakingPart2(cueCard: '', points: [], sampleAnswer: ''),
      part3: (json['part3'] as List?)
              ?.map((e) => SpeakingQA.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usedVocabulary:
          (json['usedVocabulary'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SpeakingQA {
  final String question;
  final String sampleAnswer;
  SpeakingQA({required this.question, required this.sampleAnswer});
  factory SpeakingQA.fromJson(Map<String, dynamic> json) => SpeakingQA(
        question: json['question'] ?? '',
        sampleAnswer: json['sampleAnswer'] ?? '',
      );
}

class SpeakingPart2 {
  final String cueCard;
  final List<String> points;
  final String sampleAnswer;
  SpeakingPart2({
    required this.cueCard,
    required this.points,
    required this.sampleAnswer,
  });
  factory SpeakingPart2.fromJson(Map<String, dynamic> json) => SpeakingPart2(
        cueCard: json['cueCard'] ?? '',
        points: (json['points'] as List?)?.map((e) => e.toString()).toList() ?? [],
        sampleAnswer: json['sampleAnswer'] ?? '',
      );
}
