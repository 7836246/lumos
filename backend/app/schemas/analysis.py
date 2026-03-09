"""
风险分析结果相关 Schema.

定义 SSE 流式推送事件与最终分析报告的数据结构。
"""

from __future__ import annotations

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field

from app.models.analysis import RiskCategory, RiskLevel


# ─── SSE 事件类型 ──────────────────────────────────────────────


class SSEEventType(str, Enum):
    """SSE 流式推送事件类型."""

    # Agent 思考进度
    THINKING = "thinking"  # Agent 正在思考中 (附带当前步骤描述)
    NODE_START = "node_start"  # 某个 Node 开始执行
    NODE_COMPLETE = "node_complete"  # 某个 Node 执行完毕

    # 风险结果 (逐条推送)
    RISK_FOUND = "risk_found"  # 发现一条风险

    # 最终结果
    SUMMARY = "summary"  # 分析总结
    COMPLETE = "complete"  # 全部完成
    ERROR = "error"  # 发生错误


class SSEEvent(BaseModel):
    """SSE 事件基础结构."""

    event: SSEEventType
    data: dict = Field(default_factory=dict)


# ─── 风险条目 ──────────────────────────────────────────────────


class RiskItemResponse(BaseModel):
    """单项风险条目响应."""

    category: RiskCategory
    level: RiskLevel
    title: str = Field(description="风险标题 (说人话)")
    original_clause: str = Field(default="", description="原始合同条文")
    explanation: str = Field(description="大白话解读")
    legal_basis: str = Field(default="", description="法律依据")
    negotiation_tip: str = Field(default="", description="谈判话术建议")
    score: int = Field(ge=0, le=100, description="单项评分")

    model_config = {"from_attributes": True}


# ─── 完整报告 ──────────────────────────────────────────────────


class AnalysisReportResponse(BaseModel):
    """完整风险分析报告响应."""

    contract_id: str
    overall_score: int = Field(ge=0, le=100, description="合同安全总评分")
    overall_level: RiskLevel
    summary: str = Field(description="一句话总结")
    risk_items: list[RiskItemResponse] = Field(
        default_factory=list,
        description="逐条风险清单 (按危险程度排序)",
    )
    analyzed_at: datetime

    model_config = {"from_attributes": True}


# ─── Agent 节点进度 ────────────────────────────────────────────


class AgentNodeProgress(BaseModel):
    """Agent 节点执行进度."""

    node_name: str = Field(description="当前执行节点名称")
    description: str = Field(description="节点功能描述")
    progress: float = Field(ge=0, le=1, description="进度百分比 (0~1)")
