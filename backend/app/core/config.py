"""
应用全局配置.

使用 pydantic-settings 从环境变量/.env 文件自动加载配置，
支持 development / production 两种模式。
"""

from __future__ import annotations

from enum import Enum
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# 项目根目录 = backend/
BASE_DIR = Path(__file__).resolve().parent.parent.parent


class Environment(str, Enum):
    """运行环境枚举."""

    DEVELOPMENT = "development"
    PRODUCTION = "production"
    TESTING = "testing"


class Settings(BaseSettings):
    """应用核心配置, 一切可配项均在此定义."""

    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── 应用基础 ──────────────────────────────────────────────
    app_name: str = "Lumos Server"
    app_version: str = "0.1.0"
    app_env: Environment = Environment.DEVELOPMENT
    app_debug: bool = True
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    # ── 数据库 ────────────────────────────────────────────────
    database_url: str = f"sqlite+aiosqlite:///{BASE_DIR / 'lumos.db'}"

    # ── AI 模型 ───────────────────────────────────────────────
    llm_api_key: str = ""
    llm_base_url: str = "https://api.deepseek.com/v1"
    llm_model_name: str = "deepseek-chat"

    # 嵌入模型 (RAG)
    embedding_api_key: str = ""
    embedding_base_url: str = "https://api.deepseek.com/v1"
    embedding_model_name: str = "text-embedding-v3"

    # ── 安全 ──────────────────────────────────────────────────
    api_secret_key: str = ""

    # ── 日志 ──────────────────────────────────────────────────
    log_level: str = "DEBUG"

    # ── 衍生属性 ──────────────────────────────────────────────
    @property
    def is_development(self) -> bool:
        return self.app_env == Environment.DEVELOPMENT

    @property
    def is_production(self) -> bool:
        return self.app_env == Environment.PRODUCTION

    @property
    def is_testing(self) -> bool:
        return self.app_env == Environment.TESTING

    @property
    def auth_enabled(self) -> bool:
        """只在 api_secret_key 非空时启用鉴权."""
        return bool(self.api_secret_key)


@lru_cache
def get_settings() -> Settings:
    """获取全局配置单例 (缓存)."""
    return Settings()
