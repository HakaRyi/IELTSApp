class CriterionScore {
  final double band;
  final String comment;
  CriterionScore({required this.band, required this.comment});
  factory CriterionScore.fromJson(Map<String, dynamic> json) => CriterionScore(
        band: (json['band'] as num?)?.toDouble() ?? 0,
        comment: json['comment'] ?? '',
      );
}

class EssayResult {
  final String id;
  final String prompt;
  final String essayText;
  final int wordCount;
  final double overallBand;
  final CriterionScore taskResponse;
  final CriterionScore coherenceCohesion;
  final CriterionScore lexicalResource;
  final CriterionScore grammaticalRange;
  final String generalFeedback;
  final List<String> improvements;
  final List<String> usedTargetVocabulary;
  final DateTime createdAt;

  EssayResult({
    required this.id,
    required this.prompt,
    required this.essayText,
    required this.wordCount,
    required this.overallBand,
    required this.taskResponse,
    required this.coherenceCohesion,
    required this.lexicalResource,
    required this.grammaticalRange,
    required this.generalFeedback,
    required this.improvements,
    required this.usedTargetVocabulary,
    required this.createdAt,
  });

  factory EssayResult.fromJson(Map<String, dynamic> json) => EssayResult(
        id: json['id'] ?? '',
        prompt: json['prompt'] ?? '',
        essayText: json['essayText'] ?? '',
        wordCount: json['wordCount'] ?? 0,
        overallBand: (json['overallBand'] as num?)?.toDouble() ?? 0,
        taskResponse:
            CriterionScore.fromJson(json['taskResponse'] ?? const {}),
        coherenceCohesion:
            CriterionScore.fromJson(json['coherenceCohesion'] ?? const {}),
        lexicalResource:
            CriterionScore.fromJson(json['lexicalResource'] ?? const {}),
        grammaticalRange:
            CriterionScore.fromJson(json['grammaticalRange'] ?? const {}),
        generalFeedback: json['generalFeedback'] ?? '',
        improvements:
            (json['improvements'] as List?)?.map((e) => e.toString()).toList() ?? [],
        usedTargetVocabulary: (json['usedTargetVocabulary'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
