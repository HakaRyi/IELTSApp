import 'package:flutter/material.dart';
import '../models/essay_result.dart';
import '../services/essay_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/floating_background.dart';

class EssayScreen extends StatefulWidget {
  final EssayService essayService;
  const EssayScreen({super.key, required this.essayService});

  @override
  State<EssayScreen> createState() => _EssayScreenState();
}

class _EssayScreenState extends State<EssayScreen> {
  final _promptCtrl = TextEditingController();
  final _essayCtrl = TextEditingController();
  bool _scoring = false;
  String? _error;
  EssayResult? _result;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _essayCtrl.addListener(() {
      final wc = _essayCtrl.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      if (wc != _wordCount) setState(() => _wordCount = wc);
    });
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _essayCtrl.dispose();
    super.dispose();
  }

  Future<void> _score() async {
    final prompt = _promptCtrl.text.trim();
    final essay = _essayCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = 'Nhập đề bài trước nhé');
      return;
    }
    if (_wordCount < 50) {
      setState(() => _error = 'Bài viết quá ngắn (nên ≥ 250 từ cho Task 2)');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _scoring = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await widget.essayService.score(prompt: prompt, essayText: essay);
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = 'Lỗi chấm bài: $e');
    } finally {
      setState(() => _scoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: FloatingBackground()),
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FadeSlideIn(
                      child: Text('Luyện viết',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                    ),
                    const SizedBox(height: 4),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 60),
                      child: Text('IELTS Writing Task 2 — chấm theo 4 tiêu chí',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ),
                    const SizedBox(height: 20),

                    // Prompt
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: _Field(
                        controller: _promptCtrl,
                        hint: 'Đề bài (vd: Some people think... To what extent do you agree?)',
                        icon: Icons.assignment_rounded,
                        minLines: 2,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Essay
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: _Field(
                        controller: _essayCtrl,
                        hint: 'Viết bài của bạn ở đây...',
                        icon: Icons.edit_note_rounded,
                        minLines: 8,
                        maxLines: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('$_wordCount từ',
                          style: TextStyle(
                              fontSize: 12,
                              color: _wordCount >= 250
                                  ? AppColors.positive
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),

                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.negative.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.negative, fontSize: 13)),
                      ),

                    FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _scoring ? null : _score,
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: _scoring
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white)),
                                    SizedBox(width: 10),
                                    Text('Đang chấm bài...',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.grading_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('Chấm điểm',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_result != null)
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: _ScoreCard(result: _result!),
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ],
    );
  }
}

// ─── Result card ──────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final EssayResult result;
  const _ScoreCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall band header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Text('Overall Band',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                Text(result.overallBand.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        height: 1.1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Criterion('Task Response', result.taskResponse),
                _Criterion('Coherence & Cohesion', result.coherenceCohesion),
                _Criterion('Lexical Resource', result.lexicalResource),
                _Criterion('Grammatical Range', result.grammaticalRange),

                if (result.generalFeedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _SectionTitle('Nhận xét chung'),
                  const SizedBox(height: 6),
                  Text(result.generalFeedback,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textPrimary)),
                ],

                if (result.improvements.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _SectionTitle('Gợi ý cải thiện'),
                  const SizedBox(height: 8),
                  ...result.improvements.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded,
                                size: 18, color: AppColors.formal),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(s,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: AppColors.textPrimary))),
                          ],
                        ),
                      )),
                ],

                if (result.usedTargetVocabulary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _SectionTitle('Từ đã học dùng tốt ✓'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: result.usedTargetVocabulary
                        .map((w) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.positive.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.positive
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(w,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.positive,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Criterion extends StatelessWidget {
  final String label;
  final CriterionScore score;
  const _Criterion(this.label, this.score);

  Color get _color {
    if (score.band >= 7) return AppColors.positive;
    if (score.band >= 5.5) return AppColors.primary;
    return AppColors.informal;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(score.band.toStringAsFixed(1),
                    style: TextStyle(
                        color: _color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score.band / 9).clamp(0, 1),
              minHeight: 5,
              backgroundColor: _color.withValues(alpha: 0.12),
              color: _color,
            ),
          ),
          if (score.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(score.comment,
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.textSecondary));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int minLines;
  final int maxLines;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.minLines,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}
