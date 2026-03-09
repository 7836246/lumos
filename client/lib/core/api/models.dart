/// 合同分析 API 数据模型.
///
/// 与后端 Pydantic Schema 一一对应的 Dart 数据类。
library;

/// 合同来源类型
enum ContractSource {
  cameraOcr('camera_ocr'),
  pdfUpload('pdf_upload'),
  wordUpload('word_upload'),
  textPaste('text_paste');

  const ContractSource(this.value);
  final String value;
}

/// 合同处理状态
enum ContractStatus {
  pending('pending'),
  analyzing('analyzing'),
  completed('completed'),
  failed('failed');

  const ContractStatus(this.value);
  final String value;

  static ContractStatus fromString(String value) {
    return ContractStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ContractStatus.pending,
    );
  }
}

/// 风险等级
enum RiskLevel {
  high('high', '🔴 高危', 0xFFEF4444),
  medium('medium', '🟡 警惕', 0xFFF59E0B),
  low('low', '🟢 关注', 0xFF22C55E),
  safe('safe', '✅ 合规', 0xFF3B82F6);

  const RiskLevel(this.value, this.label, this.colorValue);
  final String value;
  final String label;
  final int colorValue;

  static RiskLevel fromString(String value) {
    return RiskLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RiskLevel.medium,
    );
  }
}

/// 提交合同请求体
class ContractSubmitRequest {
  final String text;
  final ContractSource source;
  final int? pageCount;
  final String? deviceId;

  const ContractSubmitRequest({
    required this.text,
    this.source = ContractSource.textPaste,
    this.pageCount,
    this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'source': source.value,
    if (pageCount != null) 'page_count': pageCount,
    if (deviceId != null) 'device_id': deviceId,
  };
}

/// 提交合同响应
class ContractSubmitResponse {
  final String contractId;
  final ContractStatus status;
  final String message;
  final String streamUrl;

  const ContractSubmitResponse({
    required this.contractId,
    required this.status,
    required this.message,
    required this.streamUrl,
  });

  factory ContractSubmitResponse.fromJson(Map<String, dynamic> json) {
    return ContractSubmitResponse(
      contractId: json['contract_id'] as String,
      status: ContractStatus.fromString(json['status'] as String),
      message: json['message'] as String,
      streamUrl: json['stream_url'] as String,
    );
  }
}

/// SSE 事件类型
enum SSEEventType {
  thinking,
  nodeStart,
  nodeComplete,
  riskFound,
  summary,
  complete,
  error;

  static SSEEventType fromString(String value) {
    return switch (value) {
      'thinking' => SSEEventType.thinking,
      'node_start' => SSEEventType.nodeStart,
      'node_complete' => SSEEventType.nodeComplete,
      'risk_found' => SSEEventType.riskFound,
      'summary' => SSEEventType.summary,
      'complete' => SSEEventType.complete,
      'error' => SSEEventType.error,
      _ => SSEEventType.thinking,
    };
  }
}

/// 单项风险评估
class RiskItem {
  final String category;
  final RiskLevel level;
  final String title;
  final String originalClause;
  final String explanation;
  final String legalBasis;
  final String negotiationTip;
  final int score;

  const RiskItem({
    required this.category,
    required this.level,
    required this.title,
    this.originalClause = '',
    required this.explanation,
    this.legalBasis = '',
    this.negotiationTip = '',
    required this.score,
  });

  factory RiskItem.fromJson(Map<String, dynamic> json) {
    return RiskItem(
      category: json['category'] as String? ?? '',
      level: RiskLevel.fromString(json['level'] as String? ?? 'medium'),
      title: json['title'] as String? ?? '',
      originalClause: json['original_clause'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      legalBasis: json['legal_basis'] as String? ?? '',
      negotiationTip: json['negotiation_tip'] as String? ?? '',
      score: json['score'] as int? ?? 50,
    );
  }
}

/// 分析总结
class AnalysisSummary {
  final int overallScore;
  final RiskLevel overallLevel;
  final String summary;
  final int totalClauses;
  final int totalRisks;

  const AnalysisSummary({
    required this.overallScore,
    required this.overallLevel,
    required this.summary,
    required this.totalClauses,
    required this.totalRisks,
  });

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      overallScore: json['overall_score'] as int? ?? 0,
      overallLevel: RiskLevel.fromString(json['overall_level'] as String? ?? 'medium'),
      summary: json['summary'] as String? ?? '',
      totalClauses: json['total_clauses'] as int? ?? 0,
      totalRisks: json['total_risks'] as int? ?? 0,
    );
  }
}

/// Agent 节点进度
class AgentNodeProgress {
  final String nodeName;
  final String description;
  final double progress;

  const AgentNodeProgress({
    required this.nodeName,
    required this.description,
    required this.progress,
  });

  factory AgentNodeProgress.fromJson(Map<String, dynamic> json) {
    return AgentNodeProgress(
      nodeName: json['node_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
