import 'package:flutter/material.dart';
import '../models/generated_passage.dart';
import '../models/speaking_practice.dart';
import '../services/practice_service.dart';
import '../services/speaking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/floating_background.dart';

class HistoryScreen extends StatefulWidget {
  final PracticeService practiceService;
  final SpeakingService speakingService;
  const HistoryScreen(
      {super.key,
      required this.practiceService,
      required this.speakingService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<GeneratedPassage> _passages = [];
  List<SpeakingPractice> _speakings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.practiceService.getRecent(limit: 30),
        widget.speakingService.getRecent(limit: 30),
      ]);
      setState(() {
        _passages = results[0] as List<GeneratedPassage>;
        _speakings = results[1] as List<SpeakingPractice>;
      });
    } catch (e) {
      setState(() => _error = 'Không tải được lịch sử: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: FloatingBackground()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FadeSlideIn(
                    child: Text('Lịch sử',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 4),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 60),
                    child: Text('Bài đọc & bài nói đã sinh',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        padding: const EdgeInsets.all(4),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_stories_rounded,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text('Đọc (${_passages.length})'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.record_voice_over_rounded,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text('Nói (${_speakings.length})'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _error != null
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.negative)),
                        ))
                      : TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _PassageList(passages: _passages),
                            _SpeakingList(speakings: _speakings),
                          ],
                        ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Passage history list ─────────────────────────────────────────────────────

class _PassageList extends StatelessWidget {
  final List<GeneratedPassage> passages;
  const _PassageList({required this.passages});

  @override
  Widget build(BuildContext context) {
    if (passages.isEmpty) {
      return const _EmptyState(
          icon: Icons.auto_stories_rounded,
          message: 'Chưa có bài đọc nào\nSinh bài ở tab Đọc nhé');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: passages.length,
      itemBuilder: (_, i) => FadeSlideIn(
        delay: Duration(milliseconds: 40 * i),
        child: _PassageTile(passage: passages[i]),
      ),
    );
  }
}

class _PassageTile extends StatefulWidget {
  final GeneratedPassage passage;
  const _PassageTile({required this.passage});

  @override
  State<_PassageTile> createState() => _PassageTileState();
}

class _PassageTileState extends State<_PassageTile> {
  bool _expanded = false;
  bool _showVI = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.passage;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.article_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.topic,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 3),
                        Text(
                            'Band ${p.targetBand.toStringAsFixed(1)} · ${_fmtDate(p.createdAt)}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Color(0xFFEEF2FF)),
                        const SizedBox(height: 8),
                        // EN/VI toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _LangBtn(
                                label: 'EN',
                                active: !_showVI,
                                onTap: () =>
                                    setState(() => _showVI = false)),
                            const SizedBox(width: 8),
                            _LangBtn(
                                label: 'VI',
                                active: _showVI,
                                onTap: () =>
                                    setState(() => _showVI = true)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            key: ValueKey(_showVI),
                            _showVI
                                ? p.vietnameseTranslation
                                : p.englishContent,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.7,
                                color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Speaking history list ────────────────────────────────────────────────────

class _SpeakingList extends StatelessWidget {
  final List<SpeakingPractice> speakings;
  const _SpeakingList({required this.speakings});

  @override
  Widget build(BuildContext context) {
    if (speakings.isEmpty) {
      return const _EmptyState(
          icon: Icons.record_voice_over_rounded,
          message: 'Chưa có bài nói nào\nSinh bài ở tab Nói nhé');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: speakings.length,
      itemBuilder: (_, i) => FadeSlideIn(
        delay: Duration(milliseconds: 40 * i),
        child: _SpeakingTile(s: speakings[i]),
      ),
    );
  }
}

class _SpeakingTile extends StatefulWidget {
  final SpeakingPractice s;
  const _SpeakingTile({required this.s});

  @override
  State<_SpeakingTile> createState() => _SpeakingTileState();
}

class _SpeakingTileState extends State<_SpeakingTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.formal.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.record_voice_over_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.topic,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 3),
                        Text(
                            'Band ${s.targetBand.toStringAsFixed(1)} · ${_fmtDate(s.createdAt)} · ${s.part1.length + s.part3.length + 1} câu hỏi',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Color(0xFFEEF2FF)),
                        const SizedBox(height: 8),
                        _PartSummary(
                            label: 'Part 1',
                            qas: s.part1
                                .map((q) => q.question)
                                .toList()),
                        const SizedBox(height: 6),
                        _PartSummary(
                            label: 'Part 2',
                            qas: [s.part2.cueCard]),
                        const SizedBox(height: 6),
                        _PartSummary(
                            label: 'Part 3',
                            qas: s.part3
                                .map((q) => q.question)
                                .toList()),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PartSummary extends StatelessWidget {
  final String label;
  final List<String> qas;
  const _PartSummary({required this.label, required this.qas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 4),
        ...qas.map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 8),
              child: Text('• $q',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
            )),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _LangBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 64,
              color: AppColors.primaryLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d.toLocal()).inDays;
  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Hôm qua';
  return '${d.day}/${d.month}/${d.year}';
}
