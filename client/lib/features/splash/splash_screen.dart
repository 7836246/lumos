import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    // 短暂留白，保持原生启动页的高级克制感
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 极致极简的原生品牌标识
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: LumosColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                CupertinoIcons.shield_lefthalf_fill,
                size: 56,
                color: Colors.white,
              ),
            ).animate().scale(
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ).fadeIn(duration: 400.ms),
            
            const SizedBox(height: 24),
            
            Text(
              '契光鉴微',
              style: GoogleFonts.notoSansSc(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: theme.colorScheme.onSurface,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            
            const SizedBox(height: 8),
            
            Text(
              'LUMOS',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
