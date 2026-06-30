import 'package:flutter/material.dart';
import '../models/generated_passage.dart';
import '../theme/app_theme.dart';
import 'bouncy.dart';
import 'fade_slide_in.dart';
import 'highlighted_text.dart';

/// Hiển thị câu hỏi của bài đọc theo dạng. User trả lời → nhấn Nộp bài → hiện đáp án + giải thích.
/// Hỗ trợ user-highlight + tap-to-lookup trên question text + options
/// (dùng chung [userHighlights] với _PassageCard).
class PassageQuestions extends StatefulWidget {
  final GeneratedPassage passage;
  final Set<String>? userHighlights;
  final void Function(String word)? onWordTap;

  const PassageQuestions({
    super.key,
    required this.passage,
    this.userHighlights,
    this.onWordTap,
  });

  @override
  State<PassageQuestions> createState() => _PassageQuestionsState();
}

class _PassageQuestionsState extends State<PassageQuestions> {
  /// number → câu trả lời user nhập/chọn (chuẩn hoá uppercase + trim khi so).
  final Map<int, String> _answers = {};
  final Map<int, TextEditingController> _textCtrls = {};
  bool _submitted = false;

  GeneratedPassage get p => widget.passage;
  bool get _isText =>
      p.questionType == PassageQuestionType.shortAnswer ||
      p.questionType == PassageQuestionType.tableCompletion;

