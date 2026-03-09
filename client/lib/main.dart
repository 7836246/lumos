import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 沉浸式状态栏：透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // 让系统自己根据明暗主题去决定状态栏的图标黑白
    ),
  );

  runApp(const LumosApp());
}

/// Lumos · 契光鉴微 — 应用根组件 (优雅极简)
class LumosApp extends StatelessWidget {
  const LumosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lumos · 契光鉴微',
      debugShowCheckedModeBanner: false,

      // 精心打磨的主题：极简留白、沉浸优雅
      theme: LumosTheme.lightTheme,
      darkTheme: LumosTheme.darkTheme,
      // 跟随系统主题，完美适配 Light / Dark
      themeMode: ThemeMode.system,

      // 模块化路由
      routerConfig: appRouter,
    );
  }
}
