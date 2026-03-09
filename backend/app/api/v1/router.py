"""
API v1 路由聚合.

将所有 v1 版本的子路由统一注册在此。
"""

from __future__ import annotations

from fastapi import APIRouter

from app.api.v1.contracts import router as contracts_router
from app.api.v1.health import router as health_router

v1_router = APIRouter(prefix="/api/v1")

v1_router.include_router(health_router)
v1_router.include_router(contracts_router)
