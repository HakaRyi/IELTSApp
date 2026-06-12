import 'package:flutter/material.dart';
import '../core/topic_style.dart';
import '../models/lexical_item.dart';
import '../services/lexical_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/word_card.dart';
import 'detail_screen.dart';

/// Danh sách từ vựng của MỘT chủ đề, nhóm theo ngày tra.
class TopicWordsScreen extends StatefulWidget {
  final LexicalService service;
  final String topic;
  const TopicWordsScreen(
      {super.key, required this.service, required this.topic});

  @override
  State<TopicWordsScreen> createState() => _TopicWordsScreenState();
}

class _TopicWordsScreenState extends State<TopicWordsScreen> {
  List<LexicalItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final paged =
          await widget.service.getVault(topic: widget.topic, pageSize: 100);
      setState(() => _items = paged.items);
    } catch (_) {
      setState(() => _error = 'Không tải được danh sách từ.');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Nhóm theo ngày tra: "Hôm nay" / "Hôm qua" / dd/MM/yyyy / "Trước đây" (data cũ).
  List<MapEntry<String, List<LexicalItem>>> _groupByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String labelFor(LexicalItem item) {
      final c = item.createdAt;
      if (c == null) return 'Trước đây';
      final day = DateTime(c.year, c.month, c.day);
      final diff = today.difference(day).inDays;
      if (diff == 0) return 'Hôm nay';
      if (diff == 1) return 'Hôm qua';
      return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
    }

    final groups = <String, List<LexicalItem>>{};
    for (final item in _items) {
      groups.putIfAbsent(labelFor(item), () => []).add(item);
    }
    // _items đã sort CreatedAt desc từ backend → giữ thứ tự xuất hiện của nhóm
    return groups.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = TopicStyle.color(widget.topic);
    final emoji = TopicStyle.emoji(widget.topic);
    final groups = _groupByDate();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            PulsingEmoji(emoji, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(widget.topic,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_items.length}',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const WigglingEmoji('😵', size: 44),
                      const SizedBox(height: 10),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.negative)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    children: [
                      for (var g = 0; g < groups.length; g++) ...[
                        // Header ngày
                        FadeSlideIn(
                          delay: Duration(milliseconds: 40 * g),
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: g == 0 ? 0 : 16, bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('📅',
                                          style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 5),
                                      Text(groups[g].key,
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: color)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                      height: 1,
                                      color: color.withValues(alpha: 0.15)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Các từ trong ngày
                        ...groups[g].value.map((item) => FadeSlideIn(
                              delay: Duration(milliseconds: 60 * g + 30),
                              child: WordCard(
                                item: item,
                                onTap: () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailScreen(
                                        service: widget.service,
                                        item: item,
                                        isNew: false,
                                      ),
                                    ),
                                  );
                                  if (changed == true) _load();
                                },
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
    );
  }
}
