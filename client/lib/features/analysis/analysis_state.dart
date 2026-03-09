/// 合同分析状态管理.
///
/// 管理从提交合同到分析完成的全流程状态，
/// 通过 ChangeNotifier 驱动 UI 实时更新。
library;

import 'package:flutter/foundation.dart';

import '../../core/api/contract_service.dart';
import '../../core/api/models.dart';

/// 分析阶段
enum AnalysisPhase {
  idle,        // 空闲
  submitting,  // 提交中
  extracting,  // 结构化抽取中
  retrieving,  // 法规检索中
  reviewing,   // 风险审查中
  completed,   // 完成
  error,       // 出错
}

/// 合同分析状态
class AnalysisState extends ChangeNotifier {
  final ContractService _service = ContractService();

  // ── 状态 ──
  AnalysisPhase _phase = AnalysisPhase.idle;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _contractId;
  final List<RiskItem> _risks = [];
  AnalysisSummary? _summary;
  String? _errorMessage;

  // ── Getters ──
  AnalysisPhase get phase => _phase;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String? get contractId => _contractId;
  List<RiskItem> get risks => List.unmodifiable(_risks);
  AnalysisSummary? get summary => _summary;
  String? get errorMessage => _errorMessage;
  bool get isAnalyzing => _phase != AnalysisPhase.idle
      && _phase != AnalysisPhase.completed
      && _phase != AnalysisPhase.error;

  /// 提交合同并开始流式分析
  Future<void> analyzeContract(String text, {ContractSource source = ContractSource.textPaste}) async {
    // 重置状态
    _phase = AnalysisPhase.submitting;
    _progress = 0.0;
    _statusMessage = '正在提交合同…';
    _risks.clear();
    _summary = null;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. 提交合同
      final response = await _service.submitContract(text: text, source: source);
      _contractId = response.contractId;
      _statusMessage = response.message;
      notifyListeners();

      // 2. 订阅 SSE 流
      await for (final event in _service.streamAnalysis(response.contractId)) {
        _handleSSEEvent(event);
        notifyListeners();
      }
    } catch (e) {
      _phase = AnalysisPhase.error;
      _errorMessage = '分析失败: $e';
      _statusMessage = '发生错误';
      notifyListeners();
    }
  }

  /// 处理 SSE 事件
  void _handleSSEEvent(SSEParsedEvent event) {
    switch (event.type) {
      case SSEEventType.nodeStart:
        final nodeProgress = AgentNodeProgress.fromJson(event.data);
        _progress = nodeProgress.progress;
        _statusMessage = nodeProgress.description;
        _phase = _phaseFromNodeName(nodeProgress.nodeName);

      case SSEEventType.nodeComplete:
        final nodeProgress = AgentNodeProgress.fromJson(event.data);
        _progress = nodeProgress.progress;
        _statusMessage = nodeProgress.description;

      case SSEEventType.thinking:
        _statusMessage = event.data['message'] as String? ?? '思考中…';

      case SSEEventType.riskFound:
        final risk = RiskItem.fromJson(event.data);
        _risks.add(risk);

      case SSEEventType.summary:
        _summary = AnalysisSummary.fromJson(event.data);

      case SSEEventType.complete:
        _phase = AnalysisPhase.completed;
        _progress = 1.0;
        _statusMessage = event.data['message'] as String? ?? '分析完成';

      case SSEEventType.error:
        _phase = AnalysisPhase.error;
        _errorMessage = event.data['message'] as String? ?? '未知错误';
        _statusMessage = '分析出错';
    }
  }

  AnalysisPhase _phaseFromNodeName(String name) {
    return switch (name) {
      'extractor' => AnalysisPhase.extracting,
      'retriever' => AnalysisPhase.retrieving,
      'reviewer' => AnalysisPhase.reviewing,
      _ => _phase,
    };
  }

  /// 重置为初始状态
  void reset() {
    _phase = AnalysisPhase.idle;
    _progress = 0.0;
    _statusMessage = '';
    _contractId = null;
    _risks.clear();
    _summary = null;
    _errorMessage = null;
    notifyListeners();
  }
}
