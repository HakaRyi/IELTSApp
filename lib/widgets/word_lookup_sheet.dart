import 'package:flutter/material.dart';
import '../models/lookup_result.dart';
import '../screens/detail_screen.dart';
import '../services/lexical_service.dart';
import '../theme/app_theme.dart';
import 'bouncy.dart';
import 'intensity_meter.dart';
import 'topic_chip.dart';

/// Mở bottom sheet tra nhanh [word] (gọi từ bài đọc khi tap vào một từ).
Future<void> showWordLookupSheet(BuildContext context, String word) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WordLookupSheet(word: word),
  );
}

class _WordLookupSheet extends StatefulWidget {
  final String word;
  const _WordLookupSheet({required this.word});

  @override
  State<_WordLookupSheet> createState() => _WordLookupSheetState();
}

class _WordLookupSheetState extends State<_WordLookupSheet> {
  final _service = LexicalService();
  LookupResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    try {
      final res = await _service.lookup(widget.word);
      if (mounted) setState(() => _result = res);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tra được từ này 😢');
    }
  }

  Future<void> _save() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          service: _service,
          item: _result!.data,
          isNew: true,
        ),
      ),
    );
    if (created == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            if (_result == null && _error == null) ...[
              const SizedBox(height: 24),
              const Center(child: PulsingEmoji('🔍', size: 40)),
              const SizedBox(height: 12),
              Center(
                child: Text('Đang tra "${widget.word}"...',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ),
              const SizedBox(height: 24),
            ] else if (_error != null) ...[
              const SizedBox(height: 16),
              const Center(child: WigglingEmoji('😢', size: 44)),
              const SizedBox(height: 10),
              Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.negative))),
              const SizedBox(height: 16),
            ] else ...[
              _buildResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final item = r.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: r.isFromVault
                    ? AppColors.positive.withValues(alpha: 0.12)
                    : AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.isFromVault ? '🔖 Trong kho' : '✨ AI tạo',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        r.isFromVault ? AppColors.positive : AppColors.accent),
              ),
            ),
          ],
        ),
        Text(item.type,
            style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary)),
        if (item.topics.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.topics
                .map((t) => TopicChip(label: t, selected: false))
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        ...item.meanings.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConnotationTag(connotation: m.connotation),
                  const SizedBox(height: 5),
                  Text(m.definition,
                      style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: AppColors.textPrimary)),
                  IntensityMeter(
                      intensity: m.intensity, note: m.intensityNote),
                  ...m.examples.take(1).map((ex) => Padding(
                        padding: const EdgeInsets.only(top: 5, left: 4),
                        child: Text('• $ex',
                            style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary)),
                      )),
                ],
              ),
            )),
        const SizedBox(height: 8),
        if (!r.isFromVault)
          Bouncy(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_add_rounded,
                      color: Colors.white, size: 19),
                  SizedBox(width: 8),
                  Text('Lưu vào kho từ vựng',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
