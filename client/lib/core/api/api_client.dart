/// Lumos API 客户端配置.
///
/// 集中管理后端 API 地址和 Dio 实例。
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API 基础配置
class ApiConfig {
  /// 后端 API 地址
  /// 开发环境使用本机地址; 生产环境替换为实际服务器地址
  /// Android 模拟器用 10.0.2.2 访问宿主机
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// API 版本前缀
  static const String apiPrefix = '/api/v1';

  /// 完整的 API 基础 URL
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// 连接超时 (毫秒)
  static const int connectTimeout = 10000;

  /// 接收超时 (毫秒)
  static const int receiveTimeout = 60000;

  /// SSE 流超时 (毫秒) — 合同分析可能需要较长时间
  static const int streamTimeout = 120000;
}

/// 全局 Dio 单例
final Dio apiClient = _createDio();

Dio _createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // 请求/响应日志 (开发环境)
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('🌐 $obj'),
    ),
  );

  return dio;
}

/// 创建用于 SSE 流的 Dio 实例 (不同超时配置)
Dio createStreamDio() {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConfig.streamTimeout),
      responseType: ResponseType.stream,
      headers: {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      },
    ),
  );
}
