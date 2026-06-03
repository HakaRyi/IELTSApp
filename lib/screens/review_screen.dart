import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/review_card.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/floating_background.dart';

class ReviewScreen extends StatefulWidget {
  final ReviewService reviewService;
  const ReviewScreen({super.key, required this.reviewService});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  ReviewStats? _stats;
  List<ReviewCard> _queue = [];
  int _current = 0;
  bool _loading = true;
  bool _rating = false;
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
      _current = 0;
    });
    try {
      final results =
          await Future.wait([widget.reviewService.getDue(), widget.reviewService.getStats()]);
      setState(() {
        _queue = results[0] as List<ReviewCard>;
        _stats = results[1] as ReviewStats;
      });
    } catch (e) {
      setState(() => _error = 'Không tải được: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _rate(int quality) async {
    if (_rating || _current >= _queue.length) return;
    setState(() => _rating = true);
    try {
      await widget.reviewService.rate(_queue[_current].id, quality);
      setState(() {
        _current++;
        if (_current >= _queue.length) _load(); // reload stats when done
      });
    } catch (_) {}
    setState(() => _rating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: FloatingBackground()),
        _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                          child: _buildHeader()),
                      if (_stats != null)
                        SliverToBoxAdapter(
                            child: _buildStats()),
                      if (_queue.isEmpty)
                        SliverFillRemaining(
                            hasScrollBody: false,
                            child: _AllDoneView(onRefresh: _load))
                      else if (_current < _queue.length)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 40),
                            child: _FlashCard(
                              card: _queue[_current],
                              onRate: _rating ? null : _rate,
                              index: _current,
                              total: _queue.length,
                            ),
                          ),
                        )
                      else
                        SliverFillRemaining(
                            hasScrollBody: false,
                            child: _AllDoneView(onRefresh: _load)),
                    ],
                  ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FadeSlideIn(
            child: Text('Ôn tập',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 4),
          const FadeSlideIn(
            delay: Duration(milliseconds: 60),
            child: Text('Spaced Repetition — SM-2',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final s = _stats!;
    return FadeSlideIn(
      delay: const Duration(milliseconds: 100),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(
          children: [
            _StatChip(
                label: 'Tổng',
                value: '${s.total}',
                color: AppColors.primary),
            const SizedBox(width: 10),
            _StatChip(
                label: 'Cần ôn',
                value: '${s.dueToday}',
                color: AppColors.negative),
            const SizedBox(width: 10),
            _StatChip(
                label: 'Thành thạo',
                value: '${s.mastered}',
                color: AppColors.positive),
          ],
        ),
      ),
    );
  }
}

// ─── Flash card ───────────────────────────────────────────────────────────────

class _FlashCard extends StatefulWidget {
  final ReviewCard card;
  final void Function(int quality)? onRate;
  final int index;
  final int total;

  const _FlashCard(
      {required this.card,
      required this.onRate,
      required this.index,
      required this.total});

  @override
  State<_FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<_FlashCard>
    with SingleTickerProviderStateMixin {
  bool _flipped = false;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _flipped = false;
  }

  @override
  void didUpdateWidget(_FlashCard old) {
    super.didUpdateWidget(old);
    if (old.card.id != widget.card.id) {
      _ctrl.reset();
      _flipped = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipped) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _flipped = !_flipped);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: widget.index / widget.total,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            color: AppColors.primary,
            minHeight: 4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('${widget.index + 1} / ${widget.total}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),

        // Card flip
        GestureDetector(
          onTap: _flip,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final angle = _anim.value * math.pi;
              final showBack = angle > math.pi / 2;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: showBack
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(math.pi),
                        alignment: Alignment.center,
                        child: _CardBack(card: widget.card),
                      )
                    : _CardFront(card: widget.card),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (!_flipped)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Nhấn thẻ để xem nghĩa',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.7))),
          ),

        // Rating buttons (show only when flipped)
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          child: _flipped
              ? Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _RatingButtons(onRate: widget.onRate),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CardFront extends StatelessWidget {
  final ReviewCard card;
  const _CardFront({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.topics.isNotEmpty)
            Wrap(
              spacing: 6,
              children: card.topics
                  .take(3)
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(t,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 20),
          Text(card.word,
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(card.type,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_rounded,
                  color: Colors.white54, size: 18),
              const SizedBox(width: 6),
              const Text('Nhấn để lật',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final ReviewCard card;
  const _CardBack({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(card.word,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(card.type,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFEEF2FF)),
          Text(card.definition,
              style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.6)),
          if (card.example.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(card.example,
                        style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.repeat_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                  '${card.repetitions} lần · Interval ${card.interval}d',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingButtons extends StatelessWidget {
  final void Function(int)? onRate;
  const _RatingButtons({required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RateBtn(
            label: 'Quên mất',
            emoji: '😵',
            color: AppColors.negative,
            onTap: onRate == null ? null : () => onRate!(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RateBtn(
            label: 'Nhớ được',
            emoji: '🙂',
            color: AppColors.primary,
            onTap: onRate == null ? null : () => onRate!(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RateBtn(
            label: 'Dễ dàng',
            emoji: '😎',
            color: AppColors.positive,
            onTap: onRate == null ? null : () => onRate!(5),
          ),
        ),
      ],
    );
  }
}

class _RateBtn extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback? onTap;
  const _RateBtn(
      {required this.label,
      required this.emoji,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty / done state ───────────────────────────────────────────────────────

class _AllDoneView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _AllDoneView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('Hoàn thành hôm nay!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Không còn từ cần ôn hôm nay.\nHãy thêm từ mới vào kho nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.negative, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
