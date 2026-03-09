"""
安全与鉴权模块.

提供可选的 API Key 鉴权，当 api_secret_key 为空时自动跳过。
"""

from __future__ import annotations

from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader

from app.core.config import get_settings

settings = get_settings()

_api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


async def verify_api_key(
    api_key: str | None = Security(_api_key_header),
) -> str | None:
    """
    验证 API Key.

    - 如果服务端未配置 api_secret_key，则跳过鉴权（开发友好）。
    - 如果配置了 api_secret_key，则必须在请求头中携带有效 Key。
    """
    if not settings.auth_enabled:
        return None

    if not api_key or api_key != settings.api_secret_key:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无效的 API Key",
        )
    return api_key
