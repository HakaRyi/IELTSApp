import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/speaking_practice.dart';
import '../services/lexical_service.dart';
import '../services/speaking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/floating_background.dart';

class SpeakingScreen extends StatefulWidget {
  final LexicalService lexicalService;
  final SpeakingService speakingService;
  const SpeakingScreen({
    super.key,
    required this.lexicalService,
    required this.speakingService,
  });

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final _topicCtrl = TextEditingController();
  double _band = 6.5;
  bool _generating = false;
  String? _error;
  SpeakingPractice? _result;

  // Topics từ vault để gợi ý
  List<String> _topics = [];
  String? _selectedTopic;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    try {
      final t = await widget.lexicalService.getTopics();
      setState(() => _topics = t);
    } catch (_) {}
  }

  void _pickTopic(String topic) {
    setState(() {
      _selectedTopic = topic;
      _topicCtrl.text = topic;
    });
  }

  Future<void> _generate() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      setState(() => _error = 'Nhập chủ đề trước nhé');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
      _result = null;
    });
    try {
      final practice = await widget.speakingService.generateSpeaking(
        topic: topic,
        targetBand: _band,
      );
      setState(() => _result = practice);
    } catch (e) {
      setState(() => _error = 'Lỗi sinh bài: $e');
    } finally {
      setState(() => _generating = false);
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
                    // Header
                    const FadeSlideIn(
                      child: Text('Luyện nói',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                    ),
                    const SizedBox(height: 4),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 60),
                      child: Text('IELTS Speaking Part 1 · 2 · 3',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ),
                    const SizedBox(height: 20),

                    // Topic input
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: _buildTopicField(),
                    ),
                    const SizedBox(height: 12),

                    // Topic chips từ vault
                    if (_topics.isNotEmpty)
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 130),
                        child: _buildTopicChips(),
                      ),
                    const SizedBox(height: 16),

                    // Band selector
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: _buildBandSelector(),
                    ),
                    const SizedBox(height: 16),

                    // Error
                    if (_error != null)
                      FadeSlideIn(
                        child: Container(
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
                      ),

                    // Generate button
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 170),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _generating ? null : _generate,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _generating
                              ? const _GeneratingIndicator()
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.record_voice_over_rounded,
                                        size: 20),
                                    SizedBox(width: 8),
                                    Text('Sinh bài nói',
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

            // Result
            if (_result != null) ...[
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _buildVocabStrip(_result!.usedVocabulary),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _Part1Card(qas: _result!.part1),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _Part2Card(part2: _result!.part2),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: _Part3Card(qas: _result!.part3),
                  ),
                ),
              ),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ],
    );
  }

  Widget _buildTopicField() {
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
        controller: _topicCtrl,
        onChanged: (_) => setState(() => _selectedTopic = null),
        decoration: InputDecoration(
          hintText: 'Chủ đề (vd: Environment, Health, Work...)',
          hintStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.topic_rounded,
              color: AppColors.primary, size: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textInputAction: TextInputAction.done,
      ),
    );
  }

  Widget _buildTopicChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _topics.map((t) {
          final sel = _selectedTopic == t;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _pickTopic(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent])
                      : null,
                  color: sel ? null : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: sel ? 0.25 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Text(t,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: sel ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBandSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Band mục tiêu',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_band.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor:
                  AppColors.primaryLight.withValues(alpha: 0.3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 4,
            ),
            child: Slider(
              value: _band,
              min: 4.0,
              max: 9.0,
              divisions: 10,
              onChanged: (v) => setState(() => _band = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['4.0', '5.0', '6.0', '7.0', '8.0', '9.0']
                  .map((l) => Text(l,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabStrip(List<String> vocab) {
    if (vocab.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Từ vựng được dùng',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: vocab
              .map((w) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(w,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Part cards ───────────────────────────────────────────────────────────────

class _PartHeader extends StatelessWidget {
  final String label;
  final String title;
  final List<Color> gradientColors;
  const _PartHeader(
      {required this.label,
      required this.title,
      required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }
}

class _QAItem extends StatefulWidget {
  final String question;
  final String answer;
  final int index;
  const _QAItem(
      {required this.question, required this.answer, required this.index});

  @override
  State<_QAItem> createState() => _QAItemState();
}

class _QAItemState extends State<_QAItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.index > 0)
          const Divider(height: 1, color: Color(0xFFEEF2FF)),
        // Question row
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('Q',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.question,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.4)),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
          ),
        ),
        // Answer (expandable)
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          child: _expanded
              ? Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_quote_rounded,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 6),
                          const Text('Model Answer',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: widget.answer));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã copy câu trả lời'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Icon(Icons.copy_rounded,
                                size: 16, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(widget.answer,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.65)),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _Part1Card extends StatelessWidget {
  final List<SpeakingQA> qas;
  const _Part1Card({required this.qas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.09),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PartHeader(
            label: 'P1',
            title: 'Part 1 — Personal Questions',
            gradientColors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          ),
          ...qas.asMap().entries.map(
                (e) => _QAItem(
                    question: e.value.question,
                    answer: e.value.sampleAnswer,
                    index: e.key),
              ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Part2Card extends StatefulWidget {
  final SpeakingPart2 part2;
  const _Part2Card({required this.part2});

  @override
  State<_Part2Card> createState() => _Part2CardState();
}

class _Part2CardState extends State<_Part2Card> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PartHeader(
            label: 'P2',
            title: 'Part 2 — Cue Card',
            gradientColors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cue card box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0891B2).withValues(alpha: 0.06),
                        const Color(0xFF06B6D4).withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.assignment_rounded,
                              size: 16, color: AppColors.accent),
                          SizedBox(width: 6),
                          Text('Cue Card',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(widget.part2.cueCard,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.45)),
                      if (widget.part2.points.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFCFEFF9)),
                        const SizedBox(height: 8),
                        ...widget.part2.points.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.arrow_right_rounded,
                                      size: 20, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                      child: Text(p,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                              height: 1.4))),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Show answer toggle
                GestureDetector(
                  onTap: () => setState(() => _showAnswer = !_showAnswer),
                  child: Row(
                    children: [
                      Icon(
                          _showAnswer
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                          size: 20),
                      const SizedBox(width: 6),
                      Text(
                          _showAnswer
                              ? 'Ẩn model answer'
                              : 'Xem model answer (2 phút)',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: _showAnswer
                      ? Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.format_quote_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                const Text('Model Answer',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: widget.part2.sampleAnswer));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã copy câu trả lời'),
                                        duration: Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded,
                                      size: 16,
                                      color: AppColors.textSecondary),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Text(widget.part2.sampleAnswer,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                      height: 1.65)),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Part3Card extends StatelessWidget {
  final List<SpeakingQA> qas;
  const _Part3Card({required this.qas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.formal.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PartHeader(
            label: 'P3',
            title: 'Part 3 — Discussion',
            gradientColors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          ),
          ...qas.asMap().entries.map(
                (e) => _QAItem(
                    question: e.value.question,
                    answer: e.value.sampleAnswer,
                    index: e.key),
              ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Generating animation ─────────────────────────────────────────────────────

class _GeneratingIndicator extends StatefulWidget {
  const _GeneratingIndicator();

  @override
  State<_GeneratingIndicator> createState() => _GeneratingIndicatorState();
}

class _GeneratingIndicatorState extends State<_GeneratingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _dot = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _dot = (_dot + 1) % 4);
          _ctrl.forward(from: 0);
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child:
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          'Đang sinh bài nói${'.' * _dot}',
          style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
