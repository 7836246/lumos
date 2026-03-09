/// 合同分析进度页面.
///
/// 展示 AI Agent 实时分析过程：
/// - 节点执行进度 (极光动画)
/// - 逐条推送的风险条目
/// - 最终评分与总结
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/models.dart';
import 'analysis_state.dart';

class AnalysisScreen extends StatefulWidget {
  final String contractText;

  const AnalysisScreen({super.key, required this.contractText});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final AnalysisState _state = AnalysisState();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    // 自动开始分析
    _state.analyzeContract(widget.contractText);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.xmark, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _state.phase == AnalysisPhase.completed ? '排查报告' : '风险排查中…',
          style: GoogleFonts.notoSansSc(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: _state.phase == AnalysisPhase.error
          ? _buildErrorView(theme)
          : _state.phase == AnalysisPhase.completed
              ? _buildResultView(theme, isDark)
              : _buildProgressView(theme, isDark),
    );
  }

  /// 分析进度视图
  Widget _buildProgressView(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 进度环
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: _state.progress,
                      strokeWidth: 6,
                      backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    ),
                  ),
                  Text(
                    '${(_state.progress * 100).toInt()}%',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
              duration: 2000.ms,
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 40),
            Text(
              _state.statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSc(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            if (_state.risks.isNotEmpty)
              Text(
                '已发现 ${_state.risks.length} 项风险',
                style: GoogleFonts.notoSansSc(
                  fontSize: 14,
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 分析结果视图
  Widget _buildResultView(ThemeData theme, bool isDark) {
    final summary = _state.summary;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 评分卡片
        if (summary != null)
          SliverToBoxAdapter(
            child: _buildScoreCard(theme, isDark, summary),
          ),

        // 总结
        if (summary != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                summary.summary,
                style: GoogleFonts.notoSansSc(
                  fontSize: 15,
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ),

        // 风险条目列表
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              '风险详情',
              style: GoogleFonts.notoSansSc(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),

        if (_state.risks.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(CupertinoIcons.checkmark_shield, size: 48, color: const Color(0xFF22C55E)),
                  const SizedBox(height: 16),
                  Text(
                    '未发现明显风险，合同整体合规 👍',
                    style: GoogleFonts.notoSansSc(fontSize: 16, color: const Color(0xFF22C55E)),
                  ),
                ],
              ),
            ),
          ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildRiskCard(theme, isDark, _state.risks[index], index),
            childCount: _state.risks.length,
          ),
        ),

        // 底部安全距离
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  /// 评分卡片
  Widget _buildScoreCard(ThemeData theme, bool isDark, AnalysisSummary summary) {
    final scoreColor = Color(summary.overallLevel.colorValue);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: isDark ? 0.25 : 0.1),
            scoreColor.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // 评分数字
          Column(
            children: [
              Text(
                '${summary.overallScore}',
                style: GoogleFonts.notoSansSc(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                  height: 1,
                ),
              ),
              Text(
                '/100',
                style: GoogleFonts.notoSansSc(
                  fontSize: 16,
                  color: scoreColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // 描述
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    summary.overallLevel.label,
                    style: GoogleFonts.notoSansSc(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '共扫描 ${summary.totalClauses} 条条款',
                  style: GoogleFonts.notoSansSc(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                Text(
                  '发现 ${summary.totalRisks} 项风险',
                  style: GoogleFonts.notoSansSc(fontSize: 14, fontWeight: FontWeight.w600, color: scoreColor),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  /// 风险卡片
  Widget _buildRiskCard(ThemeData theme, bool isDark, RiskItem risk, int index) {
    final riskColor = Color(risk.level.colorValue);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: riskColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              risk.level.label.substring(0, 2),
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
        title: Text(
          risk.title,
          style: GoogleFonts.notoSansSc(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '评分 ${risk.score}/100',
          style: GoogleFonts.notoSansSc(fontSize: 12, color: riskColor),
        ),
        children: [
          if (risk.originalClause.isNotEmpty) ...[
            _buildSection('📜 原始条文', risk.originalClause, theme),
            const SizedBox(height: 12),
          ],
          _buildSection('💬 大白话解读', risk.explanation, theme),
          if (risk.legalBasis.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection('⚖️ 法律依据', risk.legalBasis, theme),
          ],
          if (risk.negotiationTip.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection('🗣️ 谈判话术', risk.negotiationTip, theme, highlight: true),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX(begin: 0.02);
  }

  Widget _buildSection(String title, String content, ThemeData theme, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansSc(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight
                ? theme.colorScheme.primary.withValues(alpha: 0.06)
                : theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            content,
            style: GoogleFonts.notoSansSc(
              fontSize: 14,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  /// 错误视图
  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, size: 64, color: Color(0xFFEF4444)),
            const SizedBox(height: 24),
            Text(
              '分析失败',
              style: GoogleFonts.notoSansSc(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444)),
            ),
            const SizedBox(height: 8),
            Text(
              _state.errorMessage ?? '未知错误',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSc(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: () => _state.analyzeContract(widget.contractText),
              child: Text('重试', style: GoogleFonts.notoSansSc(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
