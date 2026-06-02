import 'package:flutter/material.dart';
import '../models/lexical_item.dart';
import '../models/lookup_result.dart';
import '../services/lexical_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/topic_chip.dart';
import 'detail_screen.dart';

class LookupScreen extends StatefulWidget {
  final LexicalService service;
  const LookupScreen({super.key, required this.service});

  @override
  State<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends State<LookupScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  LookupResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final word = _controller.text.trim();
    if (word.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await widget.service.lookup(word);
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = 'Không tra được từ. Kiểm tra kết nối tới API.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final data = _result!.data;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          service: widget.service,
          item: data,
          isNew: true,
        ),
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu vào kho từ vựng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FadeSlideIn(
            child: Text(
              'Tra từ vựng',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              'Tìm nghĩa, ví dụ và lưu vào kho theo chủ đề',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: _SearchBar(
              controller: _controller,
              onSubmit: _lookup,
            ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          if (_error != null)
            FadeSlideIn(
              child: _MessageBox(text: _error!, isError: true),
            ),
          if (_result != null)
            FadeSlideIn(
              key: ValueKey(_result!.data.value),
              child: _ResultCard(result: _result!, onSave: _save),
            ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _SearchBar({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          const Icon(Icons.search_rounded, color: AppColors.primary),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: 'Nhập một từ tiếng Anh...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final LookupResult result;
  final VoidCallback onSave;
  const _ResultCard({required this.result, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final item = result.data;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                item.type,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: result.isFromVault
                      ? AppColors.positive.withOpacity(0.12)
                      : AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.isFromVault ? 'Đã có trong kho' : 'AI tạo mới',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: result.isFromVault
                        ? AppColors.positive
                        : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          if (item.topics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.topics
                  .map((t) => TopicChip(label: t, selected: false))
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          ...item.meanings.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConnotationTag(connotation: m.connotation),
                    const SizedBox(height: 6),
                    Text(
                      m.definition,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    ...m.examples.map((ex) => Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            '• $ex',
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        )),
                  ],
                ),
              )),
          if (item.synonyms.isNotEmpty)
            _WordRow(label: 'Đồng nghĩa', words: item.synonyms),
          if (item.antonyms.isNotEmpty)
            _WordRow(label: 'Trái nghĩa', words: item.antonyms),
          const SizedBox(height: 8),
          if (!result.isFromVault)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('Lưu vào kho từ vựng'),
              ),
            ),
        ],
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final String label;
  final List<String> words;
  const _WordRow({required this.label, required this.words});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: words
                .map((w) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(w,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String text;
  final bool isError;
  const _MessageBox({required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.negative : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: TextStyle(color: color, fontSize: 14))),
        ],
      ),
    );
  }
}
