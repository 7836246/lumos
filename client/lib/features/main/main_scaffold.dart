import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  void _onItemTapped(BuildContext context, int index) {
    if (index == 2) {
      context.push('/scanner');
      return;
    }
    
    // 映射 navigationShell index. 0 -> home, 1 -> report, 2 -> scanner (ignored above), 3 -> profile
    int shellIndex = index > 2 ? index - 1 : index;

    navigationShell.goBranch(
      shellIndex,
      initialLocation: shellIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Map shell index back to bottom bar index
    int shellIndex = navigationShell.currentIndex;
    int currentIndex = shellIndex >= 2 ? shellIndex + 1 : shellIndex;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: navigationShell,
      // 真正的 iOS 原生底栏，锚定底部，带极细顶部描边
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9F9),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.15),
              width: 0.5, // Retina 发丝边
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 49, // 标准 iOS TabBar 高度
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, currentIndex, CupertinoIcons.home, '首页', isDark),
                _buildNavItem(context, 1, currentIndex, CupertinoIcons.doc_text, '案卷', isDark),
                _buildCenterButton(context, isDark),
                _buildNavItem(context, 3, currentIndex, CupertinoIcons.person, '我的', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, int currentIndex, IconData icon, String label, bool isDark) {
    final isSelected = currentIndex == index;
    final activeColor = LumosColors.primary;
    final inactiveColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF999999);
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(context, index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.notoSansSc(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context, bool isDark) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(context, 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.barcode_viewfinder,
              size: 32, // Large central action
              color: LumosColors.primary,
            ),
            const SizedBox(height: 2),
            Text(
              '扫描',
              style: GoogleFonts.notoSansSc(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: LumosColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
