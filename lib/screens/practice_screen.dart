import 'package:flutter/material.dart';
import '../models/generated_passage.dart';
import '../models/lexical_item.dart';
import '../services/lexical_service.dart';
import '../services/practice_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/floating_background.dart';

class PracticeScreen extends StatefulWidget {
  final LexicalService lexicalService;
  final PracticeService practiceService;
  const PracticeScreen({
    super.key,
    required this.lexicalService,
    required this.practiceService,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _topicCtrl = TextEditingController();
  double _band = 6.5;
  bool _generating = false;
  String? _error;
  GeneratedPassage? _result;

  // vocab-pick mode
  List<LexicalItem> _vaultItems = [];
  bool _vaultLoading = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _loadVault();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVault() async {
    setState(() => _vaultLoading = true);
    try {
      final paged = await widget.lexicalService.getVault();
      setState(() => _vaultItems = paged.items);
    } catch (_) {}
    setState(() => _vaultLoading = false);
  }

  Future<void> _generate() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      setState(() => _error = 'Nhập chủ đề trước nhé');
      return;
    }
    if (_tabCtrl.index == 1 && _selectedIds.isEmpty) {
      setState(() => _error = 'Chọn ít nhất 1 từ vựng');
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
      _result = null;
    });

    try {
      final ids = _tabCtrl.index == 1 ? _selectedIds.toList() : <String>[];
      final passage = await widget.practiceService.generatePassage(
        topic: topic,
        targetBand: _band,
        lexicalItemIds: ids,
      );
      setState(() => _result = passage);
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
                    const FadeSlideIn(
                      child: Text(
                        'Luyện đọc',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 60),
                      child: Text(
                        'Sinh bài đọc IELTS từ từ vựng của bạn',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mode tabs
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TabBar(
                          controller: _tabCtrl,
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                            ),
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
                            Tab(text: 'Theo chủ đề'),
                            Tab(text: 'Từ kho từ'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Topic input
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: _buildTopicField(),
                    ),
                    const SizedBox(height: 16),

                    // Band slider
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: _buildBandSelector(),
                    ),
                    const SizedBox(height: 16),

                    // Vocab picker (tab 1 only)
                    if (_tabCtrl.index == 1) ...[
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: _buildVocabPicker(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Error
                    if (_error != null)
                      FadeSlideIn(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.negative.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.negative, fontSize: 13)),
                        ),
                      ),

                    // Generate button
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _generating ? null : _generate,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _generating
                              ? const _GeneratingIndicator()
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('Sinh bài đọc',
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
            if (_result != null)
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: _PassageCard(passage: _result!),
                  ),
                ),
              ),

            if (_result == null && !_generating)
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
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _topicCtrl,
        decoration: InputDecoration(
          hintText: 'Chủ đề (vd: Climate Change, Technology...)',
          hintStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.topic_rounded,
              color: AppColors.primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textInputAction: TextInputAction.done,
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
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
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
                child: Text(
                  _band.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight.withOpacity(0.3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.15),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
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

  Widget _buildVocabPicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.checklist_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Chọn từ vựng',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const Spacer(),
                if (_selectedIds.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${_selectedIds.length} đã chọn',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          if (_vaultLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child:
                  Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_vaultItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Kho từ trống — tra từ ở tab Tra từ nhé',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                shrinkWrap: true,
                itemCount: _vaultItems.length,
                itemBuilder: (context, i) {
                  final item = _vaultItems[i];
                  final id = item.id ?? '';
                  final selected = _selectedIds.contains(id);
                  return InkWell(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedIds.remove(id);
                      } else {
                        _selectedIds.add(id);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.06)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary.withOpacity(0.4),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: selected
                                ? const Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.value,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontSize: 15)),
                                if (item.topics.isNotEmpty)
                                  Text(item.topics.join(' · '),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(item.type,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Passage result card ──────────────────────────────────────────────────────

class _PassageCard extends StatefulWidget {
  final GeneratedPassage passage;
  const _PassageCard({required this.passage});

  @override
  State<_PassageCard> createState() => _PassageCardState();
}

class _PassageCardState extends State<_PassageCard> {
  bool _showVietnamese = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.passage.topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            'Band ${widget.passage.targetBand.toStringAsFixed(1)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          if (widget.passage.usedLexicalItemIds.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.bookmark_rounded,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.passage.usedLexicalItemIds.length} từ',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // EN/VI toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LangToggle(
                        label: 'EN',
                        active: !_showVietnamese,
                        onTap: () => setState(() => _showVietnamese = false),
                      ),
                      _LangToggle(
                        label: 'VI',
                        active: _showVietnamese,
                        onTap: () => setState(() => _showVietnamese = true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                        begin: const Offset(0.02, 0), end: Offset.zero)
                    .animate(anim),
                child: child,
              ),
            ),
            child: Padding(
              key: ValueKey(_showVietnamese),
              padding: const EdgeInsets.all(20),
              child: Text(
                _showVietnamese
                    ? widget.passage.vietnameseTranslation
                    : widget.passage.englishContent,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.75,
                  color: AppColors.textPrimary,
                  fontStyle: _showVietnamese ? FontStyle.normal : FontStyle.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangToggle(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
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
  late final Animation<double> _fade;
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
    _fade = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dot;
    return FadeTransition(
      opacity: _fade,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            'Đang sinh bài$dots',
            style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
