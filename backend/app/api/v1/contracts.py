"""
合同分析路由.

核心业务接口:
- POST /contracts: 提交合同 → 启动 Agent 分析
- GET  /contracts/{id}/stream: SSE 流式接收分析过程
- GET  /contracts/{id}/report: 获取完整分析报告
"""

from __future__ import annotations

import asyncio
import json
from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import StreamingResponse
from loguru import logger
from sqlmodel import select

from app.agent.graph import run_contract_analysis
from app.api.deps import AuthGuard, DBSession
from app.models.analysis import AnalysisResult, RiskItem
from app.models.contract import Contract, ContractStatus
from app.schemas.analysis import AnalysisReportResponse, RiskItemResponse, SSEEventType
from app.schemas.contract import (
    ContractCreateRequest,
    ContractResponse,
    ContractSubmitResponse,
)

router = APIRouter(prefix="/contracts", tags=["📄 合同分析"])


# ─── POST /contracts ───────────────────────────────────────────


@router.post(
    "",
    response_model=ContractSubmitResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="提交合同进行风险排查",
    description="接收脱敏后的合同文本，创建合同记录并启动 AI Agent 分析。"
    "分析结果通过 SSE 流式推送。",
)
async def submit_contract(
    request: ContractCreateRequest,
    session: DBSession,
    _auth: AuthGuard,
) -> ContractSubmitResponse:
    """提交合同文本进行 AI 风险排查."""
    logger.info(
        f"📥 收到合同提交 | 来源: {request.source.value} | "
        f"字数: {len(request.text)}"
    )

    # 创建合同记录
    contract = Contract(
        raw_text=request.text,
        source=request.source,
        status=ContractStatus.ANALYZING,
        page_count=request.page_count,
        char_count=len(request.text),
        device_id=request.device_id,
    )

    session.add(contract)
    await session.flush()  # 获取 ID, 但不提交事务 (由 get_session 管理)

    logger.info(f"✅ 合同记录已创建 | ID: {contract.id}")

    return ContractSubmitResponse(
        contract_id=contract.id,
        status=ContractStatus.ANALYZING,
        message="合同已受理, 正在进行 AI 风险排查…",
        stream_url=f"/api/v1/contracts/{contract.id}/stream",
    )


# ─── GET /contracts/{id}/stream (SSE) ──────────────────────────


@router.get(
    "/{contract_id}/stream",
    summary="SSE 流式接收分析过程",
    description="通过 Server-Sent Events 实时接收 Agent 的思考进度和风险发现。",
)
async def stream_analysis(
    contract_id: str,
    session: DBSession,
) -> StreamingResponse:
    """SSE 流式推送合同分析进度."""
    # 查找合同
    contract = await session.get(Contract, contract_id)
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"合同 {contract_id} 不存在",
        )

    async def event_generator():
        """生成 SSE 事件流."""
        try:
            async for event in run_contract_analysis(
                contract_id=contract_id,
                raw_text=contract.raw_text,
                session=session,
            ):
                # 格式化为 SSE 协议
                data = json.dumps(event.data, ensure_ascii=False)
                yield f"event: {event.event.value}\ndata: {data}\n\n"

                # 给前端一点渲染时间
                await asyncio.sleep(0.1)

            # 更新合同状态为已完成
            contract.status = ContractStatus.COMPLETED
            contract.updated_at = datetime.now(UTC)
            session.add(contract)
            await session.commit()

        except Exception as e:
            logger.exception(f"SSE 流异常 | 合同ID: {contract_id}")
            error_data = json.dumps(
                {"message": f"分析失败: {e}"},
                ensure_ascii=False,
            )
            yield f"event: error\ndata: {error_data}\n\n"

            # 标记失败
            contract.status = ContractStatus.FAILED
            contract.updated_at = datetime.now(UTC)
            session.add(contract)
            await session.commit()

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",  # Nginx 禁用缓冲
        },
    )


# ─── GET /contracts/{id}/report ────────────────────────────────


@router.get(
    "/{contract_id}/report",
    response_model=AnalysisReportResponse,
    summary="获取完整分析报告",
    description="获取指定合同的完整风险分析报告 (需分析完成后调用)。",
)
async def get_report(
    contract_id: str,
    session: DBSession,
    _auth: AuthGuard,
) -> AnalysisReportResponse:
    """获取合同的完整风险分析报告."""
    # 查找合同
    contract = await session.get(Contract, contract_id)
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"合同 {contract_id} 不存在",
        )

    if contract.status != ContractStatus.COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"合同尚未分析完成, 当前状态: {contract.status.value}",
        )

    # 查找分析结果
    stmt = select(AnalysisResult).where(AnalysisResult.contract_id == contract_id)
    result = await session.execute(stmt)
    analysis = result.scalar_one_or_none()

    if not analysis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="分析结果不存在",
        )

    # 查找风险条目
    stmt = (
        select(RiskItem)
        .where(RiskItem.analysis_id == analysis.id)
        .order_by(RiskItem.order)
    )
    result = await session.execute(stmt)
    risk_items = result.scalars().all()

    return AnalysisReportResponse(
        contract_id=contract_id,
        overall_score=analysis.overall_score,
        overall_level=analysis.overall_level,
        summary=analysis.summary,
        risk_items=[RiskItemResponse.model_validate(item) for item in risk_items],
        analyzed_at=analysis.created_at,
    )


# ─── GET /contracts/{id} ──────────────────────────────────────


@router.get(
    "/{contract_id}",
    response_model=ContractResponse,
    summary="查询合同状态",
)
async def get_contract(
    contract_id: str,
    session: DBSession,
    _auth: AuthGuard,
) -> ContractResponse:
    """查询合同记录与当前处理状态."""
    contract = await session.get(Contract, contract_id)
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"合同 {contract_id} 不存在",
        )

    return ContractResponse.model_validate(contract)
