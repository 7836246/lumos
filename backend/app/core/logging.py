"""
日志配置模块.

使用 loguru 替代标准 logging，提供更丰富的日志格式和输出。
"""

from __future__ import annotations

import sys

from loguru import logger

from app.core.config import get_settings


def setup_logging() -> None:
    """配置全局日志."""
    settings = get_settings()

    # 移除默认 handler
    logger.remove()

    # 控制台输出 (带颜色)
    log_format = (
        "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    )

    logger.add(
        sys.stderr,
        format=log_format,
        level=settings.log_level,
        colorize=True,
        backtrace=settings.is_development,
        diagnose=settings.is_development,
    )

    # 生产环境额外写入文件
    if settings.is_production:
        logger.add(
            "logs/lumos_{time:YYYY-MM-DD}.log",
            rotation="00:00",
            retention="30 days",
            compression="gz",
            level="INFO",
            format=log_format,
        )

    logger.info(f"📋 日志级别: {settings.log_level} | 环境: {settings.app_env.value}")
