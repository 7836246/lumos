import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

///原生精致仪表盘 — Clean, precise iOS style circular gauge
class SecurityRing extends StatefulWidget {
  final double progress; // 0.0 ~ 1.0
  final String label;
  final String subLabel;
  final double size;

  const SecurityRing({
    super.key,
    required this.progress,
    this.label = '98',
    this.subLabel = '安全评分',
    this.size = 110, // 稍微缩小一点，增加留白
  });

  @override
  State<SecurityRing> createState() => _SecurityRingState();
}

class _SecurityRingState extends State<SecurityRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 背景环与进度环
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _NativeRingPainter(
                  progress: _progressAnimation.value,
                  bgColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  fgColor: LumosColors.primary,
                  strokeWidth: 8,
                ),
              ),
              // 中心文字 (纯白/纯黑，无渐变)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.notoSansSc(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subLabel,
                    style: GoogleFonts.notoSansSc(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NativeRingPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;
  final double strokeWidth;

  _NativeRingPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 标准背景圆环
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = bgColor
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 实心纯色前景色进度
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = fgColor
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _NativeRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
