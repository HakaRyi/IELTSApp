import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Thước sắc thái 1-5: 🔥 đầy theo độ mạnh + ghi chú so sánh với từ gần nghĩa.
/// Ẩn hoàn toàn nếu intensity <= 0 (dữ liệu cũ chưa có).
class IntensityMeter extends StatelessWidget {
  final int intensity;
  final String note;
  const IntensityMeter({super.key, required this.intensity, this.note = ''});

  Color get _color {
    if (intensity >= 5) return const Color(0xFFDC2626); // đỏ — cực mạnh
    if (intensity >= 4) return const Color(0xFFEA580C); // cam
    if (intensity >= 3) return const Color(0xFFCA8A04); // vàng
    return const Color(0xFF16A34A); // xanh — nhẹ nhàng
  }

  String get _label {
    switch (intensity) {
      case 1: return 'Rất nhẹ';
      case 2: return 'Nhẹ';
      case 3: return 'Trung bình';
      case 4: return 'Mạnh';
      default: return 'Cực mạnh';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Sắc thái',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              // 5 ngọn lửa, sáng theo intensity — mỗi cái hiện trễ một nhịp
              ...List.generate(5, (i) {
                final lit = i < intensity;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 250 + i * 120),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Opacity(
                      opacity: lit ? 1 : 0.18,
                      child: const Text('🔥', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(_label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _color)),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note,
                style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
