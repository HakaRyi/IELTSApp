import 'package:flutter/material.dart';
import '../models/lexical_item.dart';
import '../services/lexical_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/intensity_meter.dart';
import '../widgets/topic_chip.dart';

class DetailScreen extends StatefulWidget {
  final LexicalService service;
  final LexicalItem item;
  final bool isNew;

  const DetailScreen({
    super.key,
    required this.service,
    required this.item,
    required this.isNew,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _reviewService = ReviewService();

  late List<String> _topics;
  late TextEditingController _notesController;
  final _newTopicController = TextEditingController();

  bool _saving = false;
  bool _enrolling = false;
  bool _enrolled = false;
  String? _savedItemId; // id sau khi lưu (dùng cho enroll)

  @override
  void initState() {
    super.initState();
    _topics = List<String>.from(widget.item.topics);
    _notesController = TextEditingController(text: widget.item.personalNotes);
    _savedItemId = widget.item.id; // null nếu isNew
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newTopicController.dispose();
    super.dispose();
  }

  void _addTopic() {
    final t = _newTopicController.text.trim();
    if (t.isNotEmpty && !_topics.contains(t)) {
      setState(() => _topics.add(t));
      _newTopicController.clear();
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.item.copyWith(
        topics: _topics,
        personalNotes: _notesController.text.trim(),
      );
      if (widget.isNew) {
        final created = await widget.service.create(updated);
        setState(() => _savedItemId = created.id);
      } else {
        await widget.service.update(widget.item.id!, updated);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Lưu (nếu chưa lưu) rồi enroll vào Review
  Future<void> _enroll() async {
    setState(() => _enrolling = true);
    try {
      // 1. Nếu từ chưa được lưu vào vault thì lưu trước
      if (_savedItemId == null) {
        final updated = widget.item.copyWith(
          topics: _topics,
          personalNotes: _notesController.text.trim(),
        );
        final created = await widget.service.create(updated);
        setState(() => _savedItemId = created.id);
      }

      // 2. Lấy definition + example từ meanings
      final item = widget.item;
      final definition = item.meanings.isNotEmpty
          ? item.meanings.first.definition
          : item.value;
      final example = item.meanings.isNotEmpty &&
              item.meanings.first.examples.isNotEmpty
          ? item.meanings.first.examples.first
          : '';

      // 3. Gọi enroll (idempotent — gọi lại vẫn OK)
      await _reviewService.enroll(
        lexicalItemId: _savedItemId!,
        word: item.value,
        type: item.type,
        definition: definition,
        example: example,
        topics: _topics,
      );

      setState(() => _enrolled = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('"${item.value}" đã thêm vào danh sách ôn tập'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        // Nếu là từ mới, pop với true để vault refresh
        if (widget.isNew) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa từ này?'),
        content: Text('"${widget.item.value}" sẽ bị xóa khỏi kho.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa',
                  style: TextStyle(color: AppColors.negative))),
        ],
      ),
    );
    if (confirm == true) {
      await widget.service.delete(widget.item.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Lưu từ mới' : 'Chi tiết'),
        actions: [
          if (!widget.isNew)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.negative),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          // Word + type header
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Hero(
                tag: 'word-${item.id ?? item.value}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item.type,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              // Enrolled badge
              if (_enrolled)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Đang ôn',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Topics
          const _SectionLabel('Chủ đề'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topics
                .map((t) => InputChip(
                      label: Text(t),
                      onDeleted: () => setState(() => _topics.remove(t)),
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.10),
                      deleteIconColor: AppColors.primary,
                      labelStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newTopicController,
                  decoration: InputDecoration(
                    hintText: 'Thêm chủ đề...',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addTopic(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addTopic,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Meanings
          const _SectionLabel('Nghĩa'),
          const SizedBox(height: 10),
          ...item.meanings.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConnotationTag(connotation: m.connotation),
                    const SizedBox(height: 8),
                    Text(m.definition,
                        style:
                            const TextStyle(fontSize: 15, height: 1.5)),
                    IntensityMeter(
                        intensity: m.intensity, note: m.intensityNote),
                    ...m.examples.map((ex) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('• $ex',
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              )),
                        )),
                  ],
                ),
              )),

          if (item.synonyms.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _SectionLabel('Đồng nghĩa'),
            const SizedBox(height: 8),
            _Tags(words: item.synonyms),
          ],
          if (item.antonyms.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionLabel('Trái nghĩa'),
            const SizedBox(height: 8),
            _Tags(words: item.antonyms),
          ],
          const SizedBox(height: 24),

          // Personal notes
          const _SectionLabel('Ghi chú cá nhân'),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Mẹo ghi nhớ, ngữ cảnh hay dùng...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),

      // Bottom sheet — 2 buttons
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
              top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.08))),
        ),
        child: Row(
          children: [
            // Save button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_saving || _enrolling) ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(widget.isNew ? 'Lưu vào kho' : 'Cập nhật'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Enroll button
            Expanded(
              child: _enrolled
                  ? _EnrolledBadge()
                  : ElevatedButton.icon(
                      onPressed: (_saving || _enrolling) ? null : _enroll,
                      icon: _enrolling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.psychology_rounded, size: 18),
                      label: Text(
                          widget.isNew ? 'Lưu & Ôn tập' : 'Thêm vào ôn tập'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shadowColor:
                            const Color(0xFF7C3AED).withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Enrolled badge (replaces button after enrolled) ─────────────────────────

class _EnrolledBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.positive.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.positive.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.positive),
          SizedBox(width: 6),
          Text('Đã thêm',
              style: TextStyle(
                  color: AppColors.positive,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _Tags extends StatelessWidget {
  final List<String> words;
  const _Tags({required this.words});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: words
          .map((w) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(w, style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
    );
  }
}
