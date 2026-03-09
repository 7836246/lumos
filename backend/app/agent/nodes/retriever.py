"""
Node B: 法规检索节点.

对每一条结构化条款，通过 RAG 向量语义检索
查找最相关的劳动法条文，为后续风险审查提供法律依据。
"""

from __future__ import annotations

from loguru import logger

from app.agent.state import AgentState, LegalReference
from app.rag.vector_store import search_laws


async def retrieve_legal_references(state: AgentState) -> AgentState:
    """
    Node B: 法规检索节点.

    对每条合同条款进行语义检索，找到最相关的法律条文。
    """
    logger.info(f"⚖️ [Node B] 开始法规检索 | 合同ID: {state.contract_id}")
    state.current_node = "retriever"

    all_refs: list[LegalReference] = []
    seen_articles: set[str] = set()  # 去重

    try:
        for clause in state.extracted_clauses:
            # 构建查询: 条款标题 + 核心内容
            query = f"{clause.title} {clause.content[:200]}"

            # 语义检索 (如果有分类则优先按分类过滤)
            category = clause.category.value if clause.category else None
            results = search_laws(
                query=query,
                n_results=3,
                category=category,
            )

            # 如果按分类没找到足够结果，再做一次无过滤检索
            if len(results) < 2 and category:
                fallback = search_laws(query=query, n_results=3)
                for r in fallback:
                    if r["article"] not in seen_articles:
                        results.append(r)

            for match in results:
                article_key = f"{match['law_name']}_{match['article']}"
                if article_key in seen_articles:
                    continue
                seen_articles.add(article_key)

                ref = LegalReference(
                    law_name=match["law_name"],
                    article=match["article"],
                    content=match["content"],
                    relevance_score=match["similarity"],
                )
                all_refs.append(ref)

        # 按相关度排序
        all_refs.sort(key=lambda r: r.relevance_score, reverse=True)
        state.legal_references = all_refs

        logger.info(
            f"✅ [Node B] 法规检索完成 | 找到 {len(all_refs)} 条相关法条"
        )

    except Exception as e:
        error_msg = f"[Node B] 法规检索失败: {e}"
        logger.error(error_msg)
        state.errors.append(error_msg)

        # 降级: 使用空引用列表, 不阻断流程
        logger.info("  ⬇️ 降级: 跳过法规检索，继续后续节点")
        state.legal_references = []

    return state
