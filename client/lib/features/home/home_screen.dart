import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/modern_card.dart';
import '../../shared/widgets/security_ring.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── 1. iOS Large Title Header ──
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
              title: Text(
                '上午好，主管',
                style: GoogleFonts.notoSansSc(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: 0.36,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  radius: 16,
                  child: Icon(
                    CupertinoIcons.person_fill,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ],
          ),

          // ── 2. Security Status (Inset Grouped) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: ModernCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SecurityRing(progress: 0.98),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusBadge(isDark),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildDataPoint(isDark, '127', '已扫描', LumosColors.primary),
                                  _buildDataPoint(isDark, '23', '风险项', LumosColors.red),
                                  _buildDataPoint(isDark, '18', '已修复', LumosColors.emerald),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildProgressBar(isDark, '合规率', 0.87, LumosColors.emerald)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildProgressBar(isDark, '范围', 0.72, LumosColors.primary)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildProgressBar(isDark, '时效', 0.95, LumosColors.secondary)),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      context, isDark,
                      icon: CupertinoIcons.camera_fill,
                      label: '拍照排查',
                      color: LumosColors.primary,
                      onTap: () => context.push('/scanner'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      context, isDark,
                      icon: CupertinoIcons.doc_text_fill,
                      label: '粘贴文本',
                      color: LumosColors.accent,
                      onTap: () => context.push('/text-input'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      context, isDark,
                      icon: CupertinoIcons.folder_badge_plus,
                      label: '导入文件',
                      color: LumosColors.emerald,
                      onTap: () {},
                    ),
                  ),
                ],
              ).animate(delay: 200.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── 4. Core Domains Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '核心风险领域',
                style: GoogleFonts.notoSansSc(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.38,
                  color: theme.colorScheme.onSurface,
                ),
              ).animate(delay: 300.ms).fadeIn(),
            ),
          ),

          // ── 5. Domains Grid ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildDomainCard(isDark, '薪资计算', '潜在扣除项', CupertinoIcons.money_dollar, LumosColors.primary, '12', 400),
                _buildDomainCard(isDark, '违约索赔', '隐性违约金', CupertinoIcons.exclamationmark_triangle_fill, LumosColors.red, '3', 500),
                _buildDomainCard(isDark, '保密竞业', '霸王条款', CupertinoIcons.doc_text_fill, LumosColors.gold, '8', 600),
                _buildDomainCard(isDark, '劳动保护', '工时与社保', CupertinoIcons.heart_fill, LumosColors.emerald, '5', 700),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: LumosColors.emerald.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '系统运行正常',
        style: GoogleFonts.notoSansSc(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF30D158) : LumosColors.emerald, // iOS specific green values depending on mode
        ),
      ),
    );
  }

  Widget _buildDataPoint(bool isDark, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.notoSansSc(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.notoSansSc(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDark ? LumosColors.textDarkTertiary : LumosColors.textLightTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark, String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansSc(
                fontSize: 11,
                color: isDark ? LumosColors.textDarkTertiary : LumosColors.textLightTertiary,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: GoogleFonts.notoSansSc(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, bool isDark, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // A clean solid button that looks native
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.notoSansSc(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainCard(bool isDark, String title, String subtitle, IconData icon, Color iconColor, String count, int delay) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count,
                  style: GoogleFonts.notoSansSc(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansSc(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.notoSansSc(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }
}
