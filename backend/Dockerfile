# ========================================
# Lumos Server — 多阶段构建 Dockerfile
# ========================================
# 使用 uv 加速 Python 依赖安装

# ---- 阶段 1: 构建 ----
FROM python:3.12-slim AS builder

# 安装 uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# 先复制依赖声明 (利用 Docker 层缓存)
COPY pyproject.toml ./

# 使用 uv 安装依赖
RUN uv pip install --system --no-cache -r pyproject.toml

# ---- 阶段 2: 运行 ----
FROM python:3.12-slim AS runtime

WORKDIR /app

# 从 builder 阶段复制已安装的包
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 复制应用代码
COPY . .

# 非 root 用户运行
RUN groupadd -r lumos && useradd -r -g lumos lumos
USER lumos

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8000/api/v1/health')" || exit 1

# 启动命令
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
