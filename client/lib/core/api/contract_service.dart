/// 合同分析 API 服务.
///
/// 封装与后端 /contracts 相关的所有网络请求，
/// 包括提交合同、订阅 SSE 流式分析、获取报告。
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'models.dart';

/// SSE 解析后的事件
class SSEParsedEvent {
  final SSEEventType type;
  final Map<String, dynamic> data;

  const SSEParsedEvent({required this.type, required this.data});
}

/// 合同分析服务
class ContractService {
  final Dio _dio = apiClient;

  /// 提交合同进行 AI 风险排查
  ///
  /// 返回 [ContractSubmitResponse]，包含合同 ID 和 SSE 流地址。
  Future<ContractSubmitResponse> submitContract({
    required String text,
    ContractSource source = ContractSource.textPaste,
    int? pageCount,
  }) async {
    final request = ContractSubmitRequest(
      text: text,
      source: source,
      pageCount: pageCount,
    );

    final response = await _dio.post(
      '/contracts',
      data: request.toJson(),
    );

    return ContractSubmitResponse.fromJson(response.data);
  }

  /// 订阅 SSE 流式分析事件
  ///
  /// 返回一个 [Stream<SSEParsedEvent>]，实时推送 Agent 的思考进度和风险发现。
  /// 调用方应 listen 此 stream 并根据事件类型更新 UI。
  Stream<SSEParsedEvent> streamAnalysis(String contractId) async* {
    final streamDio = createStreamDio();

    try {
      final response = await streamDio.get<ResponseBody>(
        '${ApiConfig.apiPrefix}/contracts/$contractId/stream',
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      // SSE 协议解析
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);

        // SSE 以两个换行符分隔事件
        while (buffer.contains('\n\n')) {
          final index = buffer.indexOf('\n\n');
          final rawEvent = buffer.substring(0, index);
          buffer = buffer.substring(index + 2);

          final parsed = _parseSSE(rawEvent);
          if (parsed != null) {
            yield parsed;
          }
        }
      }
    } catch (e) {
      yield SSEParsedEvent(
        type: SSEEventType.error,
        data: {'message': '连接服务器失败: $e'},
      );
    }
  }

  /// 获取合同当前状态
  Future<ContractStatus> getContractStatus(String contractId) async {
    final response = await _dio.get('/contracts/$contractId');
    return ContractStatus.fromString(response.data['status'] as String);
  }

  /// 解析单条 SSE 事件
  SSEParsedEvent? _parseSSE(String raw) {
    String? eventType;
    String? dataStr;

    for (final line in raw.split('\n')) {
      if (line.startsWith('event: ')) {
        eventType = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        dataStr = line.substring(6).trim();
      }
    }

    if (eventType == null || dataStr == null) return null;

    try {
      final data = json.decode(dataStr) as Map<String, dynamic>;
      return SSEParsedEvent(
        type: SSEEventType.fromString(eventType),
        data: data,
      );
    } catch (_) {
      return null;
    }
  }
}
