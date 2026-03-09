"""
Agent 状态定义.

定义 LangGraph 流转过程中的统一状态结构，
每个节点读取并更新此状态，形成完整的思考链路。
"""

from __future__ import annotations

from typing import Annotated

from pydantic import BaseModel, Field

from app.models.analysis import RiskCategory, RiskLevel


# ─── 结构化合同条款 ────────────────────────────────────────────


class ExtractedClause(BaseModel):
    """经 AI 结构化提取后的单条合同条款."""

    clause_index: int = Field(description="条款序号")
    title: str = Field(description="条款标题 (如: 竞业限制)")
    content: str = Field(description="条款原文内容")
    category: RiskCategory | None = Field(
        default=None,
        description="关联的风险分类 (可能为空)",
    )


# ─── 法规检索结果 ──────────────────────────────────────────────


class LegalReference(BaseModel):
    """RAG 检索到的法律条文."""

    law_name: str = Field(description="法律名称 (如: 《劳动合同法》)")
    article: str = Field(description="条款编号 (如: 第二十三条)")
    content: str = Field(description="法条原文")
    relevance_score: float = Field(ge=0, le=1, description="相关性评分")


# ─── 风险评估结果 ──────────────────────────────────────────────


class RiskAssessment(BaseModel):
    """单项风险评估."""

    category: RiskCategory
    level: RiskLevel
    title: str = Field(description="风险标题 (说人话)")
    original_clause: str = Field(description="原始合同条文")
    explanation: str = Field(description="大白话解读")
    legal_basis: str = Field(description="法律依据")
    negotiation_tip: str = Field(description="谈判话术建议")
    score: int = Field(ge=0, le=100, description="单项评分 (100=安全)")


# ─── LangGraph 全局状态 ────────────────────────────────────────


class AgentState(BaseModel):
    """
    LangGraph 工作流的全局状态.

    每个 Node 读取需要的字段，处理后更新对应字段，
    状态就像流水线上的「工单」，沿着 Graph 逐步被充实完整。
    """

    # ── 输入 ──
    contract_id: str = Field(description="合同 ID")
    raw_text: str = Field(description="脱敏后的合同原文")

    # ── Node A: 结构化提取 ──
    corrected_text: str = Field(default="", description="纠错后的文本")
    extracted_clauses: list[ExtractedClause] = Field(
        default_factory=list,
        description="结构化提取的条款列表",
    )

    # ── Node B: 法规检索 (RAG) ──
    legal_references: list[LegalReference] = Field(
        default_factory=list,
        description="检索到的相关法条",
    )

    # ── Node C: 风险审查 ──
    risk_assessments: list[RiskAssessment] = Field(
        default_factory=list,
        description="逐项风险评估结果",
    )
    overall_score: int = Field(default=0, ge=0, le=100, description="整体评分")
    overall_level: RiskLevel = Field(
        default=RiskLevel.MEDIUM,
        description="整体风险等级",
    )
    summary: str = Field(default="", description="一句话总结")

    # ── 流程控制 ──
    current_node: str = Field(default="", description="当前执行的节点名称")
    errors: list[str] = Field(default_factory=list, description="错误信息收集")
