"""
风险分析结果数据模型.

存储 Agent 对合同条款的逐项风险评估与整体评分。
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from enum import Enum

from sqlmodel import Field, Relationship, SQLModel


class RiskLevel(str, Enum):
    """风险等级."""

    HIGH = "high"  # 🔴 高危
    MEDIUM = "medium"  # 🟡 警惕
    LOW = "low"  # 🟢 关注
    SAFE = "safe"  # ✅ 合规


class RiskCategory(str, Enum):
    """十大坑点分类."""

    NON_COMPETE = "non_compete"  # 竞业禁止
    PROBATION_SALARY = "probation_salary"  # 试用期薪资
    PROBATION_INSURANCE = "probation_insurance"  # 试用期社保
    SALARY_DEDUCTION = "salary_deduction"  # 扣薪条款
    JOB_DESCRIPTION = "job_description"  # 岗位职责模糊
    OBEDIENCE_CLAUSE = "obedience_clause"  # 服从安排条款
    RESIGNATION = "resignation"  # 离职审批
    LEAVE_RIGHTS = "leave_rights"  # 休假权益
    JURISDICTION = "jurisdiction"  # 管辖地争议
    TRAINING_BOND = "training_bond"  # 培训服务期


class AnalysisResult(SQLModel, table=True):
    """风险分析结果总表."""

    __tablename__ = "analysis_results"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        description="分析结果唯一标识",
    )

    # ---- 关联 ----
    contract_id: str = Field(foreign_key="contracts.id", description="关联合同 ID")

    # ---- 整体评分 ----
    overall_score: int = Field(
        default=0,
        ge=0,
        le=100,
        description="合同安全总评分 (0=极度危险, 100=完全合规)",
    )
    overall_level: RiskLevel = Field(
        default=RiskLevel.MEDIUM,
        description="整体风险等级",
    )
    summary: str = Field(default="", description="一句话总结")

    # ---- 时间 ----
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        description="分析完成时间",
    )


class RiskItem(SQLModel, table=True):
    """单项风险条目."""

    __tablename__ = "risk_items"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
    )

    # ---- 关联 ----
    analysis_id: str = Field(
        foreign_key="analysis_results.id",
        description="关联分析结果 ID",
    )

    # ---- 风险详情 ----
    category: RiskCategory = Field(description="坑点分类")
    level: RiskLevel = Field(description="风险等级")
    title: str = Field(description="风险标题 (说人话)")
    original_clause: str = Field(default="", description="原始合同条文")
    explanation: str = Field(default="", description="大白话解读")
    legal_basis: str = Field(default="", description="法律依据")
    negotiation_tip: str = Field(default="", description="谈判话术建议")
    score: int = Field(default=0, ge=0, le=100, description="单项评分")

    # ---- 排序 ----
    order: int = Field(default=0, description="展示排序 (高危在前)")
