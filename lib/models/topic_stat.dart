class TopicStat {
  final String topic;
  final int count;
  TopicStat({required this.topic, required this.count});

  factory TopicStat.fromJson(Map<String, dynamic> json) => TopicStat(
        topic: json['topic'] ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}
