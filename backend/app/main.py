"""
Lumos Server — FastAPI 应用入口.

🔍 契光鉴微 · AI 合同风险排查引擎
"""

from __future__ import annotations

from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from app.api.v1.router import v1_router
from app.core.config import get_settings
from app.core.database import init_db
from app.core.logging import setup_logging


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """应用生命周期管理."""
    # ── 启动 ──
    setup_logging()
    settings = get_settings()

    logger.info("=" * 60)
    logger.info(f"🔍 {settings.app_name} v{settings.app_version}")
    logger.info(f"📍 环境: {settings.app_env.value}")
    logger.info(f"🗄️ 数据库: {settings.database_url[:50]}...")
    logger.info(f"🤖 LLM: {settings.llm_model_name} @ {settings.llm_base_url[:40]}")
    logger.info(f"🔐 鉴权: {'已启用' if settings.auth_enabled else '未启用'}")
    logger.info("=" * 60)

    # 初始化数据库
    await init_db()
    logger.info("✅ 数据库初始化完成")

    logger.info(f"🚀 服务已启动: http://{settings.app_host}:{settings.app_port}")
    logger.info(f"📚 API 文档: http://{settings.app_host}:{settings.app_port}/docs")

    yield

    # ── 关闭 ──
    logger.info("👋 服务正在关闭…")


def create_app() -> FastAPI:
    """创建并配置 FastAPI 应用实例."""
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=(
            "🔍 **Lumos · 契光鉴微** — AI 合同风险排查引擎\n\n"
            "开源免费的劳动合同风险检测服务，站在劳动者视角，\n"
            "深度适配中国劳动法，一键排查合同中的十大坑点。\n\n"
            "---\n"
            "- 📸 拍照即查 (端侧 OCR)\n"
            "- 💬 \"说人话\"的条款解读\n"
            "- 🗣️ 一键生成谈判话术\n"
            "- ⚡ SSE 流式实时分析\n"
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # ── CORS 跨域 ──
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"] if settings.is_development else [],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── 注册路由 ──
    app.include_router(v1_router)

    # ── 根路径 ──
    @app.get("/", tags=["🏠 根"])
    async def root() -> dict:
        return {
            "service": settings.app_name,
            "version": settings.app_version,
            "docs": "/docs",
            "health": "/api/v1/health",
        }

    return app


# 应用实例 (供 uvicorn 直接引用: uvicorn app.main:app)
app = create_app()
