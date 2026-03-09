import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // 原生 Large Title 头部
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
              title: Text(
                '案卷中心',
                style: GoogleFonts.notoSansSc(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: 0.36,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.search),
                onPressed: () {},
                color: theme.colorScheme.primary,
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.slider_horizontal_3),
                onPressed: () {},
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── 分段控制器 (原生 Segemented Control 风格) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildSegmentedControl(isDark),
            ),
          ),

          // ── 空状态 (简洁) ──
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.doc_text_search,
                  size: 64,
                  color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFC7C7CC),
                ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  '暂无案卷记录',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.38,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击下方按钮进行首次合规排查',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 15,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 32),
                CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  onPressed: () => context.push('/scanner'),
                  child: Text(
                    '新建合规扫描',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }

  // 模拟 iOS 原生的 UISegmentedControl
  Widget _buildSegmentedControl(bool isDark) {
    final tabs = ['全部', '进行中', '已归档'];
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? const Color(0xFF3A3A3C) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected && !isDark ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ] : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansSc(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
