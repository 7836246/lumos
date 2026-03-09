"""
健康检查接口测试.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_root(client: AsyncClient) -> None:
    """根路径应返回服务信息."""
    response = await client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "service" in data
    assert "version" in data


@pytest.mark.asyncio
async def test_health(client: AsyncClient) -> None:
    """健康检查应返回 healthy."""
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


@pytest.mark.asyncio
async def test_readiness(client: AsyncClient) -> None:
    """就绪检查应返回检查结果."""
    response = await client.get("/api/v1/health/ready")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "checks" in data


@pytest.mark.asyncio
async def test_submit_contract(client: AsyncClient) -> None:
    """提交合同应返回 202 并包含 stream_url."""
    payload = {
        "text": "甲方：某某有限公司\n\n乙方同意在合同期内不得从事与甲方业务相关的工作。"
        * 3,
        "source": "text_paste",
    }
    response = await client.post("/api/v1/contracts", json=payload)
    assert response.status_code == 202
    data = response.json()
    assert "contract_id" in data
    assert "stream_url" in data
    assert data["status"] == "analyzing"


@pytest.mark.asyncio
async def test_submit_contract_too_short(client: AsyncClient) -> None:
    """过短的合同文本应被拒绝."""
    payload = {"text": "太短了"}
    response = await client.post("/api/v1/contracts", json=payload)
    assert response.status_code == 422  # Validation Error


@pytest.mark.asyncio
async def test_get_nonexistent_contract(client: AsyncClient) -> None:
    """查询不存在的合同应返回 404."""
    response = await client.get("/api/v1/contracts/nonexistent-id")
    assert response.status_code == 404
