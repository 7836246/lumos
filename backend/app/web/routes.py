"""
Web 前端路由.

提供 Lumos Web 体验端和后台管理页面。
直接内嵌到 FastAPI，无需额外的前端服务器。
"""

from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

WEB_DIR = Path(__file__).parent
templates = Jinja2Templates(directory=str(WEB_DIR / "templates"))

web_router = APIRouter(tags=["🌐 Web 前端"])


@web_router.get("/", response_class=HTMLResponse, include_in_schema=False)
async def web_home(request: Request) -> HTMLResponse:
    """Web 首页."""
    return templates.TemplateResponse("index.html", {"request": request})
