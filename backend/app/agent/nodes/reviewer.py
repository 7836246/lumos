"""
Node C: 风险审查节点.

综合结构化条款和检索到的法规，对合同进行逐项风险评估、
整体打分，并生成可直接发送给 HR 的谈判话术。
"""

from __future__ import annotations

from loguru import logger

from app.agent.state import AgentState, RiskAssessment
from app.models.analysis import RiskLevel

# ── 风险审查系统提示词 ─────────────────────────────────────────

REVIEWER_SYSTEM_PROMPT = """\
你是一位站在劳动者立场的合同风险审查专家。你需要综合合同条款和相关法律条文，对每一条可能存在风险的条款进行评估。

## 评估维度:
1. **风险等级**: high(高危) / medium(警惕) / low(关注) / safe(合规)
2. **大白话解读**: 用普通人能听懂的语言解释这条条款意味着什么
3. **法律依据**: 引用具体的法律条文说明为什么这是风险
4. **谈判话术**: 提供一段可以直接复制、通过微信发送给 HR 的建议话术

## 评分标准:
- 0-30: 严重违法，极度危险
- 31-50: 存在重大风险，需要谈判
- 51-70: 有一定风险，建议关注
- 71-85: 基本合规，但有改进空间
- 86-100: 完全合规

## 输出要求:
对每条风险条款输出 JSON 对象，包含:
- category, level, title, original_clause, explanation, legal_basis, negotiation_tip, score

语言风格要亲切、平易近人，像一位热心的前辈在帮你看合同。
"""


async def review_risks(state: AgentState) -> AgentState:
    """
    Node C: 风险审查节点.

    对提取的条款进行逐项风险评估，生成评分和谈判话术。
    当前为骨架实现，后续接入 LLM 进行深度分析。
    """
    logger.info(f"🔍 [Node C] 开始风险审查 | 合同ID: {state.contract_id}")
    state.current_node = "reviewer"

    try:
        assessments: list[RiskAssessment] = []

        # ── TODO: 接入 LLM 进行真正的风险审查推理 ──
        # 将 extracted_clauses + legal_references 组合为上下文，让大模型进行深度分析
        # 当前为占位逻辑

        for clause in state.extracted_clauses:
            if clause.category is not None:
                # 查找关联的法规
                related_laws = [
                    ref
                    for ref in state.legal_references
                    if clause.category
                    and clause.category.value
                    in BUILTIN_CATEGORY_HINTS.get(clause.category.value, [])
                ]
                legal_basis = (
                    "; ".join(f"{r.law_name} {r.article}" for r in related_laws)
                    if related_laws
                    else "待 AI 分析后补充法律依据"
                )

                assessments.append(
                    RiskAssessment(
                        category=clause.category,
                        level=RiskLevel.MEDIUM,
                        title=f"⚠️ {clause.title} — 需要关注",
                        original_clause=clause.content[:200],
                        explanation="此条款涉及员工权益，建议仔细审阅。（LLM 接入后将提供详细大白话解读）",
                        legal_basis=legal_basis,
                        negotiation_tip="建议与 HR 沟通此条款的具体执行方式。（LLM 接入后将生成专业话术）",
                        score=60,
                    )
                )

        # 计算整体评分
        if assessments:
            total = sum(a.score for a in assessments)
            state.overall_score = total // len(assessments)
        else:
            state.overall_score = 85  # 没检出风险，打个较高但不满的分

        # 确定整体等级
        if state.overall_score <= 30:
            state.overall_level = RiskLevel.HIGH
        elif state.overall_score <= 60:
            state.overall_level = RiskLevel.MEDIUM
        elif state.overall_score <= 85:
            state.overall_level = RiskLevel.LOW
        else:
            state.overall_level = RiskLevel.SAFE

        # 生成一句话总结
        risk_count = len(assessments)
        high_count = sum(1 for a in assessments if a.level == RiskLevel.HIGH)
        state.summary = (
            f"共扫描到 {len(state.extracted_clauses)} 条条款, "
            f"发现 {risk_count} 项风险点"
            + (f" (其中 {high_count} 项高危)" if high_count > 0 else "")
            + f", 整体安全评分 {state.overall_score}/100。"
        )

        # 按风险等级排序 (高危在前)
        level_order = {
            RiskLevel.HIGH: 0,
            RiskLevel.MEDIUM: 1,
            RiskLevel.LOW: 2,
            RiskLevel.SAFE: 3,
        }
        assessments.sort(key=lambda a: (level_order.get(a.level, 99), a.score))
        state.risk_assessments = assessments

        logger.info(
            f"✅ [Node C] 风险审查完成 | 评分: {state.overall_score}/100 | "
            f"风险: {risk_count} 项"
        )

    except Exception as e:
        error_msg = f"[Node C] 风险审查失败: {e}"
        logger.error(error_msg)
        state.errors.append(error_msg)

    return state


# 分类关联表 (用于初版的简单匹配)
BUILTIN_CATEGORY_HINTS: dict[str, list[str]] = {
    "non_compete": ["non_compete"],
    "probation_salary": ["probation_salary"],
    "probation_insurance": ["probation_insurance"],
    "salary_deduction": ["salary_deduction"],
    "resignation": ["resignation"],
    "training_bond": ["training_bond"],
}
