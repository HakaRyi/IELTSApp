/// Các dạng câu hỏi IELTS Reading được hỗ trợ.
class PassageQuestionType {
  PassageQuestionType._();
  static const multipleChoice = 'MultipleChoice';
  static const shortAnswer = 'ShortAnswer';
  static const tableCompletion = 'TableCompletion';
  static const matchingHeadings = 'MatchingHeadings';
  static const trueFalseNotGiven = 'TrueFalseNotGiven';
  static const yesNoNotGiven = 'YesNoNotGiven';

  /// Tên hiển thị tiếng Việt cho UI.
  static String label(String type) => switch (type) {
        shortAnswer => 'Short-answer question',
        tableCompletion => 'Table Completion',
        matchingHeadings => 'Matching Headings',
        trueFalseNotGiven => 'True / False / Not Given',
        yesNoNotGiven => 'Yes / No / Not Given',
        _ => 'Multiple Choice',
      };

  static const all = [
    multipleChoice,
    shortAnswer,
    tableCompletion,
    matchingHeadings,
    trueFalseNotGiven,
    yesNoNotGiven,
  ];
}

class PassageQuestion {
  final int number;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  PassageQuestion({
    required this.number,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory PassageQuestion.fromJson(Map<String, dynamic> json) => PassageQuestion(
        number: (json['number'] as num?)?.toInt() ?? 0,
        question: json['question'] ?? '',
        options:
            (json['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        correctAnswer: json['correctAnswer'] ?? '',
        explanation: json['explanation'] ?? '',
      );
}

class PassageTable {
  final List<String> headers;
  final List<List<String>> rows;

  PassageTable({required this.headers, required this.rows});

  factory PassageTable.fromJson(Map<String, dynamic> json) => PassageTable(
        headers:
            (json['headers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        rows: (json['rows'] as List?)
                ?.map((r) =>
                    (r as List).map((c) => c.toString()).toList())
                .toList() ??
            const [],
      );
}

class GeneratedPassage {
  final String id;
  final String topic;
  final double targetBand;
  final String englishContent;
  final String vietnameseTranslation;
  final List<String> usedLexicalItemIds;
  final List<String> usedVocabulary;

  final String questionType;
  final String instructions;
  final List<PassageQuestion> questions;
  final PassageTable? table;

  final DateTime createdAt;

  GeneratedPassage({
    required this.id,
    required this.topic,
    required this.targetBand,
    required this.englishContent,
    required this.vietnameseTranslation,
    required this.usedLexicalItemIds,
    required this.usedVocabulary,
    required this.questionType,
    required this.instructions,
    required this.questions,
    required this.table,
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
      questionType: json['questionType'] ?? PassageQuestionType.multipleChoice,
      instructions: json['instructions'] ?? '',
      questions: (json['questions'] as List?)
              ?.map((q) => PassageQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
      table: json['table'] == null
          ? null
          : PassageTable.fromJson(json['table'] as Map<String, dynamic>),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
