import 'package:flutter/material.dart';
import '../core/topic_style.dart';
import '../models/lexical_item.dart';
import '../models/topic_stat.dart';
import '../services/lexical_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/word_card.dart';
import 'detail_screen.dart';
import 'topic_words_screen.dart';

class VaultScreen extends StatefulWidget {
  final LexicalService service;
  const VaultScreen({super.key, required this.service});

  @override
  State<VaultScreen> createState() => VaultScreenState();
}

class VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  List<TopicStat> _topics = [];
  List<LexicalItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    refresh();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // chạy song song, giữ đúng kiểu
      final topicsFuture = widget.service.getTopicStats();
      final vaultFuture = widget.service.getVault(pageSize: 100);
      final topics = await topicsFuture;
      final paged = await vaultFuture;
      setState(() {
        _topics = topics;
        _items = paged.items;
      });
    } catch (e) {
      setState(() => _error = 'Không tải được kho từ. Kiểm tra kết nối API.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openTopic(TopicStat stat) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicWordsScreen(
          service: widget.service,
          topic: stat.topic,
        ),
      ),
    );
    refresh(); // về lại thì làm mới (có thể đã sửa/xóa từ)
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FadeSlideIn(
                child: Row(
                  children: [
                    Text('Kho từ vựng',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    SizedBox(width: 8),
                    PulsingEmoji('📚', size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: '🗂️ Chủ đề'),
                      Tab(text: '🔤 Từ vựng'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: refresh)
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _TopicsTab(topics: _topics, onTapTopic: _openTopic),
                        _WordsTab(
                            items: _items,
                            service: widget.service,
                            onChanged: refresh),
                      ],
                    ),
        ),
      ],
    );
  }
}

// ─── Tab 1: Chủ đề (grid icon + tên + số từ) ─────────────────────────────────

class _TopicsTab extends StatelessWidget {
  final List<TopicStat> topics;
  final void Function(TopicStat) onTapTopic;
  const _TopicsTab({required this.topics, required this.onTapTopic});

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const _EmptyState(
        emoji: '🌱',
        title: 'Chưa có chủ đề nào',
        subtitle: 'Tra và lưu từ — chủ đề sẽ tự xuất hiện ở đây',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: topics.length,
      itemBuilder: (_, i) {
        final t = topics[i];
        final color = TopicStyle.color(t.topic);
        return FadeSlideIn(
          delay: Duration(milliseconds: 50 * i),
          child: Bouncy(
            onTap: () => onTapTopic(t),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(TopicStyle.emoji(t.topic),
                            style: const TextStyle(fontSize: 20)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${t.count} từ',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    t.topic,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab 2: Từ vựng (danh sách tất cả) ───────────────────────────────────────

class _WordsTab extends StatelessWidget {
  final List<LexicalItem> items;
  final LexicalService service;
  final VoidCallback onChanged;
  const _WordsTab(
      {required this.items, required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        emoji: '🔤',
        title: 'Kho từ đang trống',
        subtitle: 'Tra một từ ở tab Tra từ rồi lưu lại nhé',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return FadeSlideIn(
          delay: Duration(milliseconds: 40 * (i < 12 ? i : 12)),
          child: WordCard(
            item: item,
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(
                      service: service, item: item, isNew: false),
                ),
              );
              if (changed == true) onChanged();
            },
          ),
        );
      },
    );
  }
}

// ─── States ──────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WigglingEmoji(emoji, size: 52),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WigglingEmoji('😵', size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.negative)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
