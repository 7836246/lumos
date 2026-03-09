import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

///原生精致卡片 — Clean flat card with iOS 14+ widget border radius
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool hasShadow;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const ModernCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.hasShadow = true,
    this.onTap,
    this.color,
    this.borderRadius = LumosTheme.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = color ?? theme.colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        splashColor: theme.colorScheme.onSurface.withValues(alpha: 0.02),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: hasShadow
                ? (isDark ? LumosColors.cardShadowDark : LumosColors.cardShadowLight)
                : null,
            // 细线描边提升锐利度，但不可突兀
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
