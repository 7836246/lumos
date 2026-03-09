/// 合同文本输入页面.
///
/// 让用户粘贴合同文本进行快速分析 (MVP 核心路径)。
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class TextInputScreen extends StatefulWidget {
  const TextInputScreen({super.key});

  @override
  State<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final _controller = TextEditingController();
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _charCount = _controller.text.length);
    });
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
    final isValid = _charCount >= 50; // 最少 50 字

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '粘贴合同文本',
          style: GoogleFonts.notoSansSc(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          // 提示
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.shield_lefthalf_fill, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '合同文本仅在本次分析中使用，分析完成后可随时删除记录',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.05),

          // 文本输入
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: GoogleFonts.notoSansSc(
                  fontSize: 15,
                  height: 1.8,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '将劳动合同全文粘贴到这里…\n\n'
                      '支持直接从 Word、PDF 复制的文本，\n'
                      'Lumos 会自动进行格式纠错和条款提取。',
                  hintStyle: GoogleFonts.notoSansSc(
                    fontSize: 15,
                    height: 1.8,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // 底部: 字数 + 提交按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  // 字数统计
                  Text(
                    '$_charCount 字',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 14,
                      color: isValid
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  if (!isValid && _charCount > 0)
                    Text(
                      '  (最少 50 字)',
                      style: GoogleFonts.notoSansSc(
                        fontSize: 12,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  const Spacer(),
                  // 提交按钮
                  CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    onPressed: isValid
                        ? () => context.push('/analysis', extra: _controller.text)
                        : null,
                    child: Text(
                      '开始排查 🔍',
                      style: GoogleFonts.notoSansSc(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
