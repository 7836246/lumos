"""
LLM 客户端工厂.

统一管理大模型客户端的创建与配置，
支持 OpenAI 兼容接口 (DeepSeek / Claude / 通义千问 等)。
"""

from __future__ import annotations

from functools import lru_cache

from langchain_openai import ChatOpenAI

from app.core.config import get_settings


@lru_cache
def get_chat_llm() -> ChatOpenAI:
    """获取聊天大模型客户端 (单例缓存)."""
    settings = get_settings()

    return ChatOpenAI(
        api_key=settings.llm_api_key,
        base_url=settings.llm_base_url,
        model=settings.llm_model_name,
        temperature=0.1,  # 合同分析需要严谨，低温度
        max_tokens=4096,
        streaming=True,
    )
