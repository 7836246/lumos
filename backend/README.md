# 🧠 Lumos Server — AI 合同风险排查引擎

> Lumos · 契光鉴微 的 Python 后端服务

## 技术栈

| 层 | 技术 | 说明 |
|:---|:---|:---|
| **Web 框架** | FastAPI | 极速 + 自带 Swagger 文档 |
| **AI 编排** | LangGraph | 循环节点，模型"懂思考、会改错" |
| **模型对接** | LangChain / OpenAI SDK | DeepSeek、Claude、通义千问适配 |
| **文档进阶** | LlamaIndex | 复杂文档提取与知识图谱 |
| **数据库** | SQLModel (SQLite/PG) | FastAPI 原生作者开发的 ORM |

## 快速开始

### 1. 安装依赖

推荐使用 [uv](https://docs.astral.sh/uv/):

```bash
# 安装 uv (如果还没有)
pip install uv

# 创建虚拟环境并安装依赖
uv venv
uv pip install -e ".[dev]"
```

或使用传统方式:

```bash
python -m venv .venv
.venv\Scripts\activate    # Windows
pip install -e ".[dev]"
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env, 填入你的 AI 模型 API Key
```

### 3. 启动服务

```bash
uvicorn app.main:app --reload --port 8000
```

访问 API 文档: http://localhost:8000/docs

### 4. 运行测试

```bash
pytest
```

## 项目结构

```
backend/
├── app/
│   ├── main.py              # FastAPI 应用入口
│   ├── api/                  # API 路由层
│   │   ├── deps.py           # 公共依赖注入
│   │   └── v1/
│   │       ├── router.py     # v1 路由聚合
│   │       ├── health.py     # 健康检查
│   │       └── contracts.py  # 合同分析 (核心)
│   ├── agent/                # LangGraph AI 智能体
│   │   ├── graph.py          # 工作流编排
│   │   ├── state.py          # Agent 状态定义
│   │   ├── nodes/            # 处理节点
│   │   │   ├── extractor.py  # 结构化抽取
│   │   │   ├── retriever.py  # 法规检索 (RAG)
│   │   │   └── reviewer.py   # 风险审查
│   │   └── tools/
│   │       └── law_search.py # 法律检索工具
│   ├── core/                 # 基础设施层
│   │   ├── config.py         # 全局配置
│   │   ├── database.py       # 数据库引擎
│   │   ├── security.py       # API 鉴权
│   │   └── logging.py        # 日志配置
│   ├── models/               # 数据库模型
│   │   ├── contract.py       # 合同模型
│   │   └── analysis.py       # 分析结果模型
│   └── schemas/              # 请求/响应 DTO
│       ├── contract.py       # 合同 schemas
│       └── analysis.py       # 分析结果 schemas
├── tests/                    # 测试套件
├── pyproject.toml            # 项目配置
├── Dockerfile                # Docker 容器化
└── .env.example              # 环境变量模板
```

## Docker 部署

```bash
docker build -t lumos-server .
docker run -p 8000:8000 --env-file .env lumos-server
```

## API 概览

| 方法 | 端点 | 描述 |
|:---|:---|:---|
| `GET` | `/api/v1/health` | 健康检查 |
| `POST` | `/api/v1/contracts` | 提交合同进行分析 |
| `GET` | `/api/v1/contracts/{id}/stream` | SSE 流式接收分析过程 |
| `GET` | `/api/v1/contracts/{id}/report` | 获取完整分析报告 |
| `GET` | `/api/v1/contracts/{id}` | 查询合同状态 |
