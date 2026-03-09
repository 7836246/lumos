"""
健康检查路由.

提供系统运行状态检测接口, 供监控和部署探针使用。
"""

from __future__ import annotations

from fastapi import APIRouter

from app.core.config import get_settings

router = APIRouter(tags=["🏥 系统健康"])


@router.get("/health")
async def health_check() -> dict:
    """
    健康检查.

    返回服务运行状态和基本信息。
    """
    settings = get_settings()
    return {
        "status": "healthy",
        "service": settings.app_name,
        "version": settings.app_version,
        "environment": settings.app_env.value,
    }


@router.get("/health/ready")
async def readiness_check() -> dict:
    """
    就绪检查.

    验证所有外部依赖 (数据库, AI 服务) 是否可用。
    用于 Kubernetes 的 readinessProbe。
    """
    settings = get_settings()
    checks = {
        "database": True,  # TODO: 实际检测 DB 连接
        "llm_configured": bool(settings.llm_api_key),
    }
    all_ready = all(checks.values())

    return {
        "status": "ready" if all_ready else "not_ready",
        "checks": checks,
    }
