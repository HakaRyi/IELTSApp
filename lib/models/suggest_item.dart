class SuggestItem {
  final String id;
  final String value;
  final String type;
  final List<String> topics;

  SuggestItem(
      {required this.id,
      required this.value,
      required this.type,
      required this.topics});

  factory SuggestItem.fromJson(Map<String, dynamic> json) => SuggestItem(
        id: json['id'] ?? '',
        value: json['value'] ?? '',
        type: json['type'] ?? '',
        topics:
            (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}
