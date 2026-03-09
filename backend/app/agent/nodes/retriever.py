"""
Node B: 法规检索节点 (RAG).

根据提取的条款关键信息，在劳动法向量数据库中检索相关法条，
为后续的风险审查提供法律依据支撑。
"""

from __future__ import annotations

from loguru import logger

from app.agent.state import AgentState, LegalReference

# ── 中国劳动法核心条文 (内置知识库, 后续替换为向量检索) ─────────

BUILTIN_LEGAL_KNOWLEDGE: dict[str, list[LegalReference]] = {
    "non_compete": [
        LegalReference(
            law_name="《劳动合同法》",
            article="第二十三条",
            content="用人单位与劳动者可以在劳动合同中约定保守用人单位的商业秘密和与知识产权相关的保密事项。对负有保密义务的劳动者，用人单位可以在劳动合同或者保密协议中与劳动者约定竞业限制条款，并约定在解除或者终止劳动合同后，在竞业限制期限内按月给予劳动者经济补偿。",
            relevance_score=0.95,
        ),
        LegalReference(
            law_name="《劳动合同法》",
            article="第二十四条",
            content="竞业限制的人员限于用人单位的高级管理人员、高级技术人员和其他负有保密义务的人员。竞业限制的范围、地域、期限由用人单位与劳动者约定，竞业限制的约定不得违反法律、法规的规定。在解除或者终止劳动合同后，前款规定的人员到与本单位生产或者经营同类产品、从事同类业务的有竞争关系的其他用人单位，或者自己开业生产或者经营同类产品、从事同类业务的竞业限制期限，不得超过二年。",
            relevance_score=0.93,
        ),
    ],
    "probation_salary": [
        LegalReference(
            law_name="《劳动合同法》",
            article="第二十条",
            content="劳动者在试用期的工资不得低于本单位相同岗位最低档工资或者劳动合同约定工资的百分之八十，并不得低于用人单位所在地的最低工资标准。",
            relevance_score=0.96,
        ),
    ],
    "probation_insurance": [
        LegalReference(
            law_name="《社会保险法》",
            article="第五十八条",
            content="用人单位应当自用工之日起三十日内为其职工向社会保险经办机构申请办理社会保险登记。试用期包含在劳动合同期限内，用人单位必须为试用期员工缴纳社会保险。",
            relevance_score=0.94,
        ),
    ],
    "salary_deduction": [
        LegalReference(
            law_name="《劳动法》",
            article="第五十条",
            content="工资应当以货币形式按月支付给劳动者本人。不得克扣或者无故拖欠劳动者的工资。",
            relevance_score=0.92,
        ),
    ],
    "resignation": [
        LegalReference(
            law_name="《劳动合同法》",
            article="第三十七条",
            content="劳动者提前三十日以书面形式通知用人单位，可以解除劳动合同。劳动者在试用期内提前三日通知用人单位，可以解除劳动合同。",
            relevance_score=0.95,
        ),
    ],
    "training_bond": [
        LegalReference(
            law_name="《劳动合同法》",
            article="第二十二条",
            content="用人单位为劳动者提供专项培训费用，对其进行专业技术培训的，可以与该劳动者订立协议，约定服务期。劳动者违反服务期约定的，应当按照约定向用人单位支付违约金。违约金的数额不得超过用人单位提供的培训费用。",
            relevance_score=0.94,
        ),
    ],
}


async def retrieve_legal_references(state: AgentState) -> AgentState:
    """
    Node B: 法规检索节点.

    根据已提取条款中涉及的风险类别，检索相关法律条文。
    当前使用内置知识库，后续接入向量数据库实现真正的 RAG。
    """
    logger.info(f"⚖️ [Node B] 开始法规检索 | 合同ID: {state.contract_id}")
    state.current_node = "retriever"

    try:
        references: list[LegalReference] = []
        searched_categories: set[str] = set()

        # ── TODO: 接入向量数据库 (如 ChromaDB / Qdrant) 进行真正的 RAG ──
        # 当前从内置知识库按分类直接匹配

        for clause in state.extracted_clauses:
            if clause.category and clause.category.value not in searched_categories:
                category_key = clause.category.value
                searched_categories.add(category_key)

                if category_key in BUILTIN_LEGAL_KNOWLEDGE:
                    refs = BUILTIN_LEGAL_KNOWLEDGE[category_key]
                    references.extend(refs)
                    logger.debug(
                        f"  📖 分类 [{category_key}] 命中 {len(refs)} 条法规"
                    )

        # 如果没有任何分类命中，提供通用法规参考
        if not references:
            logger.info("  📖 未命中特定分类, 加载通用劳动法参考")
            for category_refs in BUILTIN_LEGAL_KNOWLEDGE.values():
                references.extend(category_refs)

        # 去重
        seen = set()
        unique_refs = []
        for ref in references:
            key = (ref.law_name, ref.article)
            if key not in seen:
                seen.add(key)
                unique_refs.append(ref)

        state.legal_references = unique_refs

        logger.info(f"✅ [Node B] 法规检索完成 | 共检索到 {len(unique_refs)} 条法条")

    except Exception as e:
        error_msg = f"[Node B] 法规检索失败: {e}"
        logger.error(error_msg)
        state.errors.append(error_msg)

    return state
