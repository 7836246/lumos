import 'package:flutter/material.dart';

/// 装饰性渐变光晕球 — Ambient decorative gradient orb
/// 放在 Stack 中作为背景装饰元素
class GradientOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  final Alignment alignment;

  const GradientOrb({
    super.key,
    this.size = 200,
    required this.color,
    this.opacity = 0.15,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
