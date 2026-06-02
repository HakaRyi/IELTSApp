import 'package:flutter/material.dart';
import '../models/lexical_item.dart';
import '../services/lexical_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/topic_chip.dart';
import '../widgets/word_card.dart';
import 'detail_screen.dart';

class VaultScreen extends StatefulWidget {
  final LexicalService service;
  const VaultScreen({super.key, required this.service});

  @override
  State<VaultScreen> createState() => VaultScreenState();
}

class VaultScreenState extends State<VaultScreen> {
  List<String> _topics = [];
  String? _selectedTopic;
  List<LexicalItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final topics = await widget.service.getTopics();
      final paged = await widget.service.getVault(topic: _selectedTopic);
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

  void _selectTopic(String? topic) {
    setState(() => _selectedTopic = topic);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FadeSlideIn(
                    child: Text(
                      'Kho từ vựng',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_topics.isNotEmpty)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            TopicChip(
                              label: 'Tất cả',
                              selected: _selectedTopic == null,
                              onTap: () => _selectTopic(null),
                            ),
                            const SizedBox(width: 8),
                            ..._topics.expand((t) => [
                                  TopicChip(
                                    label: t,
                                    selected: _selectedTopic == t,
                                    onTap: () => _selectTopic(t),
                                  ),
                                  const SizedBox(width: 8),
                                ]),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.negative)),
                ),
              ),
            )
          else if (_items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _items[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 60 * index),
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
                          if (changed == true) refresh();
                        },
                      ),
                    );
                  },
                  childCount: _items.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 64, color: AppColors.primaryLight.withOpacity(0.6)),
          const SizedBox(height: 16),
          const Text(
            'Kho từ đang trống',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tra một từ ở tab Tra từ rồi lưu lại nhé',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
