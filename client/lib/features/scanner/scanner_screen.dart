import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '安全扫码区',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.zap, color: LumosColors.secondary),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(),
                ],
              ),
            ),
            
            // ── Viewfinder ──
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Fake camera view
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LumosColors.secondary.withValues(alpha: 0.8), width: 2),
                      color: Colors.white.withValues(alpha: 0.05),
                      boxShadow: [
                        BoxShadow(
                          color: LumosColors.secondary.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: -10,
                        )
                      ]
                    ),
                  ),
                  
                  // Scanning Line Animation
                  Positioned(
                    top: 100,
                    width: MediaQuery.of(context).size.width - 48,
                    height: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: LumosColors.secondary,
                        boxShadow: [
                          BoxShadow(color: LumosColors.secondary, blurRadius: 10, spreadRadius: 2)
                        ]
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: 0, end: 200, duration: 2500.ms, curve: Curves.easeInOut),
                  ),
                  
                  // Text overlay
                  Positioned(
                    bottom: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        '文档边缘将自动对齐并脱敏',
                        style: GoogleFonts.notoSansSc(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 200.ms).fadeIn(),
            ),

            // ── Controls ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControl(context, LucideIcons.image, '导入相册'),
                  
                  // Shutter Button
                  InkWell(
                    onTap: () {},
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: LumosColors.primary, width: 4),
                        color: theme.scaffoldBackgroundColor,
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: LumosColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: 300.ms).scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.easeOutBack),

                  _buildControl(context, LucideIcons.fileText, '云端抓取'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControl(BuildContext context, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.notoSansSc(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1);
  }
}
