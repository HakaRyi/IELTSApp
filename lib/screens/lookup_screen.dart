import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lookup_result.dart';
import '../models/suggest_item.dart';
import '../services/lexical_service.dart';
import '../services/word_dictionary.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/intensity_meter.dart';
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
  final _focusNode = FocusNode();
  bool _loading = false;
  String? _error;
  LookupResult? _result;

  // Suggestions
  List<_SuggestEntry> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WordDictionary.instance.ensureLoaded(); // preload asset
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      // 1. Local dictionary (tức thì)
      final localWords = WordDictionary.instance.search(text, limit: 8);

      // 2. Vault (async)
      List<SuggestItem> vaultItems = [];
      try {
        vaultItems = await widget.service.suggest(text, limit: 8);
      } catch (_) {}

      if (!mounted || !_focusNode.hasFocus) return;

      // Merge: vault words first (fromVault=true), then local-only words
      final vaultValues = vaultItems.map((v) => v.value.toLowerCase()).toSet();
      final merged = [
        ...vaultItems.map((v) => _SuggestEntry(
              word: v.value,
              type: v.type,
              fromVault: true,
            )),
        ...localWords
            .where((w) => !vaultValues.contains(w.toLowerCase()))
            .take(8 - vaultItems.length)
            .map((w) => _SuggestEntry(word: w, type: '', fromVault: false)),
      ];

      setState(() {
        _suggestions = merged.take(8).toList();
        _showSuggestions = merged.isNotEmpty;
      });
    });
  }

  Future<void> _lookup([String? word]) async {
    final w = (word ?? _controller.text).trim();
    if (w.isEmpty) return;
    if (word != null) _controller.text = word;
    _focusNode.unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _showSuggestions = false;
    });
    try {
      final res = await widget.service.lookup(w);
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = 'Không tra được từ. Kiểm tra kết nối tới API.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          service: widget.service,
          item: _result!.data,
          isNew: true,
        ),
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu vào kho từ vựng'),
          behavior: SnackBarBehavior.floating,
        ),
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
            child: Text('Tra từ vựng',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 4),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text('Tra từ hoặc cụm từ — nghĩa, sắc thái, ví dụ',
                style:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: _SearchBarWithSuggestions(
              controller: _controller,
              focusNode: _focusNode,
              suggestions: _suggestions,
              showSuggestions: _showSuggestions,
              onSubmit: _lookup,
              onSuggestionTap: (s) => _lookup(s.word),
            ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
            ),
          if (_error != null)
            FadeSlideIn(child: _MessageBox(text: _error!, isError: true)),
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

// ─── Data model for merged suggestions ───────────────────────────────────────

class _SuggestEntry {
  final String word;
  final String type;   // empty for local-only words
  final bool fromVault;
  const _SuggestEntry(
      {required this.word, required this.type, required this.fromVault});
}

// ─── Search bar with suggestions overlay ─────────────────────────────────────

class _SearchBarWithSuggestions extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<_SuggestEntry> suggestions;
  final bool showSuggestions;
  final void Function([String?]) onSubmit;
  final void Function(_SuggestEntry) onSuggestionTap;

  const _SearchBarWithSuggestions({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.showSuggestions,
    required this.onSubmit,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
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
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSubmit(),
                  decoration: const InputDecoration(
                    hintText: 'Nhập từ hoặc cụm từ (vd: obsessed with)...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: ElevatedButton(
                  onPressed: () => onSubmit(),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child:
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Suggestions dropdown
        if (showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: suggestions.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  return InkWell(
                    onTap: () => onSuggestionTap(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: item.fromVault
                            ? AppColors.primary.withValues(alpha: 0.03)
                            : Colors.transparent,
                        border: idx < suggestions.length - 1
                            ? const Border(
                                bottom: BorderSide(
                                    color: Color(0xFFEEF2FF), width: 1))
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Vault = bookmark, Local = search icon
                          Icon(
                            item.fromVault
                                ? Icons.bookmark_rounded
                                : Icons.search_rounded,
                            size: 16,
                            color: item.fromVault
                                ? AppColors.positive
                                : AppColors.primaryLight,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item.word,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary)),
                          ),
                          if (item.fromVault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.positive.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Kho từ',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.positive,
                                      fontWeight: FontWeight.w600)),
                            )
                          else if (item.type.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
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
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Result card (unchanged logic, same as before) ────────────────────────────

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
            color: AppColors.primary.withValues(alpha: 0.10),
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
              Text(item.value,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 10),
              Text(item.type,
                  style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: result.isFromVault
                      ? AppColors.positive.withValues(alpha: 0.12)
                      : AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.isFromVault ? 'Đã có trong kho' : 'AI tạo mới',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: result.isFromVault
                          ? AppColors.positive
                          : AppColors.accent),
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
                    Text(m.definition,
                        style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppColors.textPrimary)),
                    IntensityMeter(
                        intensity: m.intensity, note: m.intensityNote),
                    ...m.examples.map((ex) => Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text('• $ex',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                  height: 1.4)),
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
                              fontSize: 13,
                              color: AppColors.textPrimary)),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: color),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(text, style: TextStyle(color: color, fontSize: 14))),
        ],
      ),
    );
  }
}
