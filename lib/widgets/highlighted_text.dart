import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Hiển thị [text] với 2 lớp tô màu chồng nhau:
///  - [highlights] (cụm/từ vocab) → tô màu xanh primary, in đậm.
///  - [userHighlights] (set lowercase) → tô NỀN VÀNG (do user tự highlight).
///
/// Nếu [tapAllWords] = true: mọi từ đều tap được → gọi [onTapWord].
class HighlightedText extends StatefulWidget {
  final String text;
  final List<String> highlights;
  final TextStyle? style;
  final void Function(String word)? onTapWord;
  final bool tapAllWords;
  final Set<String>? userHighlights;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlights,
    this.style,
    this.onTapWord,
    this.tapAllWords = false,
    this.userHighlights,
  });

  @override
  State<HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<HighlightedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  static const _userHighlightBg = Color(0xFFFFE680); // vàng nổi bật, dịu mắt

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer? _makeRecognizer(String word) {
    if (widget.onTapWord == null) return null;
    final r = TapGestureRecognizer()..onTap = () => widget.onTapWord!(word);
    _recognizers.add(r);
    return r;
  }

  bool _isUserHighlighted(String word) =>
      widget.userHighlights?.contains(word.toLowerCase()) ?? false;

  /// Đoạn văn thường: nếu tapAllWords thì tách từng từ, mỗi từ tap được.
  /// Áp dụng nền vàng cho từ trong userHighlights.
  void _addPlainSegment(List<InlineSpan> spans, String segment, TextStyle base) {
    if (!widget.tapAllWords || widget.onTapWord == null) {
      // Vẫn cần tách để check user highlights ngay cả khi không cho tap.
      _addSegmentWithUserHighlights(spans, segment, base);
      return;
    }
    final wordRegex = RegExp(r"[A-Za-z][A-Za-z'\-]*");
    var last = 0;
    for (final m in wordRegex.allMatches(segment)) {
      if (m.start > last) {
        _addSegmentWithUserHighlights(
            spans, segment.substring(last, m.start), base);
      }
      final word = m.group(0)!;
      final hl = _isUserHighlighted(word);
      spans.add(TextSpan(
        text: word,
        style: hl ? base.copyWith(backgroundColor: _userHighlightBg) : base,
        recognizer: _makeRecognizer(word),
      ));
      last = m.end;
    }
    if (last < segment.length) {
      _addSegmentWithUserHighlights(spans, segment.substring(last), base);
    }
  }

  /// Trường hợp không tap: vẫn quét word-by-word để tô vàng từ đã highlight.
  void _addSegmentWithUserHighlights(
      List<InlineSpan> spans, String segment, TextStyle base) {
    final hls = widget.userHighlights;
    if (hls == null || hls.isEmpty) {
      spans.add(TextSpan(text: segment, style: base));
      return;
    }
    final wordRegex = RegExp(r"[A-Za-z][A-Za-z'\-]*");
    var last = 0;
    for (final m in wordRegex.allMatches(segment)) {
      final word = m.group(0)!;
      if (!hls.contains(word.toLowerCase())) continue;
      if (m.start > last) {
        spans.add(TextSpan(text: segment.substring(last, m.start), style: base));
      }
      spans.add(TextSpan(
        text: word,
        style: base.copyWith(backgroundColor: _userHighlightBg),
      ));
      last = m.end;
    }
    if (last < segment.length) {
      spans.add(TextSpan(text: segment.substring(last), style: base));
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final base = widget.style ??
        const TextStyle(
            fontSize: 15, height: 1.75, color: AppColors.textPrimary);

    final terms = widget.highlights
        .where((w) => w.trim().isNotEmpty)
        .map((w) => w.trim())
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length)); // cụm dài ưu tiên

    final spans = <InlineSpan>[];

    if (terms.isEmpty) {
      _addPlainSegment(spans, widget.text, base);
      return Text.rich(TextSpan(children: spans));
    }

    final pattern = terms.map(RegExp.escape).join('|');
    final regex = RegExp('\\b($pattern)\\b', caseSensitive: false);

    var last = 0;
    for (final m in regex.allMatches(widget.text)) {
      if (m.start > last) {
        _addPlainSegment(spans, widget.text.substring(last, m.start), base);
      }
      final word = m.group(0)!;
      final hl = _isUserHighlighted(word);
      spans.add(TextSpan(
        text: word,
        recognizer: _makeRecognizer(word),
        style: base.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          // Ưu tiên màu vàng user highlight nếu có, không thì màu primary nhạt
          backgroundColor: hl
              ? _userHighlightBg
              : AppColors.primary.withValues(alpha: 0.12),
        ),
      ));
      last = m.end;
    }
    if (last < widget.text.length) {
      _addPlainSegment(spans, widget.text.substring(last), base);
    }

    return Text.rich(TextSpan(children: spans));
  }
}
