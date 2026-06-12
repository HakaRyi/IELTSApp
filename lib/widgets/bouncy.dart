import 'package:flutter/material.dart';

/// Bọc widget với hiệu ứng "nhún" khi nhấn (co nhẹ rồi bật lại) — cảm giác dễ thương.
class Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Bouncy({super.key, required this.child, this.onTap});

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.93),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Emoji "thở" — phóng to thu nhỏ nhẹ nhàng lặp vô hạn.
class PulsingEmoji extends StatefulWidget {
  final String emoji;
  final double size;
  const PulsingEmoji(this.emoji, {super.key, this.size = 28});

  @override
  State<PulsingEmoji> createState() => _PulsingEmojiState();
}

class _PulsingEmojiState extends State<PulsingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween(begin: 1.0, end: 1.15)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: Text(widget.emoji, style: TextStyle(fontSize: widget.size)),
      );
}

/// Emoji "vẫy" — lắc lư qua lại, dùng cho empty state.
class WigglingEmoji extends StatefulWidget {
  final String emoji;
  final double size;
  const WigglingEmoji(this.emoji, {super.key, this.size = 56});

  @override
  State<WigglingEmoji> createState() => _WigglingEmojiState();
}

class _WigglingEmojiState extends State<WigglingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _angle = Tween(begin: -0.08, end: 0.08)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _angle,
        builder: (_, child) =>
            Transform.rotate(angle: _angle.value, child: child),
        child: Text(widget.emoji, style: TextStyle(fontSize: widget.size)),
      );
}
