import 'package:flutter/material.dart';
import '../models/lexical_item.dart';
import '../services/lexical_service.dart';
import '../theme/app_theme.dart';
import '../widgets/topic_chip.dart';

class DetailScreen extends StatefulWidget {
  final LexicalService service;
  final LexicalItem item;
  final bool isNew; // true: đang lưu từ mới tra; false: xem từ trong kho

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
  late List<String> _topics;
  late TextEditingController _notesController;
  final _newTopicController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _topics = List<String>.from(widget.item.topics);
    _notesController = TextEditingController(text: widget.item.personalNotes);
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
        await widget.service.create(updated);
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
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
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Chủ đề'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._topics.map((t) => InputChip(
                    label: Text(t),
                    onDeleted: () => setState(() => _topics.remove(t)),
                    backgroundColor: AppColors.primary.withOpacity(0.10),
                    deleteIconColor: AppColors.primary,
                    labelStyle: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600),
                  )),
            ],
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
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                      color: AppColors.primary.withOpacity(0.06),
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
                        style: const TextStyle(fontSize: 15, height: 1.5)),
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
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        color: AppColors.background,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(widget.isNew ? 'Lưu vào kho' : 'Cập nhật'),
          ),
        ),
      ),
    );
  }
}

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.06),
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