  @override
  void initState() {
    super.initState();
    if (_isText) {
      for (final q in p.questions) {
        _textCtrls[q.number] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// So đáp án (case-insensitive, bỏ space đầu/cuối).
  bool _isCorrect(PassageQuestion q) {
    final user = (_answers[q.number] ?? '').trim().toLowerCase();
    if (user.isEmpty) return false;
    return user == q.correctAnswer.trim().toLowerCase();
  }

  int get _score => p.questions.where(_isCorrect).length;

  void _submit() {
    // Đồng bộ text controllers (MCQ/T-F-NG đã sync trực tiếp qua _answers)
    if (_isText) {
      for (final entry in _textCtrls.entries) {
        _answers[entry.key] = entry.value.text;
      }
    }
    setState(() => _submitted = true);
  }

  void _retry() {
    setState(() {
      _submitted = false;
      _answers.clear();
      for (final c in _textCtrls.values) {
        c.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (p.questions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(PassageQuestionType.label(p.questionType),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      if (p.instructions.isNotEmpty)
                        Text(p.instructions,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11.5)),
                    ],
                  ),
                ),
                if (_submitted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$_score / ${p.questions.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bảng (chỉ với Table Completion)
                if (p.questionType == PassageQuestionType.tableCompletion &&
                    p.table != null) ...[
                  _TableView(table: p.table!),
                  const SizedBox(height: 14),
                ],

                // Danh sách câu hỏi
                for (var i = 0; i < p.questions.length; i++) ...[
                  FadeSlideIn(
                    delay: Duration(milliseconds: 40 * i),
                    child: _buildQuestion(p.questions[i]),
                  ),
                  if (i < p.questions.length - 1) const SizedBox(height: 14),
                ],

                const SizedBox(height: 16),

                // Nút Nộp bài / Làm lại
                SizedBox(
                  width: double.infinity,
                  child: _submitted
                      ? OutlinedButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Làm lại'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Nộp bài'),
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mỗi câu hỏi ─────────────────────────────────────────────────────────

  Widget _buildQuestion(PassageQuestion q) {
    final correct = _isCorrect(q);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Số + đề câu hỏi
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _submitted
                    ? (correct ? AppColors.positive : AppColors.negative)
                        .withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${q.number}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _submitted
                          ? (correct
                              ? AppColors.positive
                              : AppColors.negative)
                          : AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HighlightedText(
                text: q.question,
                highlights: const [],
                tapAllWords: widget.onWordTap != null,
                onTapWord: widget.onWordTap,
                userHighlights: widget.userHighlights,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: _buildInput(q),
        ),

        // Sau khi nộp: hiện đáp án + giải thích
        if (_submitted) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 36),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (correct ? AppColors.positive : AppColors.negative)
                  .withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: (correct ? AppColors.positive : AppColors.negative)
                      .withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                        correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 16,
                        color: correct
                            ? AppColors.positive
                            : AppColors.negative),
                    const SizedBox(width: 5),
                    Text('Đáp án: ${q.correctAnswer}',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: correct
                                ? AppColors.positive
                                : AppColors.negative)),
                  ],
                ),
                if (q.explanation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(q.explanation,
                      style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textPrimary)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Input thay đổi theo dạng câu hỏi.
  Widget _buildInput(PassageQuestion q) {
    switch (p.questionType) {
      case PassageQuestionType.trueFalseNotGiven:
        return _buildOptionChips(q, ['TRUE', 'FALSE', 'NOT GIVEN']);
      case PassageQuestionType.yesNoNotGiven:
        return _buildOptionChips(q, ['YES', 'NO', 'NOT GIVEN']);
      case PassageQuestionType.shortAnswer:
      case PassageQuestionType.tableCompletion:
        return _buildTextField(q);
      case PassageQuestionType.matchingHeadings:
      case PassageQuestionType.multipleChoice:
      default:
        return _buildOptions(q);
    }
  }

  /// Lựa chọn dạng A/B/C/D hoặc i/ii/iii — danh sách dọc clickable.
  Widget _buildOptions(PassageQuestion q) {
    if (q.options.isEmpty) return _buildTextField(q);
    return Column(
      children: q.options.map((opt) {
        // Trích key đầu (vd "B. ..." → "B", "iii. ..." → "iii")
        final dotIdx = opt.indexOf('.');
        final key = dotIdx > 0 ? opt.substring(0, dotIdx).trim() : opt.trim();
        final selected = _answers[q.number] == key;
        final isAnswer =
            _submitted && key.toLowerCase() == q.correctAnswer.trim().toLowerCase();
        final isWrong = _submitted && selected && !isAnswer;

        Color border;
        Color bg;
        if (_submitted && isAnswer) {
          border = AppColors.positive;
          bg = AppColors.positive.withValues(alpha: 0.08);
        } else if (isWrong) {
          border = AppColors.negative;
          bg = AppColors.negative.withValues(alpha: 0.08);
        } else if (selected) {
          border = AppColors.primary;
          bg = AppColors.primary.withValues(alpha: 0.08);
        } else {
          border = AppColors.primary.withValues(alpha: 0.15);
          bg = Colors.white;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: _submitted
                ? null
                : () => setState(() => _answers[q.number] = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border, width: 1.2),
              ),
              // HighlightedText cho phép tap riêng từng từ để highlight/tra từ
              // mà KHÔNG chặn tap toàn option (vì onTapWord chỉ gắn vào span từng từ).
              child: HighlightedText(
                text: opt,
                highlights: const [],
                tapAllWords: widget.onWordTap != null,
                onTapWord: widget.onWordTap,
                userHighlights: widget.userHighlights,
                style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                    height: 1.4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Chip TRUE/FALSE/NOT GIVEN nằm ngang.
  Widget _buildOptionChips(PassageQuestion q, List<String> opts) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: opts.map((opt) {
        final selected = _answers[q.number] == opt;
        final isAnswer =
            _submitted && opt.toLowerCase() == q.correctAnswer.trim().toLowerCase();
        final isWrong = _submitted && selected && !isAnswer;

        Color color;
        if (_submitted && isAnswer) {
          color = AppColors.positive;
        } else if (isWrong) {
          color = AppColors.negative;
        } else if (selected) {
          color = AppColors.primary;
        } else {
          color = AppColors.textSecondary;
        }

        return Bouncy(
          onTap: _submitted
              ? null
              : () => setState(() => _answers[q.number] = opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: (selected || (_submitted && isAnswer))
                  ? color.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(opt,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        );
      }).toList(),
    );
  }

  /// Ô nhập text (short answer / table fill).
  Widget _buildTextField(PassageQuestion q) {
    return TextField(
      controller: _textCtrls[q.number],
      enabled: !_submitted,
      decoration: InputDecoration(
        hintText: 'Nhập đáp án...',
        isDense: true,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
      onChanged: (v) => _answers[q.number] = v,
    );
  }
}

// ─── Bảng cho Table Completion ───────────────────────────────────────────────

class _TableView extends StatelessWidget {
  final PassageTable table;
  const _TableView({required this.table});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.08)),
        border: TableBorder.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8)),
        columnSpacing: 18,
        headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: AppColors.primary),
        dataTextStyle: const TextStyle(
            fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
        columns: table.headers
            .map((h) => DataColumn(label: Text(h)))
            .toList(),
        rows: table.rows
            .map((row) => DataRow(
                  cells: row
                      .map((cell) => DataCell(
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 200),
                              child: Text(cell,
                                  style: TextStyle(
                                      fontStyle: cell.contains('___')
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      color: cell.contains('___')
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: cell.contains('___')
                                          ? FontWeight.w700
                                          : FontWeight.normal)),
                            ),
                          ))
                      .toList(),
                ))
            .toList(),
      ),
    );
  }
}
