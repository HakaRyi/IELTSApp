import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Nền với các "bong bóng" xanh trôi nổi liên tục, tạo cảm giác sống động.
/// Đặt làm lớp dưới cùng trong Stack.
class FloatingBackground extends StatefulWidget {
  const FloatingBackground({super.key});

  @override
  State<FloatingBackground> createState() => _FloatingBackgroundState();
}

class _FloatingBackgroundState extends State<FloatingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  final List<_Blob> _blobs = [
    _Blob(0.12, 0.10, 180, AppColors.primaryLight, 0.18, 1.0),
    _Blob(0.82, 0.22, 140, AppColors.accent, 0.16, 1.4),
    _Blob(0.20, 0.78, 220, AppColors.primary, 0.12, 0.8),
    _Blob(0.78, 0.82, 120, AppColors.primaryLight, 0.20, 1.7),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          children: _blobs.map((b) {
            final dx = math.sin(t * b.speed) * 24;
            final dy = math.cos(t * b.speed) * 28;
            return Positioned(
              left: size.width * b.x + dx - b.size / 2,
              top: size.height * b.y + dy - b.size / 2,
              child: _SoftCircle(size: b.size, color: b.color, opacity: b.opacity),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _SoftCircle(
      {required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}

class _Blob {
  final double x; // vị trí tương đối 0..1
  final double y;
  final double size;
  final Color color;
  final double opacity;
  final double speed;
  _Blob(this.x, this.y, this.size, this.color, this.opacity, this.speed);
}
