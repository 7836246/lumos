"""
API 公共依赖.

FastAPI 依赖注入: 数据库会话、鉴权等。
"""

from __future__ import annotations

from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.security import verify_api_key

# 类型别名, 在路由中直接使用
DBSession = Annotated[AsyncSession, Depends(get_session)]
AuthGuard = Annotated[str | None, Depends(verify_api_key)]
