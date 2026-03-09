"""
LangGraph 合同审查工作流.

编排三个核心节点形成完整的 AI Agent 思考链：
  extract_clauses → retrieve_legal_refs → review_risks

每个节点的执行和产出会通过回调函数实时通知调用方，
以支持 SSE 流式推送给前端。分析完成后自动持久化结果到数据库。
"""

from __future__ import annotations

from collections.abc import AsyncGenerator, Callable

from loguru import logger
from sqlalchemy.ext.asyncio import AsyncSession

from app.agent.nodes.extractor import extract_clauses
from app.agent.nodes.retriever import retrieve_legal_references
from app.agent.nodes.reviewer import review_risks
from app.agent.state import AgentState
from app.models.analysis import AnalysisResult, RiskItem, RiskLevel
from app.schemas.analysis import AgentNodeProgress, SSEEvent, SSEEventType


async def _persist_results(state: AgentState, session: AsyncSession) -> None:
    """将 Agent 分析结果持久化到数据库."""
    try:
        # 创建分析结果主记录
        analysis = AnalysisResult(
            contract_id=state.contract_id,
            overall_score=state.overall_score,
            overall_level=state.overall_level,
            summary=state.summary,
        )
        session.add(analysis)
        await session.flush()  # 获取 analysis.id

        # 创建风险条目
        for idx, assessment in enumerate(state.risk_assessments):
            risk_item = RiskItem(
                analysis_id=analysis.id,
                category=assessment.category,
                level=assessment.level,
                title=assessment.title,
                original_clause=assessment.original_clause,
                explanation=assessment.explanation,
                legal_basis=assessment.legal_basis,
                negotiation_tip=assessment.negotiation_tip,
                score=assessment.score,
                order=idx,
            )
            session.add(risk_item)

        await session.commit()
        logger.info(
            f"💾 分析结果已持久化 | 合同ID: {state.contract_id} | "
            f"风险条目: {len(state.risk_assessments)} 条"
        )
    except Exception as e:
        logger.error(f"💾 持久化失败: {e}")
        await session.rollback()


async def run_contract_analysis(
    contract_id: str,
    raw_text: str,
    session: AsyncSession | None = None,
) -> AsyncGenerator[SSEEvent, None]:
    """
    执行合同分析工作流, 异步生成 SSE 事件流.

    Args:
        contract_id: 合同 ID
        raw_text: 脱敏后的合同文本
        session: 数据库会话 (用于持久化分析结果)

    Yields:
        SSEEvent: 流式事件 (进度/风险/总结/完成/错误)
    """
    logger.info(f"🚀 Agent 工作流启动 | 合同ID: {contract_id}")

    # 初始化状态
    state = AgentState(
        contract_id=contract_id,
        raw_text=raw_text,
    )

    # ── 定义节点管道 ──
    pipeline: list[tuple[str, str, Callable]] = [
        ("extractor", "📝 结构化抽取 — 正在整理合同条款…", extract_clauses),
        ("retriever", "⚖️ 法规检索 — 正在查询相关劳动法条文…", retrieve_legal_references),
        ("reviewer", "🔍 风险审查 — 正在逐项评估风险并生成话术…", review_risks),
    ]

    total_nodes = len(pipeline)

    try:
        for idx, (node_name, description, node_fn) in enumerate(pipeline):
            progress = idx / total_nodes

            # 通知: 节点开始
            yield SSEEvent(
                event=SSEEventType.NODE_START,
                data=AgentNodeProgress(
                    node_name=node_name,
                    description=description,
                    progress=progress,
                ).model_dump(),
            )

            # 执行节点
            state = await node_fn(state)

            # 检查错误
            if state.errors:
                latest_error = state.errors[-1]
                yield SSEEvent(
                    event=SSEEventType.THINKING,
                    data={"message": f"⚠️ {latest_error}，继续处理后续步骤…"},
                )

            # 通知: 节点完成
            yield SSEEvent(
                event=SSEEventType.NODE_COMPLETE,
                data=AgentNodeProgress(
                    node_name=node_name,
                    description=f"{description.split('—')[0]}✅ 完成",
                    progress=(idx + 1) / total_nodes,
                ).model_dump(),
            )

            # 如果风险审查完成，逐条推送风险
            if node_name == "reviewer":
                for assessment in state.risk_assessments:
                    yield SSEEvent(
                        event=SSEEventType.RISK_FOUND,
                        data=assessment.model_dump(),
                    )

        # ── 持久化分析结果 ──
        if session is not None:
            await _persist_results(state, session)

        # ── 推送最终总结 ──
        yield SSEEvent(
            event=SSEEventType.SUMMARY,
            data={
                "overall_score": state.overall_score,
                "overall_level": state.overall_level.value,
                "summary": state.summary,
                "total_clauses": len(state.extracted_clauses),
                "total_risks": len(state.risk_assessments),
                "legal_references_count": len(state.legal_references),
            },
        )

        # ── 完成 ──
        yield SSEEvent(
            event=SSEEventType.COMPLETE,
            data={"message": "✨ 合同风险排查完成！"},
        )

        logger.info(
            f"🏁 Agent 工作流完成 | 合同ID: {contract_id} | "
            f"评分: {state.overall_score}/100"
        )

    except Exception as e:
        logger.exception(f"💥 Agent 工作流异常 | 合同ID: {contract_id}")
        yield SSEEvent(
            event=SSEEventType.ERROR,
            data={"message": f"分析过程中发生错误: {e}"},
        )
